#lang racket

(require xml
         markdown/parse
         racket/date)

;;;
;;; Blog stuffs

(struct pdate
  (year month day))

(struct blog-post
  (title
   date
   id
   tags
   series
   unlisted?
   generate?)
  #:constructor-name make-blog-post)

(define (post title
              #:date date
              #:id id
              #:tags [tags '()]
              #:series [series #f]
              #:unlisted? [unlisted? #f]
              #:generate? [generate? #t])
  (make-blog-post title
                  date
                  id
                  tags
                  series
                  unlisted?
                  generate?))

(define (string-pad-left str n x)
  (let ([pad (- n (string-length str))])
    (if (> pad 0)
        (string-append (make-string pad x) str)
        str)))

(define (pdate->string d [sep "-"])
  (string-append
   (number->string (pdate-year d))
   sep
   (string-pad-left (number->string (pdate-month d)) 2 #\0)
   sep
   (string-pad-left (number->string (pdate-day d)) 2 #\0)))

(define (pdate->rfc822 d)
  (define date (seconds->date
                (find-seconds
                 0 0 0
                 (pdate-day d)
                 (pdate-month d)
                 (pdate-year d))))
  (define days '("Sun" "Mon" "Tue" "Wed" "Thu" "Fri" "Sat"))
  (define months '("" "Jan" "Feb" "Mar" "Apr"
                      "May" "Jun" "Jul" "Aug"
                      "Sep" "Oct" "Nov" "Dec"))
  (string-append
   (list-ref days (date-week-day date))
   ", "
   (string-pad-left (number->string (pdate-day d)) 2 #\0)
   " "
   (list-ref months (pdate-month d))
   " "
   (number->string (pdate-year d))
   " 00:00:00 UT"))

(define (pdate->rfc3339 d)
  (string-append
   (pdate->string d "-")
   "T00:00:00Z"))

(define (now->rfc3339)
  (define d (seconds->date (current-seconds) #f))
  (string-append
   (number->string (date-year d))
   "-"
   (string-pad-left (number->string (date-month d)) 2 #\0)
   "-"
   (string-pad-left (number->string (date-day d)) 2 #\0)
   "T"
   (string-pad-left (number->string (date-hour d)) 2 #\0)
   ":"
   (string-pad-left (number->string (date-minute d)) 2 #\0)
   ":"
   (string-pad-left (number->string (date-second d)) 2 #\0)
   "Z"))

(define (post->atom-id p)
  (string-append
   "tag:sgt.hootr.club,"
   (pdate->string (blog-post-date p) "-")
   ":"
   (blog-post-id p)))

(define (pdate>? pd1 pd2)
  (let ([y1 (pdate-year pd1)]
        [y2 (pdate-year pd2)]
        [m1 (pdate-month pd1)]
        [m2 (pdate-month pd2)]
        [d1 (pdate-day pd1)]
        [d2 (pdate-day pd2)])
    (cond [(not (= y1 y2)) (> y1 y2)]
          [(not (= m1 m2)) (> m1 m2)]
          [(not (= d1 d2)) (> d1 d2)]
          [else #f])))

(define (blog-post>? p1 p2)
  (pdate>? (blog-post-date p1)
           (blog-post-date p2)))

;;;
;;; Page stuffs

(struct page-info (id url title))

(define (navbar page page-infos)
  (define items
    (for/list ([pinfo page-infos])
      `(li (a ([href ,(page-info-url pinfo)]
               ,@(if (eq? page (page-info-id pinfo)) '([class "selected"]) '()))
              ,(page-info-title pinfo)))))
  `(nav (ul ,@items)))

(define (page curr-page page-infos title body)
  `(html
    (head
     (title ,title)
     (meta ([charset "UTF-8"]))
     (meta ([name "viewport"]
            [content "width=device-width, initial-scale=1, viewport-fit=cover"]))
     (link ([rel "stylesheet"]
            [href "/assets/style.css"]
            [type "text/css"]))
     (link ([rel "alternate"]
            [href "/rss.xml"]
            [type "application/rss+xml"]
            [title "RSS feed"]))
     (link ([rel "alternate"]
            [href "/feed.xml"]
            [type "application/atom+xml"]
            [title "Atom feed"])))
    (body ([id ,(string-append (symbol->string curr-page) "-page")])
          (div
           ([class "body-container"])
           (header ,(navbar curr-page page-infos))
           (main ,@body)
           (footer
            "made with " (a ([href "https://racket-lang.org/"])"racket")
            " // " (a ([href "/rss.xml"]) "rss")
            " // " (a ([href "/feed.xml"]) "atom"))))))

(define (image width height src [src2x #f] #:description [description ""])
  `(figure
    (img ([width ,(number->string width)]
          [height ,(number->string height)]
          [src ,src]
          [alt ,description]
          ,@(if src2x `([srcset ,(string-append src2x " 2x")]) '())))
    (figcaption ,description)))

(define (rss-page items)
  (define rss-info
    `((title "Molten Matter")
      (link "https://sgt.hootr.club/molten-matter/")
      (language "en-us")
      (generator "generator.rkt")
      #;(copyright "Copyright")
      (description "steenuil's blog")
      (atom:link ([href"https://sgt.hootr.club/rss.xml"]
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
          (channel () ,@rss-info)))
   null))

(define (atom-page entries)
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

(define (post->rss-item post)
  `(item
    (title ,(blog-post-title post))
    (link  ,(string-append "https://sgt.hootr.club/molten-matter/" (blog-post-id post)))
    (author "steenuil.owl@gmail.com (steenuil)")
    (guid ([isPermaLink "false"]) ,(post->atom-id post))
    (pubDate ,(pdate->rfc822 (blog-post-date post)))))

(define (post->atom-entry post)
  `(entry
    (title ,(blog-post-title post))
    (id ,(post->atom-id post))
    (link ([href ,(string-append "https://sgt.hootr.club/molten-matter/"
                                 (blog-post-id post))]
           [rel "alternate"]
           [type "text/html"]))
    (updated ,(pdate->rfc3339 (blog-post-date post)))
    (author
     (name "steenuil")
     (email "steenuil.owl@gmail.com"))))

;;;
;;; Generation

(define (generate-page url page #:filename [filename "index.html"])
  (define dir-path (string-append "." url))
  (unless (directory-exists? dir-path)
    (make-directory dir-path))

  (call-with-output-file (string-append dir-path filename) #:exists 'replace
    (lambda (out)
      (write-xml/content
        (xexpr->xml page)
        out))))

(define (generate-rss posts)
  (define items
    (for/list ([post (sort posts blog-post>?)]
               #:unless (blog-post-unlisted? post))
      (post->rss-item post)))

  (call-with-output-file "rss.xml" #:exists 'replace
    (lambda (out)
      (write-xml (rss-page items) out))))

(define (generate-atom posts)
  (define entries
    (for/list ([post (sort posts blog-post>?)]
               #:unless (blog-post-unlisted? post))
      (post->atom-entry post)))
  
  (call-with-output-file "feed.xml" #:exists 'replace
    (lambda (out)
      (write-xml (atom-page entries) out))))

(define (transform-post-body post)
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

(define (post-page page-infos post)
  (define post-body
    (parse-markdown (file->string (string-append "posts/" (blog-post-id post) ".md"))))
  (define pdate (blog-post-date post))

  (define unlisted-notice
    '(div ([class "warning text"])
          (p "This post is unlisted. "
             "I keep it around to avoid breaking links, "
             "but I might have some good reasons to keep it hidden. "
             "Please don't repost it.")))

  (page 'blog-post page-infos (blog-post-title post)
        `((header (div ([class "post-title"]) ,(blog-post-title post))
                  " "
                  (time ([datetime ,(pdate->string pdate)]) ,(pdate->string pdate "/")))
          ,(if (blog-post-unlisted? post) unlisted-notice "")
          ,@(transform-post-body post-body))))

;;;
;;; Content

(define page-infos
  (list (page-info 'blog "/molten-matter/" "Molten Matter")
        (page-info 'about "/" "About")
        #;(page-info 'bookmarks "/bookmarks/" "Bookmarks")
        (page-info 'legal "/legal/" "Legal")))

(define about-page
  (page 'about page-infos "steenuil's page"
        '((div ([class "text"])
               (p "The steenuil (Athene noctua) is a bird that inhabits "
                  "a small town in " (strong "Italy") " not too far from the Alps. "
                  "This owl is a member of the typical or true owl family, "
                  (strong "programmers") ", which contains most species of owl."))
          (header ([class "heading"]) "External links")
          (div ([class "table"])
               (div "github")  (div (a ([href "https://github.com/steinuil"]) "github.com/steinuil"))
               (div "twitter") (div (a ([href "https://twitter.com/steinuil"]) "@steinuil"))
               (div "email")   (div (a ([href "mailto:steenuil.owl@gmail.com"]) "steenuil.owl@gmail.com"))))))


(define blog-posts
  (list
   (post "The TTY Protocol"
         #:date (pdate 2017 2 10)
         #:id "tty"
         #:tags '(programming))
   (post "Continuations, Promises, and call/cc"
         #:date (pdate 2017 10 27)
         #:id "call-cc"
         #:tags '(programming javascript))
   (post "The social issues of programming languages"
         #:date (pdate 2017 10 29)
         #:id "bikeshed"
         #:tags '(programming)
         #:unlisted? #t)
   (post "I survived Ur/Web"
         #:date (pdate 2018 1 22)
         #:id "urweb"
         #:tags '(programming urweb))
   (post "What the hell did I do this week, anyway?"
         #:date (pdate 2018 1 29)
         #:id "week-001"
         #:series "Weekly log"
         #:unlisted? #t)
   (post "An introduction to typeclasses"
         #:date (pdate 2018 02 14)
         #:id "typeclasses"
         #:tags '(programming urweb plt))
   (post "Overthinking cash in TypeScript"
         #:date (pdate 2018 11 11)
         #:id "overthinking-cash"
         #:tags '(programming typescript))
   (post "Reading Ur/Web signatures, part 1"
         #:date (pdate 2019 1 7)
         #:id "urweb-sig"
         #:tags '(programming urweb)
         #:series "Ur/Web")
   (post "A data-fetching component in React"
         #:date (pdate 2019 5 10)
         #:id "data-fetching-react"
         #:tags '(programming typescript react))))


(define blog-index
  (page 'blog page-infos "Molten Matter"
        `((div ([class "text"])
               (p "This is my blog. I called it "
                  (strong "Molten Matter")
                  " because I thought it sounded good. "
                  "I might dump my thoughts on here every now and then."))
          ,(image 700 394 "/assets/images/greenhouse.jpg" "/assets/images/greenhouse@2x.jpg"
                  #:description "the exterior of the greenhouse at the Royal Palace in Wien, Austria")
          (div ([class "post-list"])
               (ul
                ,@(for/list ([p (sort blog-posts blog-post>?)]
                             #:unless (blog-post-unlisted? p))
                    `(li ([class "post"])
                         (a ([class "name"]
                             [href ,(string-append "/molten-matter/" (blog-post-id p))])
                            ,(blog-post-title p))
                         (span ([class "date"]) ,(pdate->string (blog-post-date p) "/")))))))))


(define legal-page
  (page 'legal page-infos "Legal"
        `((div ([class "text"])
               (p "This is a static website. It doesn't store any of your data nor use tracking cookies, scripts or anything of the sort. "
                  "It doesn't load resources from other websites."))
          ,(image 394 700 "/assets/images/vlc.jpg" "/assets/images/vlc@2x.jpg"
                  #:description "an old traffic cone on a hill just behind Cuenca, Spain")
          (div ([class "text"])
               (p "All text and pictures on this website are licensed under "
                  (a ([href "https://creativecommons.org/licenses/by-sa/4.0/"]) "Creative Commons Attribution-ShareAlike 4.0 International")
                  " (CC BY-SA 4.0), unless otherwise noted. ")
               (p "The code snippets written by me are licensed under the "
                  (a ([href "https://unlicense.org/"]) "Unlicense")
                  ", unless otherwise noted.")
               (p "This website uses some fonts licensed under the "
                  (a ([href "http://scripts.sil.org/OFL"]) "SIL Open Font License, version 1.1")
                  ". These are their copyright notices."))
          (div ([class "table"])
               (div (a ([href "https://www.huertatipografica.com/en/fonts/bitter-ht"]) "Bitter"))
               (div "Copyright (c) 2013, Sol Matas (sol@huertatipografica.com.ar), with Reserved Font Names 'Bitter'")
               (div (a ([href "http://www.omnibus-type.com/fonts/archivo-black/"]) "Archivo Black"))
               (div "Copyright 2017 The Archivo Black Project Authors (https://github.com/Omnibus-Type/ArchivoBlack)")
               (div (a ([href "https://www.ibm.com/plex/"]) "IBM Plex Mono"))
               (div "Copyright © 2017 IBM Corp. with Reserved Font Name \"Plex\"")))))

(define 404-page
  (page 'notfound page-infos "404"
        `((header (div ([class "post-title"]) "Not found"))
          ,(image 700 394 "/assets/images/swap.jpg" "/assets/images/swap@2x.jpg"))))

(define bookmarks-page
  (page 'bookmarks page-infos "Bookmarks"
        `((div ([class "text"])
               (p "bookmarks")))))


;;;
;;; Generate the pages

(for ([page (list blog-index about-page #;bookmarks-page legal-page)]
      [pinfo page-infos])
  (generate-page (page-info-url pinfo) page))

(generate-page "/" #:filename "404.html" 404-page)

(generate-rss blog-posts)
(generate-atom blog-posts)

(for ([post blog-posts]
      #:when (blog-post-generate? post))
  (generate-page (string-append "/molten-matter/" (blog-post-id post) "/") (post-page page-infos post)))
