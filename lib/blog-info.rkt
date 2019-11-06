#lang racket/base


(provide (struct-out blog)
         blog-info)


(struct blog
  (title
   url
   rss-url
   atom-url
   author-name
   author-email
   language
   description))


(define (blog-info title
                   #:url url
                   #:rss-url rss-url
                   #:atom-url atom-url
                   #:author-name author-name
                   #:author-email author-email
                   #:language language
                   #:description description)
  (blog title
        url
        rss-url
        atom-url
        author-name
        author-email
        language
        description))
