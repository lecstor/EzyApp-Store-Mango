
all: testcover cover

testcover:
	HARNESS_PERL_SWITCHES=-MDevel::Cover=+ignore,local,+ignore,home,+ignore,t/.*\.t carton exec prove -lv t/*

cover:
	carton exec cover

test:
	carton exec prove -lv t/*

.PHONY: all testcover cover test
