#lang racket

(require xml)


(define pages
  '(about
    blog
    legal))


(define (navbar page)
  (define pages
    '([blog "/molten-matter/" "Molten Matter"]
      [about "/" "About"]))
  `(nav
    (ul
     ,@(map (λ (p) `(li (a ([href ,(cadr p)]
                            ,@(if (eq? page (car p)) '([class "selected"]) '()))
                           ,(caddr p))))
            pages))))


(define (page curr-page title body)
  `(html
    (head
     (title ,title)
     (meta ([charset "UTF-8"]))
     (meta ([name "viewport"]
            [content "width=device-width, initial-scale=1, viewport-fit=cover"]))
     (link ([rel "stylesheet"]
            [href "/assets/style.css"]
            [type "text/css"])))
    (body
     (div
      ([class "body-container"]
       [id ,(string-append (symbol->string curr-page) "-page")])
      (header ,(navbar curr-page))
      (main ,@body)
      (footer
       "this web sight was made with " (a ([href "https://racket-lang.org/"]) "Racket") ".")))))


(define about-page
  (page 'about "steenuil's page"
        '((div ([class "text"])
               (p "I welcome you to my humble abode. "
                  "Make yourself comfortable. Have a link, if you'd like.")
               (div ([class "table"])
                    (div "github")   (div (a ([href "https://github.com/steinuil"]) "github.com/steinuil"))
                    (div "twitter")  (div (a ([href "https://twitter.com/steinuil"]) "@steinuil"))
                    (div "email")    (div (a ([href "mailto:steenuil.owl@gmail.com"]) "steenuil.owl@gmail.com")))
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


(struct blog-post
  (title
   date
   id
   tags
   [series #:auto])
  #:auto-value '())

(struct pdate
  (year month day))

(define (pdate->string d)
  (string-append (number->string (pdate-year d))
                 "-"
                 (number->string (pdate-month d))
                 "-"
                 (number->string (pdate-day d))))


(define blog-posts
  (list (blog-post "The TTY Protocol"
                   (pdate 2017 2 10)
                   "tty"
                   '(programming))))



(define blog-index
  (page 'blog "Molten Matter"
        `((div
           (ul
            ,@(map (λ (p)
                     `(li ([class "post"])
                          (span ([class "name"]) ,(blog-post-title p))
                          (span ([class "date"]) ,(pdate->string (blog-post-date p)))))
                   blog-posts))))))

(define legal-page
  (page 'legal "the legal stuffs page"
        `(div ([class "text"]
               [id "legal"])
              (header "Legal " (a ([href "#legal"]) "#"))
              (p "This is a static website. It doesn't store any of your data nor use tracking cookies, scripts or anything of the sort. "
                 "It doesn't load resources from other websites.")
              (p "All text and pictures on this website are licensed under "
                 (a ([href "https://creativecommons.org/licenses/by-sa/4.0/"]) "Creative Commons Attribution-ShareAlike 4.0 International")
                 " (CC BY-SA 4.0), unless otherwise noted. "
                 (br)
                 "The code snippets written by me are licensed under the "
                 (a ([href "https://unlicense.org/"]) "Unlicense")
                 ", unless otherwise noted.")
              (p "This website uses some fonts licensed under the "
                 (a ([href "http://scripts.sil.org/OFL"]) "SIL Open Font License, version 1.1")
                 ". These are their copyright notices.")
              (div ([class "table"])
                   (div (a ([href "https://www.huertatipografica.com/en/fonts/bitter-ht"]) "Bitter"))
                   (div "Copyright (c) 2013, Sol Matas (sol@huertatipografica.com.ar), with Reserved Font Names 'Bitter'")
                   (div (a ([href "http://www.omnibus-type.com/fonts/archivo-black/"]) "Archivo Black"))
                   (div "Copyright 2017 The Archivo Black Project Authors (https://github.com/Omnibus-Type/ArchivoBlack)")))))


(call-with-output-file "index.html" #:exists 'replace
  (λ (out)
    (write-xml/content
     (xexpr->xml about-page)
     out)))

#;(call-with-output-file "molten-matter/index.html" #:exists 'replace
  (λ (out)
    (write-xml/content
     (xexpr->xml blog-index)
     out)))
