(import (scheme small)
        (scheme process-context)
        (chibi sxml))

(define script-name (car (command-line)))

(define links
  '((github   . "https://github.com/steinuil")
    (blog     . "/molten-matter/")
    (email    . "mailto:steenuil.owl@gmail.com")
    (imgboard . "http://board.seize.ch")
    (steam    . "http://steamcommunity.com/id/steinuil")))


(define (linkify links)
  (let ((pad (apply max (map (lambda (x) (string-length (symbol->string (car x)))) links))))
    (let loop ((first-char "[")
               (ls links))
      (if (null? ls) '()
        (let* ((name (symbol->string (caar ls)))
               (padded-name (string-append name (make-string (- pad (string-length name)) #\space)))
               (term (if (null? (cdr ls)) " ]" #\newline))
               (line `(,first-char " " ,padded-name " => " (a (@ (href ,(cdar ls))) ,(cdar ls)) ,term)))
          (cons line (loop ";" (cdr ls))))))))


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
                        "(* Powered by " (a (@ (href ,script-path)) "Scheme") " *)")))))))

(guard (err
         (else (display "Usage: ")
               (display script-name)
               (display " <output-file>")
               (newline)))
       (let ((file (cadr (command-line))))
         (with-output-to-file file
                              (lambda () (display (sxml->xml index))))))
