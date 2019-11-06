#lang racket/base


(provide (struct-out pdate)
         pdate->string
         pdate>?
         pdate->rfc822
         pdate->rfc3339
         now->rfc3339)


(require racket/date)


(struct pdate
  (year month day))


(define (string-pad-left str n char)
  (let ([pad (- n (string-length str))])
    (if (> pad 0)
        (string-append (make-string pad char) str)
        str)))


(define (pdate->string d [sep "-"])
  (string-append
   (number->string (pdate-year d))
   sep
   (string-pad-left (number->string (pdate-month d)) 2 #\0)
   sep
   (string-pad-left (number->string (pdate-day d)) 2 #\0)))


(define (pdate>? pd1 pd2)
  (let ([y1 (pdate-year pd1)] [m1 (pdate-month pd1)] [d1 (pdate-day pd1)]
        [y2 (pdate-year pd2)] [m2 (pdate-month pd2)] [d2 (pdate-day pd2)])
    (cond [(not (= y1 y2)) (> y1 y2)]
          [(not (= m1 m2)) (> m1 m2)]
          [(not (= d1 d2)) (> d1 d2)]
          [else #f])))


(define (pdate->rfc822 d)
  (define date (seconds->date
                (find-seconds
                 0 0 0
                 (pdate-day d)
                 (pdate-month d)
                 (pdate-year d))))
  (define days '("Sun" "Mon" "Tue" "Wed" "Thu" "Fri" "Sat"))
  (define months '(null "Jan" "Feb" "Mar" "Apr"
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


(define (date->rfc3339 d)
  (define (pad n)
    (string-pad-left (number->string n) 2 #\0))
  (string-append
   (number->string (date-year d))
   "-"
   (pad (date-month d))
   "-"
   (pad (date-day d))
   "T"
   (pad (date-hour d))
   ":"
   (pad (date-minute d))
   ":"
   (pad (date-second d))
   "Z"))


(define (now->rfc3339)
  (date->rfc3339 (seconds->date (current-seconds) #f)))