
all: upetinit tests

tests:
	(rm -f ../build/0*)
	IOBASE=0x9900 make -C .. all
	for i in ../build/0*; do mv $$i .; done
	rm -f 04*gen 08*gen *.d64


upetinit: upetinit.a65
	xa -XMASM -XC -o $@ $<

clean:
	rm -f upetinit
	rm -f 0*


