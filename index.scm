(import (scheme small)
        (chibi sxml))

(define links
  '((twitter "https://twitter.com/steinuil")
    (github "https://github.com/steinuil")
    (email "mailto:steenuil.owl@gmail.com")
    (imgboard "http://board.seize.ch")
    (medium "https://medium.com/@steinuil")
    (steam "http://steamcommunity.com/id/steinuil")
    (lastfm "https://last.fm/user/Cesko_m")))

(define (linkify links)
  (if (eq? links '()) '()
    (cons `(li (a (@ (id ,(caar links))
                     (href ,(cadar links)))
                  ,(caar links)))
          (linkify (cdr links)))))

(define index
  `(html
     (head
       (title "steenuil")
       (meta (@ (charset "UTF-8")))
       (link (@ (rel "stylesheet")
                (href "style.css"))))
     (body
       (div (@ (id "card"))
            (div (@ (id "logo"))
                 (img (@ (src "an.svg")))
                 (span (@ (id "name")) "steenuil."))

            (div (@ (id "description"))
                 "I'm no good at writing bios."
                 (br)
                 "Have some links instead.")

            (ul (@ (id "links")) ,(linkify links))
            (div (@ (id "powered"))
                 "Powered by " (a (@ (href "index.scm")) "λ")))
       (div (@ (id ps)) "Protip: hold down a mouse button."))))

(with-output-to-file
  "index.html"
  (lambda () (display (sxml->xml index))))
