(import (scheme small)
        (scheme process-context)
        (chibi sxml))


(define script-name
  (car (command-line)))


(define links
  '((github   . "https://github.com/steinuil")
    (blog     . "/molten-matter/")
    (email    . "mailto:steenuil.owl@gmail.com")
    (imgboard . "http://board.seize.ch")
    (steam    . "http://steamcommunity.com/id/steinuil")))


(define (linkify links)
  (define (name-length tup)
    (let ((name (symbol->string (car tup))))
      (cons (string-length name)
            (cons name (cdr tup)))))
  (let* ((links+length (map name-length links))
         (pad (apply max (map car links+length))))
    (let loop ((first-char "[")
               (ls links+length)
               (acc '()))
      (if (null? ls) (reverse acc)
        (let* ((name (cadar ls))
               (name-pad (make-string (- pad (caar ls)) #\space))
               (link (cddar ls))
               (padded-name (string-append name name-pad))
               (term (if (null? (cdr ls)) " ]" #\newline))
               (line `(,first-char " " ,padded-name " => "
                       (a (@ (href ,link)) ,link) ,term)))
          (loop ";" (cdr ls) (cons line acc)))))))


(define index
  (let ((script-path (string-append "/" script-name)))
    `(html
       (head
         (title steenuil)
         (meta (@ (charset "UTF-8")))
         (link (@ (rel "stylesheet")
                  (href "assets/style.css"))))
       (body
         (div (@ (id "name")) "steenuil.")
         (div (@ (id "cont"))
              (div (@ (id "logo"))
                   (img (@ (src "assets/an.svg"))))
              (div (@ (id "text"))
                   (div (@ (id "description") (class comment))
                        "(* I'm no good at writing bios." " Have some links instead. *)")
                   (div (@ (id "links")) (pre ,@(linkify links)))
                   (div (@ (id "powered") (class comment))
                        "(* Powered by " (a (@ (href ,script-name))
                                            "Scheme") " and make(1) *)")))))))

(guard (error-condition
         (else (display "Usage: ")
               (display script-name)
               (display " <output-file>")
               (newline)))
       (let ((file (cadr (command-line))))
         (with-output-to-file file
            (lambda () (display (sxml->xml index))))))
