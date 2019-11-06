#lang racket/base


(require racket/list
         racket/match
         "./blog-info.rkt"
         "./page-info.rkt")


(define (take-paragraphs elts)
  (let loop ([elts elts]
             [out '()])
    (if (empty? elts)
        (values (reverse out) '())
        (match (car elts)
          [(cons 'p _)
           (loop (cdr elts)
                 (cons (car elts) out))]
          [_ (values (reverse out) elts)]))))


(define (transform-post-body post)
  (let loop ([elts post]
             [out '()])
    (if (empty? elts)
        (reverse out)
        (match (car elts)
          [(cons 'p rest)
           (let-values ([(text rest) (take-paragraphs elts)])
             (loop rest
                   (cons `(div ([class "text"])
                               ,@text)
                         out)))]
          [(list-rest 'blockquote attrs rest)
           (loop (cdr elts)
                 (cons `(blockquote ([class "text"] ,@attrs)
                                    ,@rest)
                       out))]
          [(list-rest 'h1 attrs rest)
           (loop (cdr elts)
                 (cons `(header ([class "heading"] ,@attrs) ,@rest)
                       out))]
          [(list 'div
                 '([class "figure"])
                 img
                 (list 'p '([class "caption"]) caption))
           (loop (cdr elts)
                 (cons `(figure ,img (figcaption ,caption))
                       out))]
          [_ (loop (cdr elts)
                   (cons (car elts) out))]))))


(define (nav-item page curr-id)
  `(li (a ([href ,(page-url page)]
           ,@(if (eq? curr-id (page-id page))
                 '([class "selected"]) '()))
          ,(page-title page))))


(define (html-container info pages curr-id body footer)
  `(html
    (head
     [title ,(blog-title info)]
     [meta ([charset "utf-8"])]
     [meta ([name "description"]
            [content ,(blog-description info)])]
     [meta ([name "generator"]
            [content "generator.rkt"])]
     [meta ([name "viewport"]
            [content "width=device-width, initial-scale=1, viewport-fit=cover"])]
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
               (footer ,footer)))))
