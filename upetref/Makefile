
all: upetinit tests

tests:
	(rm ../build/0*)
	IOBASE=0x9900 make -C .. all
	for i in ../build/*; do ln -sf $$i; done
	rm -f 05*gen 08*gen *.d64


upetinit: upetinit.a65
	xa -XMASM -XC -o $@ $<

clean:
	rm -f upetinit
	rm -f 0*


