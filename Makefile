# Makefile for 6520 PIA / 6522 VIA test programs
# Target: Commodore PET 4032
# Assembler: xa65 (command: xa)
# Emulator: VICE xpet

XA      = xa
XAFLAGS = -W -XMASM

BUILD   = build
PRG1    = $(BUILD)/pia_test1.prg
PRG2    = $(BUILD)/pet_pia_test1.prg
PRG3    = $(BUILD)/pet_ieee_test1.prg
PRG4    = $(BUILD)/pet_pia_test2.prg
PRG5    = $(BUILD)/via_test1_gen.prg
PRG6    = $(BUILD)/via_test1.prg
D64     = $(BUILD)/via_test.d64

.PHONY: all clean run1 run2 run3 run4 gen5 run5

all: $(PRG1) $(PRG2) $(PRG3) $(PRG4) $(PRG5) $(PRG6) $(D64)

$(BUILD):
	mkdir -p $(BUILD)

$(PRG1): pia_test1.a65 | $(BUILD)
	$(XA) $(XAFLAGS) -o $@ $<

$(PRG2): pet_pia_test1.a65 | $(BUILD)
	$(XA) $(XAFLAGS) -o $@ $<

$(PRG3): pet_ieee_test1.a65 | $(BUILD)
	$(XA) $(XAFLAGS) -o $@ $<

$(PRG4): pet_pia_test2.a65 | $(BUILD)
	$(XA) $(XAFLAGS) -o $@ $<

$(PRG5): via_test1_gen.a65 | $(BUILD)
	$(XA) $(XAFLAGS) -o $@ $<

$(PRG6): via_test1.a65 | $(BUILD)
	$(XA) $(XAFLAGS) -o $@ $<

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

clean:
	rm -rf $(BUILD)
