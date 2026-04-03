# test_copilot_piavia_testprogrs
Test programs for the PIA and VIA chips in 6502 assembler.

Target: **Commodore PET 4032**  
Assembler: **xa65** (`xa -W -XMASM`)  
Build: `make all`  
Run in VICE: `make run1` … `make run5` (see Makefile)

---

## Test Programs

### `pia_test1.a65` — PIA Test Module 1: General Functionality

Tests 6520 PIA register access that does not require any external I/O connections.
Runs on both PIA1 ($E810) and PIA2 ($E820).

| Test | Description |
|------|-------------|
| DDR A/B (PIA1 & PIA2) | Writes patterns ($FF/$55/$AA/$00) to each Data Direction Register and reads them back to confirm correct read/write behaviour. |
| CR A/B (PIA1 & PIA2) | Writes and reads back bits 5:0 of each Control Register (bits 7:6 are read-only interrupt flags and are masked). |

---

### `pet_pia_test1.a65` — PIA Test Module 2: PET-Specific I/O

Tests the two 6520 PIAs using the actual I/O connections on the PET 4032.

| Test | Description |
|------|-------------|
| 1 — PIA1 DDRA=$0F | Configures the lower nibble of Port-A as outputs; reads back to verify the DDR setting. |
| 2 — PIA1 DDRB=$00 | Configures all Port-B lines as inputs (keyboard column sense); reads back to verify. |
| 3 — KBD SCAN IDLE | Deasserts all keyboard rows via Port-A and reads Port-B; expects $FF when no key is pressed. |

---

### `pet_ieee_test1.a65` — PIA Test Module 3: IEEE-488 Bus Tests

Tests PIA2 and the VIA for correct operation of the IEEE-488 interface.

| Test | Description |
|------|-------------|
| 1 — PIA2 DDRA=$00 | Verifies that all Port-A lines of PIA2 are configured as inputs (data bus receive). |
| 2 — PIA2 DDRB=$FF | Verifies that all Port-B lines of PIA2 are configured as outputs (data bus drive). |
| 3 — BUS LOOPBACK | Writes patterns to PIA2 Port-B (outputs) and reads them back via Port-A (inputs); values must match (bus buffers invert twice). |
| 4 — EOI LOOPBACK | Drives PIA1 CA2 (EOI output) high then low; verifies that PIA1 PA6 (EOI input) follows each state. |
| 5 — VIA DDRB=$1E | Checks that VIA Port-B bits 1–4 are configured as outputs for IEEE-488 handshake lines. |
| 6 — DAV LOOPBACK | Drives the DAV line and reads it back to confirm loopback integrity. |
| 7 — NRFD LOOPBACK | Drives the NRFD line and reads it back. |
| 8 — NDAC LOOPBACK | Drives the NDAC line and reads it back. |

---

### `pet_pia_test2.a65` — PIA Test Module 4: CB1 Vertical Blank Signal Tests

Tests PIA1 CB1 input (vertical blank / frame-sync signal), which also appears on VIA PB5.

| Test | Description |
|------|-------------|
| 1a — POS PERIOD | Measures CPU cycles between consecutive positive CB1 edges; passes if within ±4 of 16600 (60 Hz NTSC) or 20000 (50 Hz PAL). Aborts remaining tests if no edge is detected within 200 000 cycles. |
| 1b — NEG PERIOD | Same period measurement using consecutive negative CB1 edges. |
| 2a — HIGH PHASE | Counts cycles while VIA PB5 stays high after the first positive transition; passes if count is less than the full period from test 1a. |
| 2b — LOW PHASE | Counts cycles while VIA PB5 stays low after the first negative transition; passes if count is less than the full period. |
| 3a — IRQFLAG POS | Verifies IRQB1 (CRB bit 7) is set on a positive CB1 transition (CRB bit1=1, bit0=0; flag only, no CPU /IRQ). |
| 3b — IRQFLAG NEG | Verifies IRQB1 is set on a negative CB1 transition (CRB bit1=0, bit0=0). |
| 4a — CPU IRQ POS | Verifies a positive CB1 transition triggers a CPU /IRQ (CRB bit1=1, bit0=1) by redirecting the user IRQ vector to a test handler. |
| 4b — CPU IRQ NEG | Verifies a negative CB1 transition triggers a CPU /IRQ (CRB bit1=0, bit0=1). |

---

### `via_test1_gen.a65` — VIA Test 1: Reference Data Generator

Runs the same timing measurement loops used by `via_test1.a65` and saves the raw 256-byte results to CBM sequential files on device 8 (IEEE-488 disk drive).
Run this **once** on a known-good machine or in VICE to produce the reference files that `via_test1.a65` compares against.

| Reference file written | Description |
|------------------------|-------------|
| `VIA.T1.SS.0` | T1 single-shot, latch=$00 |
| `VIA.T1.SS.1` | T1 single-shot, latch=$01 |
| `VIA.T1.SS.2` | T1 single-shot, latch=$02 |
| `VIA.T1.SS.FF` | T1 single-shot, latch=$FF |
| `VIA.T1.FR.0` | T1 free-run, latch=$00 |
| `VIA.T1.FR.1` | T1 free-run, latch=$01 |
| `VIA.T1.FR.2` | T1 free-run, latch=$02 |
| `VIA.T1.FR.FF` | T1 free-run, latch=$FF |
| `VIA.T1.RST` | T1 single-shot, reset mid-count ($FF → $80) |
| `VIA.T2.0` | T2 one-shot, latch=$00 |
| `VIA.T2.1` | T2 one-shot, latch=$01 |
| `VIA.T2.2` | T2 one-shot, latch=$02 |
| `VIA.T2.FF` | T2 one-shot, latch=$FF |
| `VIA.SR.IT2.A.H` | SR shift-in via T2, T2 pre-set ($04FF then $0210), T2CH (high byte) samples |
| `VIA.SR.IT2.A.L` | SR shift-in via T2, T2 pre-set ($04FF then $0210), T2CL (low byte) samples |
| `VIA.SR.IT2.B.H` | SR shift-in via T2, T2=$0210 direct, T2CH samples |
| `VIA.SR.IT2.B.L` | SR shift-in via T2, T2=$0210 direct, T2CL samples |
| `VIA.SR.IT2.C.H` | SR shift-in via T2, T2=$0210 + 16-cycle wait + latch low=$20, T2CH samples |
| `VIA.SR.IT2.C.L` | SR shift-in via T2, T2=$0210 + 16-cycle wait + latch low=$20, T2CL samples |

