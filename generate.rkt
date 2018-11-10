#lang racket

(require xml
         markdown/parse)

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
            [type "text/css"])))
    (body ([id ,(string-append (symbol->string curr-page) "-page")])
          (div
           ([class "body-container"])
           (header ,(navbar curr-page page-infos))
           (main ,@body)
           (footer
            "this web sight made with " (a ([href "https://racket-lang.org/"])"Racket")".")))))

(define (image width height src [src2x #f] #:description [description ""])
  `(figure
    (img ([width ,(number->string width)]
          [height ,(number->string height)]
          [src ,src]
          [alt ,description]
          ,@(if src2x `([srcset ,(string-append src2x " 2x")]) '())))
    (figcaption ,description)))

;;;
;;; Generation

(define (generate-page url page)
  (define dir-path (string-append "." url))
  (unless (directory-exists? dir-path)
    (make-directory dir-path))

  (call-with-output-file (string-append dir-path "index.html") #:exists 'replace
    (lambda (out)
      (write-xml/content
        (xexpr->xml page)
        out))))

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
          [(cons 'h1 rest)
           (loop (cdr elts)
                 (cons (cons 'header rest)
                       out))]
          [_ (loop (cdr elts)
                   (cons (car elts) out))]))))

(define (post-page page-infos post)
  (define post-body
    (parse-markdown (file->string (string-append "posts/" (blog-post-id post) ".md"))))

  (page 'blog-post page-infos (blog-post-title post)
        `((header ,(blog-post-title post))
          ,(image 700 523 "/assets/images/shells.jpg" "/assets/images/shells@2x.jpg"
                  #:description "cicada shells on a tree near a beach in Marina di Cecina, Italy")
          ,@(transform-post-body post-body))))

;;;
;;; Content

(define page-infos
  (list (page-info 'blog "/molten-matter/" "Molten Matter")
        (page-info 'about "/" "About")
        (page-info 'legal "/legal/" "Legal")))

(define about-page
  (page 'about page-infos "steenuil's page"
        '((div ([class "text"])
               (p "I welcome you to my humble abode. "
                  "Make yourself comfortable. Have a link, if you'd like."))
          (div ([class "table"])
               (div "github")  (div (a ([href "https://github.com/steinuil"]) "github.com/steinuil"))
               (div "twitter") (div (a ([href "https://twitter.com/steinuil"]) "@steinuil"))
               (div "email")   (div (a ([href "mailto:steenuil.owl@gmail.com"]) "steenuil.owl@gmail.com")))
          (div ([class "text"])
               (p "I go by the name of " (strong "steenuil") ". "
                  "You might recognize it as the dutch name of the "
                  (a ([href "https://en.wikipedia.org/wiki/Athene_noctua"]) "Athene Noctua")
                  ", also known as the " (em "little owl") " in english.")
               (p "I write software every now and then, "
                  "most of which could be classified as "
                  (a ([href "http://catb.org/jargon/html/Y/yak-shaving.html"]) "yak shaving")
                  " around small issues I have with the programs I use every day.")
               (p "I like revisiting old things using new tools, "
                  "so I often end up spelunking through old, semi-abandoned codebases as research. "
                  "Sometimes I even try to get them working again.")
               (p "I currently dwell in " (strong "Italy") ", not too far from the Alps. "
                  "I speak English and Italian, and I know enough French to get by.")))))


(define blog-posts
  (list
   (post "The TTY Protocol"
         #:date (pdate 2017 2 10)
         #:id "tty"
         #:tags '(programming)
         #:generate? #f)
   (post "Continuations, Promises, and call/cc"
         #:date (pdate 2017 10 27)
         #:id "call-cc"
         #:tags '(programming javascript)
         #:generate? #f)
   (post "The social issues of programming languages"
         #:date (pdate 2017 10 29)
         #:id "bikeshed"
         #:tags '(programming)
         #:generate? #f
         #:unlisted? #t)
   (post "I survived Ur/Web"
         #:date (pdate 2018 1 22)
         #:id "urweb"
         #:tags '(programming urweb)
         #:generate? #f)
   (post "What the hell did I do this week, anyway?"
         #:date (pdate 2018 1 29)
         #:id "week-001"
         #:series "Weekly log"
         #:generate? #f
         #:unlisted? #t)
   (post "An introduction to typeclasses"
         #:date (pdate 2018 02 14)
         #:id "typeclasses"
         #:tags '(programming urweb plt)
         #:generate? #f)
   (post "Overthinking cash in TypeScript"
         #:date (pdate 2018 11 09)
         #:id "overthinking-cash"
         #:tags '(programming typescript)
         #:unlisted? #t)))


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


;;;
;;; Generate the pages

(for ([page (list blog-index about-page legal-page)]
      [pinfo page-infos])
  (generate-page (page-info-url pinfo) page))

(for ([post blog-posts]
      #:when (blog-post-generate? post))
  (generate-page (string-append "/molten-matter/" (blog-post-id post) "/") (post-page page-infos post)))