#lang racket/base


(provide transform-post)


(require racket/list
         racket/match)


(define (group-paragraphs elts)
  (define (is-paragraph e)
    (eq? (car e) 'p))
  (splitf-at elts is-paragraph))


(define (transform-post-items item rest)
  (match item
    [(cons 'p _)
     (define-values (paragraphs rest*) (group-paragraphs rest))
     (values `(div ([class "text"]) ,@(cons item paragraphs))
             rest*)]

    [(list-rest 'blockquote attrs quote)
     (values `(blockquote ([class "text"] ,@attrs) ,@quote)
             rest)]

    [(list-rest (or 'h1 'h2 'h3 'h4) attrs heading)
     (values `(header ([class "heading"] ,@attrs) ,@heading)
             rest)]

    [(list 'div '([class "figure"]) img
           (list 'p '([class "caption"]) caption))
     (values `(figure ,img (figcaption ,caption))
             rest)]

    [_ (values item rest)]))


(define (transform-post post)
  (let loop ([items post]
             [out '()])
    (if (null? items)
        (reverse out)
        (let-values ([(item rest) (transform-post-items (car items)
                                                        (cdr items))])
          (loop rest (cons item out))))))