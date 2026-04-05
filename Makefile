# Makefile for 6520 PIA / 6522 VIA test programs
# Target: Commodore PET 4032
# Assembler: xa65 (command: xa)
# Emulator: VICE xpet

XA      = xa
IOBASE  ?= e800
XAFLAGS = -W -XMASM -DIOBASE=$(IOBASE)

BUILD   = build
LISTING = listing
PRG1    = $(BUILD)/pia_test1
PRG2    = $(BUILD)/pet_pia_test1
PRG3    = $(BUILD)/pet_ieee_test1
PRG4    = $(BUILD)/pet_pia_test2
GEN5    = $(BUILD)/via_test1_gen
PRG5    = $(BUILD)/via_test1
PRG6    = $(BUILD)/pet_userport_test1
PRG7    = $(BUILD)/pet_userport_test2
GEN8    = $(BUILD)/via_sr_test_gen
PRG8    = $(BUILD)/via_sr_test
D64     = $(BUILD)/via_test.d64
D64_SR  = $(BUILD)/via_sr_test.d64
LST1    = $(LISTING)/pia_test1.lst
LST2    = $(LISTING)/pet_pia_test1.lst
LST3    = $(LISTING)/pet_ieee_test1.lst
LST4    = $(LISTING)/pet_pia_test2.lst
LSTGEN5 = $(LISTING)/via_test1_gen.lst
LST5    = $(LISTING)/via_test1.lst
LST6    = $(LISTING)/pet_userport_test1.lst
LST7    = $(LISTING)/pet_userport_test2.lst
LSTGEN8 = $(LISTING)/via_sr_test_gen.lst
LST8    = $(LISTING)/via_sr_test.lst

.PHONY: all clean run1 run2 run3 run4 gen5 run5 run6 run7 gen8 run8

all: $(PRG1) $(PRG2) $(PRG3) $(PRG4) $(GEN5) $(PRG5) $(PRG6) $(PRG7) $(GEN8) $(PRG8) $(D64) $(D64_SR)

$(BUILD):
	mkdir -p $(BUILD)

$(LISTING):
	mkdir -p $(LISTING)

$(PRG1): pia_test1.a65 | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LST1) $<

$(PRG2): pet_pia_test1.a65 | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LST2) $<

$(PRG3): pet_ieee_test1.a65 | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LST3) $<

$(PRG4): pet_pia_test2.a65 | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LST4) $<

$(GEN5): via_test1_gen.a65 via_meas.inc pet_kernal.inc | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LSTGEN5) $<

$(PRG5): via_test1.a65 via_meas.inc pet_kernal.inc | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LST5) $<

$(PRG6): pet_userport_test1.a65 | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LST6) $<

$(PRG7): pet_userport_test2.a65 | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LST7) $<

$(GEN8): via_sr_test_gen.a65 via_sr_meas.inc pet_kernal.inc | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LSTGEN8) $<

$(PRG8): via_sr_test.a65 via_sr_meas.inc pet_kernal.inc | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LST8) $<

$(D64): $(GEN5) $(PRG5) | $(BUILD)
	c1541 -format "via tests,vt" d64 $@
	c1541 $@ -write $(GEN5) via_test1_gen
	c1541 $@ -write $(PRG5) via_test1

$(D64_SR): $(GEN8) $(PRG8) | $(BUILD)
	c1541 -format "sr tests,sr" d64 $@
	c1541 $@ -write $(GEN8) via_sr_test_gen
	c1541 $@ -write $(PRG8) via_sr_test

# Run pia_test1 in VICE (PET 4032)
run1: $(PRG1)
	bash vice/run_test1.sh

# Run pet_pia_test1 in VICE (PET 4032)
run2: $(PRG2)
	bash vice/run_pet_pia_test1.sh

# Run pet_ieee_test1 in VICE (PET 4032)
run3: $(PRG3)
	bash vice/run_pet_ieee_test1.sh

# Run pet_pia_test2 in VICE (PET 4032)
run4: $(PRG4)
	bash vice/run_pet_pia_test2.sh

# Run via_test1_gen in VICE to produce reference data files
gen5: $(D64)
	bash vice/run_via_test1_gen.sh $(D64)

# Run via_test1 in VICE using the reference data files
run5: $(D64)
	bash vice/run_via_test1.sh $(D64)

# Run pet_userport_test1 in VICE (PET 4032)
run6: $(PRG6)
	bash vice/run_pet_userport_test1.sh

# Run pet_userport_test2 in VICE (PET 4032)
run7: $(PRG7)
	bash vice/run_pet_userport_test2.sh

# Run via_sr_test_gen in VICE to produce SR reference data files
gen8: $(D64_SR)
	bash vice/run_via_sr_test_gen.sh $(D64_SR)

# Run via_sr_test in VICE using the SR reference data files
run8: $(D64_SR)
	bash vice/run_via_sr_test.sh $(D64_SR)

clean:
	rm -rf $(BUILD) $(LISTING)
