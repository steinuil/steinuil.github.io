(import (scheme small)
        (chibi sxml))

(define links
  '(
    (github   . "https://github.com/steinuil")
    (twitter  . "https://twitter.com/steinuil")
    (email    . "mailto:steenuil.owl@gmail.com")
    (imgboard . "http://board.seize.ch")
    (medium   . "https://medium.com/@steinuil")
    (steam    . "http://steamcommunity.com/id/steinuil")
    (lastfm   . "https://last.fm/user/Cesko_m")
    ))

(define (linkify link)
  `(li (a (@ (id ,(car link))
             (href ,(cdr link)))
          ,(car link))))

(define index
  `(html
     (head
       (title "steenuil")
       (meta (@ (charset "UTF-8")))
       (link (@ (rel "stylesheet")
                (href "assets/style.css"))))
     (body
       (div (@ (id "card"))
            (div (@ (id "logo"))
                 (img (@ (src "assets/an.svg")))
                 (span (@ (id "name")) "steenuil."))

            (div (@ (id "description"))
                 "I'm no good at writing bios."
                 (br)
                 "Have some links instead.")

            (ul (@ (id "links")) ,(map linkify links))
            (div (@ (id "powered"))
                 "Powered by " (a (@ (href "index.scm")) "λ")))
       (div (@ (id ps)) "Protip: hold down a mouse button."))))

(with-output-to-file
  "index.html"
  (lambda () (display (sxml->xml index))))
