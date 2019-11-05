#lang racket/base


(require xml
         "./blog-post.rkt"
         "./blog-info.rkt")


(provide blog->rss-feed
         blog->atom-feed)


;; RSS
(define (blog-post->rss-item info post)
  `(item
    [title ,(blog-post-title post)]
    [link ,(string-append (blog-url info) (blog-post-id post))]
    [author ,(string-append (blog-author-name info)
                            " (" (blog-author-email info) ")")]
    [guid ([isPermaLink "false"]) ,(blog-post->atom-id post)]
    [pubDate ,(pdate->rfc822 (blog-post-date post))]))


(define (blog->rss-info info posts)
  `([title ,(blog-title info)]
    [link ,(blog-url info)]
    [language "en-us"]
    [generator "generator.rkt"]
    [description ,(blog-description info)]
    [atom:link ([href ,(blog-rss-url info)]
                [rel "self"]
                [type "application/rss+xml"])]
    ,@(for/list ([post (sort posts blog-post>?)]
                 #:unless (blog-post-unlisted? post))
        (blog-post->rss-item info post))))


(define (blog->rss-feed info posts)
  (make-document
   (make-prolog
    (list (make-p-i #f #f 'xml "version=\"1.0\" encoding=\"UTF-8\""))
    #f
    null)
   (xexpr->xml
    `(rss ([version "2.0"]
           [xmlns:atom "http://www.w3.org/2005/Atom"])
          (channel () ,@(blog->rss-info info posts))))))


;; Atom
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
  `([title ([type "text"]) ,(blog-title info)]
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
   (xexpr->xml
    `(feed ([xmlns "http://www.w3.org/2005/Atom"])
           ,@(blog->atom-info info posts)))))
