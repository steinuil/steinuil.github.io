#lang racket/base


(require xml
         "./blog-post.rkt")


(define (blog->rss-feed items)
  (define rss-info
    '((title "Molten Matter")
      (link "https://sgt.hootr.club/molten-matter/")
      (language "en-us")
      (generator "generator.rkt")
      ;(copyright "")
      (description "steenuil's blog")
      (atom:link ([href "https://sgt.hootr.club/rss.xml"]
                  [rel "self"]
                  [type "application/rss+xml"]))
      ,@items))

  (make-document
   (make-prolog
    (list (make-p-i #f #f 'xml "version=\"1.0\" encoding=\"UTF-8\""))
    #f
    null)
   (xexpr->xml
    `(rss ([version "2.0"]
           [xmlns:atom "http://www.w3.org/2005/Atom"])
          (channel () @,rss-info)))
   null))


(define (post->rss-item post)
  `(item
    (title ,(blog-post-title post))
    (link ,(string-append "https://sgt.hootr.club/molten-matter/"
                          (blog-post-id post)))
    (author "steenuil.owl@gmail.com (steenuil)")
    (guid ([isPermaLink "false"]) ,(blog-post->atom-id post))
    (pubDate ,(pdate->rfc822 (blog-post-date post)))))


(define (blog->atom-feed entries)
  (define atom-info
    `((title ([type "text"]) "Molten Matter")
      (id "https://sgt.hootr.club/molten-matter/")
      (link ([rel "alternate"]
             [type "text/html"]
             [href "https://sgt.hootr.club/molten-matter/"]))
      (link ([rel "self"]
             [type "application/atom+xml"]
             [href "https://sgt.hootr.club/feed.xml"]))
      (updated ,(now->rfc3339))
      (generator "generator.rkt")
      ,@entries))

  (make-document
   (make-prolog
    (list (make-p-i #f #f 'xml "version=\"1.0\" encoding=\"UTF-8\""))
    #f
    null)
   (xexpr->xml
    `(feed ([xmlns "http://www.w3.org/2005/Atom"])
           ,@atom-info))
   null))


(define (post->atom-entry post)
  `(entry
    (title ,(blog-post-title post))
    (id ,(blog-post->atom-id post))
    (link ([href ,(string-append "https://sgt.hootr.club/molten-matter/"
                                 (blog-post-id post))]
           [rel "alternate"]
           [type "text/html"]))
    (updated ,(pdate->rfc3339 (blog-post-date post)))
    (author
     (name "steenuil")
     (email "steenuil.owl@gmail.com"))))
