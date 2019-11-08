#lang racket/base


(require web-server/web-server
         web-server/dispatchers/dispatch-files
         web-server/dispatchers/filesystem-map)


(serve
 #:dispatch (make #:url->path (make-url->path "."))
 #:port 8404)
(do-not-return)
