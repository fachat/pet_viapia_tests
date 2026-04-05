
# UltiPet/cbmio tests

This folder contains the reference values and setup for
the Ultra-CPU / UltiPET using a csa_cbmio board based on
an FPGA, addressed in the I/O window at $99xx.
I.e. the PIAs are at $9910 and $9920, and the VIA is at $9940.

The test programs from one level above can be built
with a different base address. A `make` command here builds it
with the new address.

Also, in this folder, are reference test output created
on a CSA_PETIO board using a WDC65C22 chip.


