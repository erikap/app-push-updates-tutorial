defmodule Dispatcher do
  use Matcher
  define_accept_types [
    html: [ "text/html", "application/xhtml+html" ],
    json: [ "application/json", "application/vnd.api+json" ]
  ]

  @any %{}
  @json %{ accept: %{ json: true } }
  @html %{ accept: %{ html: true } }

  define_layers [ :static, :services, :fall_back, :not_found ]

  get "/assets/*path", %{ layer: :static } do
    forward conn, path, "http://frontend/assets/"
  end

  match "/messages/*path", @json do
    forward conn, path, "http://cache/messages/"
  end

  match "/tasks/*path", @json do
    forward conn, path, "http://cache/tasks/"
  end

  match "/polling/*path", @json do
    forward conn, path, "http://polling-push-update/"
  end

  match "/*path", %{ accept: %{ html: true }, layer: :fallback } do
    forward conn, [], "http://frontend/index.html"
  end

  match "/*_", %{ layer: :not_found } do
    send_resp( conn, 404, "Route not found.  See config/dispatcher.ex" )
  end
end
