#lang racket/base


(provide (struct-out blog-post)
         post
         blog-post>?
         blog-post->atom-id)


(require "./pdate.rkt")


(struct blog-post
  (title
   date
   id
   tags
   series
   unlisted?
   generate?))


(define (post title
              #:date date
              #:id id
              #:tags [tags '()]
              #:series [series #f]
              #:unlisted? [unlisted? #f]
              #:generate? [generate? #t])
  (blog-post title
             date
             id
             tags
             series
             unlisted?
             generate?))


(define (blog-post>? p1 p2)
  (pdate>? (blog-post-date p1)
           (blog-post-date p2)))


(define (blog-post->atom-id p)
  (string-append
   "tag:"
   "sgt.hootr.club"
   ","
   (pdate->string (blog-post-date p) "-")
   ":"
   (blog-post-id p)))
