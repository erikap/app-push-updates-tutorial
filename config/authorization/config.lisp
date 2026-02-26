;;;;;;;;;;;;;;;;;;;
;;; delta messenger
(in-package :delta-messenger)

;; (push (make-instance 'delta-logging-handler) *delta-handlers*) ;; enable if delta messages should be logged on terminal
(add-delta-messenger "http://delta-notifier/")
(setf *log-delta-messenger-message-bus-processing* nil) ;; set to t for extra messages for debugging delta messenger

;;;;;;;;;;;;;;;;;
;;; configuration
(in-package :client)
(setf *log-sparql-query-roundtrip* t) ; change nil to t for logging requests to virtuoso (and the response)
(setf *backend* "http://triplestore:8890/sparql")

(in-package :server)
(setf *log-incoming-requests-p* t) ; change nil to t for logging all incoming requests

;;;;;;;;;;;;;;;;
;;; prefix types
(in-package :type-cache)

(add-type-for-prefix "http://mu.semte.ch/sessions/" "http://mu.semte.ch/vocabularies/session/Session") ; each session URI will be handled for updates as if it had this mussession:Session type

;;;;;;;;;;;;;;;;;
;;; access rights

(in-package :acl)

;; these three reset the configuration, they are likely not necessary
(defparameter *access-specifications* nil)
(defparameter *graphs* nil)
(defparameter *rights* nil)

;; Prefixes used in the constraints below (not in the SPARQL queries)
(define-prefixes
  ;; Core
  :mu "http://mu.semte.ch/vocabularies/core/"
  :session "http://mu.semte.ch/vocabularies/session/"
  :ext "http://mu.semte.ch/vocabularies/ext/"
  :service "http://services.semantic.works/"
  ;; Custom prefix URIs here, prefix casing is ignored
  :rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  :dct "http://purl.org/dc/terms/"
  )


;;;;;;;;;
;; Graphs
;;
;; These are the graph specifications known in the system.  No
;; guarantees are given as to what content is readable from a graph.  If
;; two graphs are nearly identitacl and have the same name, perhaps the
;; specifications can be folded too.  This could help when building
;; indexes.

(define-graph public ("http://mu.semte.ch/graphs/public")
  (_ -> _)) ; public allows ANY TYPE -> ANY PREDICATE in the direction
            ; of the arrow

(define-graph messages ("http://mu.semte.ch/graphs/messages")
  ("ext:Message"
   -> "rdf:type"
   -> "mu:uuid"
   -> "ext:sender"
   -> "ext:content"
   -> "ext:sentAt"))

(define-graph tasks ("http://mu.semte.ch/graphs/tasks")
  ("ext:Task"
   -> "rdf:type"
   -> "mu:uuid"
   -> "dct:title"
   -> "ext:status"))

;;;;;;;;;;;;;
;; User roles

(supply-allowed-group "public")

(grant (read)
       :to-graph public
       :for-allowed-group "public")

(grant (read write)
       :to (messages tasks)
       :for "public")
