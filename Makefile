LDFLAGS=-lrtr #-L/home/fho/git/rtrlib
CFLAGS=-Wall #-I/home/fho/git/rtrlib

validator:
	cc $(CFLAGS) $(LDFLAGS) -o rtr-validator validator.c
