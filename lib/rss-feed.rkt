#lang racket/base


(provide blog->rss-feed)


(require xml
         "./blog-post.rkt"
         "./blog-info.rkt")


(define (blog-post->rss-item info post)
  `(item
    [title ,(blog-post-title post)]
    [link ,(string-append (blog-url info) (blog-post-id post))]
    [author ,(string-append (blog-author-name info)
                            " (" (blog-author-email info) ")")]
    [guid ([isPermaLink "false"]) ,(blog-post->atom-id post)]
    [pubDate ,(pdate->rfc822 (blog-post-date post))]))


(define (blog->rss-info info posts)
  `(rss ([version "2.0"]
         [xmlns:atom "http://www.w3.org/2005/Atom"])
        (channel ()
                 [title ,(blog-title info)]
                 [link ,(blog-url info)]
                 [language ,(blog-language info)]
                 [generator "generator.rkt"]
                 [description ,(blog-description info)]
                 [atom:link ([href ,(blog-rss-url info)]
                             [rel "self"]
                             [type "application/rss+xml"])]
                 ,@(for/list ([post (sort posts blog-post>?)]
                              #:unless (blog-post-unlisted? post))
                     (blog-post->rss-item info post)))))


(define (blog->rss-feed info posts)
  (make-document
   (make-prolog
    (list (make-p-i #f #f 'xml "version=\"1.0\" encoding=\"UTF-8\""))
    #f
    null)
   (xexpr->xml (blog->rss-info info posts))
   null))
