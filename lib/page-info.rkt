#lang racket/base


(provide (struct-out page))


(struct page (id url title)
  #:constructor-name page-info)
