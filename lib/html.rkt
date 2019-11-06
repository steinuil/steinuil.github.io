#lang racket/base


(provide page->html)


(require xml
         "./blog-info.rkt"
         "./page-info.rkt")


(define (nav-item page curr-id)
  `(li (a ([href ,(page-url page)]
           ,@(if (eq? curr-id (page-id page))
                 '([class "selected"]) '()))
          ,(page-title page))))


(define (page->html page
                    #:title [title #f]
                    #:info info
                    #:all-pages all-pages
                    #:body body
                    #:footer footer)
  (xexpr->xml
   `(html
     (head [meta ([charset "utf-8"])]
           [meta ([name "viewport"]
                  [content "width=device-width, initial-scale=1, viewport-fit=cover"])]
           [title ,(page-title page)]
           [meta ([name "description"]
                  [content ,(blog-description info)])]
           [meta ([name "generator"]
                  [content "generator.rkt"])]
           [meta ([name "referrer"]
                  [content "strict-origin"])]
           [link ([rel "stylesheet"]
                  [href "/assets/style.css"]
                  [type "text/css"])]
           [link ([rel "alternate"]
                  [href "/rss.xml"]
                  [type "application/rss+xml"]
                  [title "RSS feed"])]
           [link ([rel "alternate"]
                  [href "/feed.xml"]
                  [type "application/atom+xml"]
                  [title "Atom feed"])])
     (body ([id ,(string-append (symbol->string (page-id page)) "-page")])
           (div ([class "body-container"])
                (header (nav (ul ,@(for/list ([p all-pages])
                                     (nav-item p (page-id page))))))
                (main ,@body)
                (footer ,@footer))))))


(define (html-container info pages curr-id body footer)
  `(html
    (head
     [title ,(blog-title info)]
     [meta ([charset "utf-8"])]
     [meta ([name "viewport"]
            [content "width=device-width, initial-scale=1, viewport-fit=cover"])]
     [meta ([name "description"]
            [content ,(blog-description info)])]
     [meta ([name "generator"]
            [content "generator.rkt"])]
     [meta ([name "referrer"]
            [content "strict-origin"])]
     [link ([rel "stylesheet"]
            [href "/assets/style.css"]
            [type "text/css"])]
     [link ([rel "alternate"]
            [href "/rss.xml"]
            [type "application/rss+xml"]
            [title "RSS feed"])]
     [link ([rel "alternate"]
            [href "/feed.xml"]
            [type "application/atom+xml"]
            [title "Atom feed"])])
    (body ([id ,(string-append (symbol->string curr-id) "-page")])
          (div ([class "body-container"])
               (header (nav (ul ,@(for/list ([page pages])
                                    (nav-item page curr-id)))))
               (main ,@body)
               (footer ,@footer)))))
