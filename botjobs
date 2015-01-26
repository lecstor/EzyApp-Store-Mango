
install:
	carton install

test:
	carton exec prove -lv t/*

testcover:
	HARNESS_PERL_SWITCHES=-MDevel::Cover=+ignore,^local,+ignore,^/home,+ignore,^t/,+ignore,^lib/EzyApp/Test carton exec prove -lv t/*

cover:
	carton exec cover

tc: testcover cover

.PHONY: test testcover cover tc
