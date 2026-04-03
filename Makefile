# Makefile for 6520 PIA / 6522 VIA test programs
# Target: Commodore PET 4032
# Assembler: xa65 (command: xa)
# Emulator: VICE xpet

XA      = xa
XAFLAGS = -W -XMASM

BUILD   = build
LISTING = listing
PRG1    = $(BUILD)/pia_test1
PRG2    = $(BUILD)/pet_pia_test1
PRG3    = $(BUILD)/pet_ieee_test1
PRG4    = $(BUILD)/pet_pia_test2
PRG5    = $(BUILD)/via_test1_gen
PRG6    = $(BUILD)/via_test1
PRG7    = $(BUILD)/userport_test1
PRG8    = $(BUILD)/userport_test2
D64     = $(BUILD)/via_test.d64
LST1    = $(LISTING)/pia_test1.lst
LST2    = $(LISTING)/pet_pia_test1.lst
LST3    = $(LISTING)/pet_ieee_test1.lst
LST4    = $(LISTING)/pet_pia_test2.lst
LST5    = $(LISTING)/via_test1_gen.lst
LST6    = $(LISTING)/via_test1.lst
LST7    = $(LISTING)/userport_test1.lst
LST8    = $(LISTING)/userport_test2.lst

.PHONY: all clean run1 run2 run3 run4 gen5 run5 run7 run8

all: $(PRG1) $(PRG2) $(PRG3) $(PRG4) $(PRG5) $(PRG6) $(PRG7) $(PRG8) $(D64)

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

$(PRG5): via_test1_gen.a65 via_meas.inc pet_kernal.inc | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LST5) $<

$(PRG6): via_test1.a65 via_meas.inc pet_kernal.inc | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LST6) $<

$(PRG7): pet_userport_test1.a65 | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LST7) $<

$(PRG8): pet_userport_test2.a65 | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LST8) $<

$(D64): $(PRG5) $(PRG6) | $(BUILD)
	c1541 -format "via tests,vt" d64 $@
	c1541 $@ -write $(PRG5) via_test1_gen
	c1541 $@ -write $(PRG6) via_test1

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
run7: $(PRG7)
	bash vice/run_pet_userport_test1.sh

# Run pet_userport_test2 in VICE (PET 4032)
run8: $(PRG8)
	bash vice/run_pet_userport_test2.sh

clean:
	rm -rf $(BUILD) $(LISTING)
