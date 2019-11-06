#lang racket/base


(provide blog->atom-feed)


(require xml
         "./blog-post.rkt"
         "./blog-info.rkt")


(define (blog-post->atom-entry info post)
  `(entry
    [title ,(blog-post-title post)]
    [id ,(blog-post->atom-id post)]
    [link ([href ,(string-append (blog-url info) (blog-post-id post))]
           [rel "alternate"]
           [type "text/html"])]
    [updated ,(pdate->rfc3339 (blog-post-date post))]
    [author
     [name ,(blog-author-name info)]
     [email ,(blog-author-email info)]]))


(define (blog->atom-info info posts)
  `(feed ([xmlns "http://www.w3.org/2005/Atom"])
         [title ([type "text"]) ,(blog-title info)]
         [id ,(blog-url info)]
         [link ([rel "alternate"]
                [type "text/html"]
                [href ,(blog-url info)])]
         [link ([rel "self"]
                [type "application/atom+xml"]
                [href ,(blog-atom-url info)])]
         [updated ,(now->rfc3339)]
         [generator "generator.rkt"]
         ,@(for/list ([post (sort posts blog-post>?)]
                      #:unless (blog-post-unlisted? post))
             (blog-post->atom-entry info post))))


(define (blog->atom-feed info posts)
  (make-document
   (make-prolog
    (list (make-p-i #f #f 'xml "version=\"1.0\" encoding=\"UTF-8\""))
    #f
    null)
   (xexpr->xml (blog->atom-info info posts))
   null))
