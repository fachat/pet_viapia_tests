# Makefile for 6520 PIA test programs
# Target: Commodore PET 4032
# Assembler: xa65 (command: xa)
# Emulator: VICE xpet

XA      = xa
XAFLAGS = -W -XMASM

BUILD   = build
PRG1    = $(BUILD)/pia_test1.prg
PRG2    = $(BUILD)/pia_test2.prg
PRG3    = $(BUILD)/pia_test3.prg
PRG4    = $(BUILD)/pia_test4.prg

.PHONY: all clean run1 run2 run3 run4

all: $(PRG1) $(PRG2) $(PRG3) $(PRG4)

$(BUILD):
	mkdir -p $(BUILD)

$(PRG1): pia_test1.a65 | $(BUILD)
	$(XA) $(XAFLAGS) -o $@ $<

$(PRG2): pia_test2.a65 | $(BUILD)
	$(XA) $(XAFLAGS) -o $@ $<

$(PRG3): pia_test3.a65 | $(BUILD)
	$(XA) $(XAFLAGS) -o $@ $<

$(PRG4): pia_test4.a65 | $(BUILD)
	$(XA) $(XAFLAGS) -o $@ $<

# Run Module 1 in VICE (PET 4032)
run1: $(PRG1)
	bash vice/run_test1.sh

# Run Module 2 in VICE (PET 4032)
run2: $(PRG2)
	bash vice/run_test2.sh

# Run Module 3 in VICE (PET 4032)
run3: $(PRG3)
	bash vice/run_test3.sh

# Run Module 4 in VICE (PET 4032)
run4: $(PRG4)
	bash vice/run_test4.sh

clean:
	rm -rf $(BUILD)
