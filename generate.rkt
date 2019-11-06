#lang racket/base


;; TODO
;; - tag pages
;; - series pages
;; - custom markup


(require racket/file
         xml
         markdown/parse
         "./lib/pdate.rkt"
         "./lib/blog-post.rkt"
         "./lib/blog-info.rkt"
         "./lib/page-info.rkt"
         "./lib/rss-feed.rkt"
         "./lib/atom-feed.rkt"
         "./lib/transform-post.rkt"
         "./lib/html.rkt")


(define blog
  (blog-info "Molten Matter"
             #:url "https://sgt.hootr.club/molten-matter/"
             #:rss-url "https://sgt.hootr.club/rss.xml"
             #:atom-url "https://sgt.hootr.club/feed.xml"
             #:author-name "steenuil"
             #:author-email "steenuil.owl@gmail.com"
             #:language "en-us"
             #:description "steenuil's blog"))

;;;
;;; Generation

(define (generate-page url page #:filename [filename "index.html"])
  (define dir-path (string-append "." url))
  (unless (directory-exists? dir-path)
    (make-directory dir-path))

  (call-with-output-file (string-append dir-path filename) #:exists 'replace
    (lambda (out)
      (write-xml/content page out))))


(define (generate-rss info posts)
  (call-with-output-file "rss.xml" #:exists 'replace
    (lambda (out)
      (write-xml (blog->rss-feed info posts) out))))


(define (generate-atom info posts)
  (call-with-output-file "feed.xml" #:exists 'replace
    (lambda (out)
      (write-xml (blog->atom-feed info posts) out))))



(define (page id page-infos title body)
  (page->html (page-info id "" title)
              #:title title
              #:info blog
              #:all-pages page-infos
              #:body body
              #:footer '("made with "
                         (a ([href "https://racket-lang.org/"])"racket")
                         " :: " (a ([href "/rss.xml"]) "rss")
                         " :: " (a ([href "/feed.xml"]) "atom"))))





(define (image width height src [src2x #f] #:description [description ""])
  `(figure
    (img ([width ,(number->string width)]
          [height ,(number->string height)]
          [src ,src]
          [alt ,description]
          ,@(if src2x `([srcset ,(string-append src2x " 2x")]) '())))
    (figcaption ,description)))



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
        `((header (h1 ([class "post-title"]) ,(blog-post-title post))
                  " "
                  (time ([datetime ,(pdate->string pdate)]) ,(pdate->string pdate "/")))
          ,(if (blog-post-unlisted? post) unlisted-notice "")
          ,@(transform-post post-body))))

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
         #:tags '(programming typescript react))
   (post "A brief history of JAVAScript"
          #:date (pdate 2019 8 30)
          #:id "history-of-javas"
          #:tags '(programming shitposting))
   (post "Config constraints in the type system where they belong"
         #:date (pdate 2019 9 17)
         #:id "type-level-conf"
         #:tags '(programming typescript))
   (post "Thoughts on Suspense for data fetching"
         #:date (pdate 2019 10 30)
         #:id "thoughts-on-suspense"
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

(define bookmarks-list
  '(("bugs" .
     ("https://nedbatchelder.com/blog/200811/print_this_file_your_printer_will_jam.html"
      "http://www.dkriesel.com/en/blog/2013/0802_xerox-workcentres_are_switching_written_numbers_when_scanning"
      "https://bugs.launchpad.net/ubuntu/+source/cupsys/+bug/255161/comments/28"
      "http://web.mit.edu/jemorris/humor/500-miles"))))

(define bookmarks-page
  (page 'bookmarks page-infos "Bookmarks"
        `((div ([class "text"])
               (p "bookmarks")))))


;;;
;;; Generate the pages


(unless (directory-exists? "docs")
  (make-directory "docs"))

(for ([page (list blog-index about-page #;bookmarks-page legal-page)]
      [pinfo page-infos])
  (generate-page (page-url pinfo) page))

(generate-page "/" #:filename "404.html" 404-page)

(generate-rss blog blog-posts)
(generate-atom blog blog-posts)

(for ([post blog-posts]
      #:when (blog-post-generate? post))
  (generate-page (string-append "/molten-matter/" (blog-post-id post) "/") (post-page page-infos post)))
