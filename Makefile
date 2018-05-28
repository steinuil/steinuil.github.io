RACKET = racket

index.html: generate.rkt
	racket $< > $@
