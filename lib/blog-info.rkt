#lang racket/base


(provide (struct-out blog))


(struct blog
  (title
   url
   rss-url
   atom-url
   author-name
   author-email
   language
   description)
  #:constructor-name blog-info)
