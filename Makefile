# Makefile for 6520 PIA / 6522 VIA test programs
# Target: Commodore PET 4032
# Assembler: xa65 (command: xa)
# Emulator: VICE xpet

XA      = xa
IOBASE  ?= \$$e800
XAFLAGS = -W -XC -XMASM -DIOBASE=$(IOBASE)

BUILD   = build
LISTING = listing
PRG1    = $(BUILD)/01_pia_test1
PRG2    = $(BUILD)/02_pia_test1
PRG3    = $(BUILD)/03_ieee_test1
GEN4    = $(BUILD)/04_via_test1_gen
PRG4    = $(BUILD)/04_via_test1
PRG5    = $(BUILD)/05_pia_test2
PRG6    = $(BUILD)/06_userport_t1
PRG7    = $(BUILD)/07_userport_t2
GEN8    = $(BUILD)/08_sr_test_gen
PRG8    = $(BUILD)/08_sr_test
D64     = $(BUILD)/via_test.d64
D64_SR  = $(BUILD)/via_sr_test.d64
LST1    = $(LISTING)/01_pia_test1.lst
LST2    = $(LISTING)/02_pia_test1.lst
LST3    = $(LISTING)/03_ieee_test1.lst
LSTGEN4 = $(LISTING)/04_via_test1_gen.lst
LST4    = $(LISTING)/04_via_test1.lst
LST5    = $(LISTING)/05_pia_test2.lst
LST6    = $(LISTING)/06_userport_t1.lst
LST7    = $(LISTING)/07_userport_t2.lst
LSTGEN8 = $(LISTING)/08_sr_test_gen.lst
LST8    = $(LISTING)/08_sr_test.lst

MENU     = $(BUILD)/menu
LSTMENU  = $(LISTING)/menu.lst
D64_MENU = $(BUILD)/menu_tests.d64

.PHONY: all clean run1 run2 run3 run4 run5 gen4 run6 run7 gen8 run8 menu run_menu

all: $(PRG1) $(PRG2) $(PRG3) $(GEN4) $(PRG4) $(PRG5) $(PRG6) $(PRG7) $(GEN8) $(PRG8) $(D64) $(D64_SR) $(MENU) $(D64_MENU)

$(BUILD):
	mkdir -p $(BUILD)

$(LISTING):
	mkdir -p $(LISTING)

$(PRG1): 01_pia_test1.a65 | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LST1) $<

$(PRG2): 02_pia_test1.a65 | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LST2) $<

$(PRG3): 03_ieee_test1.a65 | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LST3) $<

$(GEN4): 04_via_test1_gen.a65 meas.inc kernal.inc | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LSTGEN4) $<

$(PRG4): 04_via_test1.a65 meas.inc kernal.inc | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LST4) $<

$(PRG5): 05_pia_test2.a65 | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LST5) $<

$(PRG6): 06_userport_t1.a65 | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LST6) $<

$(PRG7): 07_userport_t2.a65 | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LST7) $<

$(GEN8): 08_sr_test_gen.a65 sr_meas.inc kernal.inc | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LSTGEN8) $<

$(PRG8): 08_sr_test.a65 sr_meas.inc kernal.inc | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LST8) $<

$(D64): $(GEN4) $(PRG4) | $(BUILD)
	c1541 -format "via tests,vt" d64 $@
	c1541 $@ -write $(GEN4) 04_via_test1_gen
	c1541 $@ -write $(PRG4) 04_via_test1

$(D64_SR): $(GEN8) $(PRG8) | $(BUILD)
	c1541 -format "sr tests,sr" d64 $@
	c1541 $@ -write $(GEN8) 08_sr_test_gen
	c1541 $@ -write $(PRG8) 08_sr_test

# Run pia_test1 in VICE (PET 4032)
run1: $(PRG1)
	bash vice/run_01_pia_test1.sh

# Run pet_pia_test1 in VICE (PET 4032)
run2: $(PRG2)
	bash vice/run_02_pia_test1.sh

# Run pet_ieee_test1 in VICE (PET 4032)
run3: $(PRG3)
	bash vice/run_03_ieee_test1.sh

# Run pet_pia_test2 in VICE (PET 4032)
run5: $(PRG5)
	bash vice/run_05_pia_test2.sh

# Run via_test1_gen in VICE to produce reference data files
gen4: $(D64)
	bash vice/run_04_via_test1_gen.sh $(D64)

# Run via_test1 in VICE using the reference data files
run4: $(D64)
	bash vice/run_04_via_test1.sh $(D64)

# Run pet_userport_t1 in VICE (PET 4032)
run6: $(PRG6)
	bash vice/run_06_userport_t1.sh

# Run pet_userport_t2 in VICE (PET 4032)
run7: $(PRG7)
	bash vice/run_07_userport_t2.sh

# Run via_sr_test_gen in VICE to produce SR reference data files
gen8: $(D64_SR)
	bash vice/run_08_sr_test_gen.sh $(D64_SR)

# Run via_sr_test in VICE using the SR reference data files
run8: $(D64_SR)
	bash vice/run_08_sr_test.sh $(D64_SR)

$(MENU): menu.a65 | $(BUILD) $(LISTING)
	$(XA) $(XAFLAGS) -o $@ -P $(LSTMENU) $<

# Combined disk image with the menu launcher and all test/generator programs.
# Load with: LOAD "menu",8 then RUN
$(D64_MENU): $(MENU) $(PRG1) $(PRG2) $(PRG3) $(GEN4) $(PRG4) $(PRG5) $(PRG6) $(PRG7) $(GEN8) $(PRG8) | $(BUILD)
	c1541 -format "test menu,tm" d64 $@
	c1541 $@ -write $(MENU)   menu
	c1541 $@ -write $(PRG1)   01_pia_test1
	c1541 $@ -write $(PRG2)   02_pia_test1
	c1541 $@ -write $(PRG3)   03_ieee_test1
	c1541 $@ -write $(GEN4)   04_via_test1_gen
	c1541 $@ -write $(PRG4)   04_via_test1
	c1541 $@ -write $(PRG5)   05_pia_test2
	c1541 $@ -write $(PRG6)   06_userport_t1
	c1541 $@ -write $(PRG7)   07_userport_t2
	c1541 $@ -write $(GEN8)   08_sr_test_gen
	c1541 $@ -write $(PRG8)   08_sr_test

menu: $(MENU) $(D64_MENU)

# Run the test menu in VICE (PET 4032) using the combined disk image
run_menu: $(D64_MENU)
	bash vice/run_menu.sh $(D64_MENU)

clean:
	rm -rf $(BUILD) $(LISTING)
