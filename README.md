# Push updates tutorial

This tutorial guides you through adding push updates to a semantic.works application. Push updates allow browser tabs to receive real-time notifications when data changes in the backend.

We will start from the demo application in this repository containing a 1999's real-time chat and a lightweight task management tool.

## Setup
Clone the backend and frontend repositories and launch the app

``` shell
git clone https://github.com/erikap/app-push-updates-tutorial.git
cd app-push-updates-tutorial
docker compose up -d
cd ..
git clone https://github.com/erikap/frontend-push-updates-tutorial.git
cd frontend-push-updates-tutorial
edi npm ci
eds --proxy=http://localhost:4200
```

When you first open the application, you can send chat messages and create new tasks. Nice! But try opening the app in two tabs side by side. You'll quickly spot the catch: nothing updates in real time. New chat messages? Task changes? They just sit there... invisible until you hit refresh. That's not very exciting. Let's fix that by wiring in push updates and make the app feel alive.

## Adding push updates to the backend

To enable push updates we will add three new services in the backend:
1. **[polling-push-updates-service](https://github.com/mu-semtech/polling-push-updates-service)**: Core service that manages browser tab connections and delivers push messages via long-polling
2. **[push-update-resource-monitor-service](https://github.com/redpencilio/push-update-resource-monitor-service)**: Monitors RDF triple patters clients have subscribed to and generates push updates for them
3. **[push-update-cache-monitor-service](https://github.com/redpencilio/push-update-cache-monitor-service)**: Monitors cache clear events and generates push updates for them

### polling-push-updates-service
Follow the steps of the Getting Started guide of https://github.com/mu-semtech/polling-push-updates-service

### push-update-resource-monitor-service
Follow the steps of the Getting Started guide of https://github.com/redpencilio/push-update-resource-monitor-service

### push-update-cache-monitor-service
Follow the steps of the Getting Started guide of https://github.com/redpencilio/push-update-cache-monitor-service

Note that both monitor services have overlapping parts in the `./config/authorization/config.lisp`. You have to add this only once of course.

### Enable cache clear notifications on mu-cache
Since v1.2.0 mu-cache can generate cache clear events to notify others about cache invalidations.

Update the config in `./config/authorization/config.lisp` such that mu-cache is allowed to write `cache:Clear` to the database.

``` common-lisp
(define-prefixes
  :mu "http://mu.semte.ch/vocabularies/core/"
  :service "http://services.semantic.works/"
  :cache "http://mu.semte.ch/vocabularies/cache/"
  :rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#")

(define-graph cache-clears ("http://mu.semte.ch/graphs/cache-clears")
  ("cache:Clear"
   -> "mu:uuid"
   -> "rdf:type"
   -> "cache:path"
   -> "cache:allowedGroups"))

(supply-allowed-group "public")

(with-scope "service:cache"
  (grant (write)
         :to cache-clears
         :for "public"))
```

``` shell
cd app-push-updates-tutorial
docker compose restart database
```

That's it for the backend part. Let's move on to the frontend.

## Adding push updates to the frontend
### Real-time chat messages
Let's start with the chat first and make new message appear automatically as soon as they're sent.

First, install the `ember-polling-push-updates` addon that will provide use with some useful services and decorators.

``` shell
cd frontend-push-updates-tutorial
edi ember install ember-polling-push-updates
eds --proxy=http://localhost:4200
```

Next, open the `chat` route and decorate the class with `@monitorCache`. Pass the path we query the message from in the backend as argument. The decorator subscribes the route to push updates for the given path.

``` diff
import Route from '@ember/routing/route';
import { service } from '@ember/service';
+ import monitorCache from 'ember-polling-push-updates/decorators/monitor-cache'

+ @monitorCache('/messages?sort=-sent-at')
export default class ChatRoute extends Route {
  @service store;

  async model() {
    return await this.store.query('message', { sort: "-sent-at" })
  }

  setupController(controller) {
    super.setupController(...arguments);
    controller.resetMessage();
  }
}
```

In the backend, we will need to inform mu-cache we're interested in cache invalidations for the `/messages` path. Do so by setting the `CACHE_CLEAR_NOTIFY_PATH_REGEX` environment variable to the `cache` service in `docker-compose.yml`

``` diff
  cache:
    image: semtech/mu-cache:2.1.0
    links:
      - resource:backend
+   environment:
+     CACHE_CLEAR_NOTIFY_PATH_REGEX: "^/messages\\?sort="
```

```shell
cd app-push-updates-tutorial
docker compose up -d
```

That's it. You have a real-time chat now.