---

### `via_test1.a65` — VIA Test Module 1: Generic 6522 VIA Tests

Tests the 6522 VIA at $E840.  Groups 1–2 are self-contained register tests; Groups 3–7 compare a live 256-byte timing capture against the reference files produced by `via_test1_gen.prg`.  On a mismatch the output shows `FAIL @xx` where `xx` is the hex index of the first differing byte.

| Test | ACR setup | Description |
|------|-----------|-------------|
| **GRP1: T1 LATCH/COUNTER REGS** | — (no change) | |
| 1A — T1LL/T1LH RD/WR | | Writes values to the T1 low and high latch registers and reads them back via the latch addresses. |
| 1B — T1LL/T1LH NO-START | | Confirms that writing T1LL/T1LH does not start the T1 counter. |
| 1C — T1LH CLEARS IFR6 | | Verifies that writing the T1 latch-high register clears IFR bit 6 (T1 interrupt flag). |
| 1D — T1CH LOADS+STARTS | | Confirms that writing T1CH loads the counter from the latch and starts T1 counting. |
| **GRP2: T2 LATCH/COUNTER REGS** | — (no change) | |
| 2A — T2CL NO-START | | Writes T2CL latch and confirms that writing T2CL alone does not start the counter. |
| 2B — T2CH STARTS | | Confirms that writing T2CH loads the counter from the T2CL latch and starts T2. |
| **GRP3: T1 SINGLE-SHOT** | bits 7–6 = `$00` (T1 single-shot, no PB7) | |
| 3A — T1-SS LATCH=00 | | Captures 256 T1 single-shot timing samples with latch=$00 and compares against `VIA.T1.SS.0`. |
| 3B — T1-SS LATCH=01 | | Same test with latch=$01; compares against `VIA.T1.SS.1`. |
| 3C — T1-SS LATCH=02 | | Same test with latch=$02; compares against `VIA.T1.SS.2`. |
| 3D — T1-SS LATCH=FF | | Same test with latch=$FF; compares against `VIA.T1.SS.FF`. |
| **GRP4: T1 FREE-RUN** | bits 7–6 = `$80` (T1 free-run, no PB7) | |
| 4A — T1-FR LATCH=00 | | Captures 256 T1 free-run timing samples with latch=$00 and compares against `VIA.T1.FR.0`. |
| 4B — T1-FR LATCH=01 | | Same test with latch=$01; compares against `VIA.T1.FR.1`. |
| 4C — T1-FR LATCH=02 | | Same test with latch=$02; compares against `VIA.T1.FR.2`. |
| 4D — T1-FR LATCH=FF | | Same test with latch=$FF; compares against `VIA.T1.FR.FF`. |
| **GRP5: T1 RESET MID-COUNT** | bits 7–6 = `$00` (T1 single-shot, no PB7) | |
| 5 — T1-RST FF→80 | | Starts T1 at latch=$FF, resets mid-count to $80, captures 256 timing samples and compares against `VIA.T1.RST`. |
| **GRP6: T2 ONE-SHOT** | bit 5 = `0` (T2 timer mode, bit 5 cleared) | |
| 6A — T2 LATCH=00 | | Captures 256 T2 one-shot timing samples with latch=$00 and compares against `VIA.T2.0`. |
| 6B — T2 LATCH=01 | | Same test with latch=$01; compares against `VIA.T2.1`. |
| 6C — T2 LATCH=02 | | Same test with latch=$02; compares against `VIA.T2.2`. |
| 6D — T2 LATCH=FF | | Same test with latch=$FF; compares against `VIA.T2.FF`. |
| **GRP7: SR SHIFT-IN VIA T2** | bits 4–2 = `$04` (SR shift-in under T2 clock); bit 5 = `0` (T2 timer mode) | NOTE: CB1 must not be hard-wired as input — the VIA drives CB1 as output clock in this mode. |
| 7A — SR-IN T2 SETUP HI | | Scenario A (T2 pre-set $04FF then $0210): captures 256 T2CH samples while SR shifts in under T2; compares against `VIA.SR.IT2.A.H`. |
| 7B — SR-IN T2 SETUP LO | | Same scenario A setup; captures 256 T2CL samples; compares against `VIA.SR.IT2.A.L`. |
| 7C — SR-IN T2 DIRECT HI | | Scenario B (T2 set directly to $0210): captures 256 T2CH samples; compares against `VIA.SR.IT2.B.H`. |
| 7D — SR-IN T2 DIRECT LO | | Same scenario B setup; captures 256 T2CL samples; compares against `VIA.SR.IT2.B.L`. |
| 7E — SR-IN T2 LATCH HI | | Scenario C (T2=$0210, 16-cycle wait, then T2CL latch overridden to $20): captures 256 T2CH samples; compares against `VIA.SR.IT2.C.H`. |
| 7F — SR-IN T2 LATCH LO | | Same scenario C setup; captures 256 T2CL samples; compares against `VIA.SR.IT2.C.L`. |

