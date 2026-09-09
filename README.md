# test_copilot_piavia_testprogrs
Test programs for the PIA and VIA chips in 6502 assembler.

Target: **Commodore PET 4032**  
Assembler: **xa65** (`xa -W -XC -XMASM`)  
Build: `make all`  
Run in VICE: `make run1` … `make run8`, `make gen4`, `make gen8` (see Makefile)

Note: the Makefile can build the test programs for I/O at a different base address. E.g. run as
`IOBASE=0x9900 make` to build for PIAs at $9910 and $9920, and the VIA at $9940.

---

## Test Programs

### `01-pia-test1.a65` — PIA Test Module 1: General Functionality

Tests 6520 PIA register access that does not require any external I/O connections.
Runs on both PIA1 ($E810) and PIA2 ($E820).

| Test | Description |
|------|-------------|
| DDR A/B (PIA1 & PIA2) | Writes patterns ($FF/$55/$AA/$00) to each Data Direction Register and reads them back to confirm correct read/write behaviour. |
| CR A/B (PIA1 & PIA2) | Writes and reads back bits 5:0 of each Control Register (bits 7:6 are read-only interrupt flags and are masked). |

---

### `02-pia-test1.a65` — PIA Test Module 2: PET-Specific I/O

Tests the two 6520 PIAs using the actual I/O connections on the PET 4032.

| Test | Description |
|------|-------------|
| 1 — PIA1 DDRA=$0F | Configures the lower nibble of Port-A as outputs; reads back to verify the DDR setting. |
| 2 — PIA1 DDRB=$00 | Configures all Port-B lines as inputs (keyboard column sense); reads back to verify. |
| 3 — KBD SCAN IDLE | Deasserts all keyboard rows via Port-A and reads Port-B; expects $FF when no key is pressed. |

---

### `03-ieee-test1.a65` — PIA Test Module 3: IEEE-488 Bus Tests

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

### `04-via-test1-gen.a65` — VIA Test 1: Reference Data Generator (GEN 4)

Runs the same timing measurement loops used by `04-via-test1.a65` and saves the raw 256-byte results to CBM sequential files on device 8 (IEEE-488 disk drive).
Run this **once** on a known-good machine or in VICE (`make gen4`) to produce the reference files that `04-via-test1.a65` compares against.

| Reference file written | Description |
|------------------------|-------------|
| `V.T1.SS.0` | T1 single-shot, latch=$00 |
| `V.T1.SS.1` | T1 single-shot, latch=$01 |
| `V.T1.SS.2` | T1 single-shot, latch=$02 |
| `V.T1.SS.FF` | T1 single-shot, latch=$FF |
| `V.T1.FR.0` | T1 free-run, latch=$00 |
| `V.T1.FR.1` | T1 free-run, latch=$01 |
| `V.T1.FR.2` | T1 free-run, latch=$02 |
| `V.T1.FR.FF` | T1 free-run, latch=$FF |
| `V.T1.RST` | T1 single-shot, reset mid-count ($FF → $80) |
| `V.T2.0` | T2 one-shot, latch=$00 |
| `V.T2.1` | T2 one-shot, latch=$01 |
| `V.T2.2` | T2 one-shot, latch=$02 |
| `V.T2.FF` | T2 one-shot, latch=$FF |
| `V.SR.IT2G7.A.H` | SR shift-in via T2, T2 pre-set ($04FF then $0210), T2CH (high byte) samples |
| `V.SR.IT2G7.A.L` | SR shift-in via T2, T2 pre-set ($04FF then $0210), T2CL (low byte) samples |
| `V.SR.IT2G7.B.H` | SR shift-in via T2, T2=$0210 direct, T2CH samples |
| `V.SR.IT2G7.B.L` | SR shift-in via T2, T2=$0210 direct, T2CL samples |
| `V.SR.IT2G7.C.H` | SR shift-in via T2, T2=$0210 + 16-cycle wait + latch low=$20, T2CH samples |
| `V.SR.IT2G7.C.L` | SR shift-in via T2, T2=$0210 + 16-cycle wait + latch low=$20, T2CL samples |

---

### `04-via-test1.a65` — VIA Test Module 1: Generic 6522 VIA Tests (Test 4)

Tests the 6522 VIA at $E840.  Groups 1–2 are self-contained register tests; Groups 3–7 compare a live 256-byte timing capture against the reference files produced by `via_test1_gen.prg`.  On a mismatch the output shows `FAIL @xx` where `xx` is the hex index of the first differing byte.

| Test | ACR setup | Description |
|------|-----------|-------------|
| **GRP1: T1 LATCH/COUNTER REGS** | — (no change) | |
| 1A — T1LL/T1LH RD/WR | | Writes values to the T1 low and high latch registers and reads them back via the latch addresses. |
| 1B — T1LL/T1LH NO-START | | Confirms that writing T1LL/T1LH does not start the T1 counter. |
| 1C — T1LH CLEARS IFR6 | | Verifies that writing the T1 latch-high register clears IFR bit 6 (T1 interrupt flag). |
| 1D — T1CH LOADS+STARTS | | Confirms that writing T1CH loads the counter from the latch and starts T1 counting. |
| 1E — T1CH STARTS IFR.T1 | | Sets T1 latch to $0000 so the timer underflows almost immediately after being started by writing T1CH; verifies that IFR bit 6 (T1 interrupt flag) is set after the underflow. |
| 1F — IFR WRITE CLEARS IFR6 | | Verifies that writing IFR_T1 (bit 6) directly to the IFR register clears IFR bit 6. |
| **GRP2: T2 LATCH/COUNTER REGS** | — (no change) | |
| 2A — T2CL NO-START | | Writes T2CL latch and confirms that writing T2CL alone does not start the counter. |
| 2B — T2CH STARTS | | Confirms that writing T2CH loads the counter from the T2CL latch and starts T2. |
| **GRP3: T1 SINGLE-SHOT** | bits 7–6 = `$00` (T1 single-shot, no PB7) | |
| 3A — T1-SS LATCH=00 | | Captures 256 T1 single-shot timing samples with latch=$00 and compares against `V.T1.SS.0`. |
| 3B — T1-SS LATCH=01 | | Same test with latch=$01; compares against `V.T1.SS.1`. |
| 3C — T1-SS LATCH=02 | | Same test with latch=$02; compares against `V.T1.SS.2`. |
| 3D — T1-SS LATCH=FF | | Same test with latch=$FF; compares against `V.T1.SS.FF`. |
| **GRP4: T1 FREE-RUN** | bits 7–6 = `$80` (T1 free-run, no PB7) | |
| 4A — T1-FR LATCH=00 | | Captures 256 T1 free-run timing samples with latch=$00 and compares against `V.T1.FR.0`. |
| 4B — T1-FR LATCH=01 | | Same test with latch=$01; compares against `V.T1.FR.1`. |
| 4C — T1-FR LATCH=02 | | Same test with latch=$02; compares against `V.T1.FR.2`. |
| 4D — T1-FR LATCH=FF | | Same test with latch=$FF; compares against `V.T1.FR.FF`. |
| **GRP5: T1 RESET MID-COUNT** | bits 7–6 = `$00` (T1 single-shot, no PB7) | |
| 5 — T1-RST FF→80 | | Starts T1 at latch=$FF, resets mid-count to $80, captures 256 timing samples and compares against `V.T1.RST`. |
| **GRP6: T2 ONE-SHOT** | bit 5 = `0` (T2 timer mode, bit 5 cleared) | |
| 6A — T2 LATCH=00 | | Captures 256 T2 one-shot timing samples with latch=$00 and compares against `V.T2.0`. |
| 6B — T2 LATCH=01 | | Same test with latch=$01; compares against `V.T2.1`. |
| 6C — T2 LATCH=02 | | Same test with latch=$02; compares against `V.T2.2`. |
| 6D — T2 LATCH=FF | | Same test with latch=$FF; compares against `V.T2.FF`. |
| **GRP7: SR SHIFT-IN VIA T2** | bits 4–2 = `$04` (SR shift-in under T2 clock); bit 5 = `0` (T2 timer mode) | NOTE: CB1 must not be hard-wired as input — the VIA drives CB1 as output clock in this mode. |
| 7A — SR-IN T2 SETUP HI | | Scenario A (T2 pre-set $04FF then $0210): captures 256 T2CH samples while SR shifts in under T2; compares against `V.SR.IT2G7.A.H`. |
| 7B — SR-IN T2 SETUP LO | | Same scenario A setup; captures 256 T2CL samples; compares against `V.SR.IT2G7.A.L`. |
| 7C — SR-IN T2 DIRECT HI | | Scenario B (T2 set directly to $0210): captures 256 T2CH samples; compares against `V.SR.IT2G7.B.H`. |
| 7D — SR-IN T2 DIRECT LO | | Same scenario B setup; captures 256 T2CL samples; compares against `V.SR.IT2G7.B.L`. |
| 7E — SR-IN T2 LATCH HI | | Scenario C (T2=$0210, 16-cycle wait, then T2CL latch overridden to $20): captures 256 T2CH samples; compares against `V.SR.IT2G7.C.H`. |
| 7F — SR-IN T2 LATCH LO | | Same scenario C setup; captures 256 T2CL samples; compares against `V.SR.IT2G7.C.L`. |

---

### `05-pia-test2.a65` — PIA Test Module 5: CB1 Vertical Blank Signal Tests

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

### `06-userport-t1.a65` — PET Userport Test Module 1: VIA Userport Connection Tests (Test 6)

Tests the VIA and PIA1 using specific connections wired at the PET userport.
Only output-by-default pins drive input-by-default pins to avoid bus contention.

Required connections:

| Userport pin | Signal |
|---|---|
| C (PA0) – D (PA1) | PA0/PA1 loopback pair |
| E (PA2) – F (PA3) | PA2/PA3 loopback pair |
| H (PA4) – 7 (PB3) | PA4 / PB3 cross-loopback |
| J (PA5) – K (PA6) | PA5/PA6 loopback pair |
| L (PA7) – M (CB2) | PA7 / CB2 cross-loopback |
| 5 (PIA1 PA7) – 6 (CB1) | PIA1 PA7 output drives CB1 input |
| B (CA1) – 11 (CA2) | CA2 manual output drives CA1 input |

| Test | Description |
|------|-------------|
| 1a — PA LO OUT | DDRA=$25 (PA0,PA2,PA5 outputs → PA1,PA3,PA6 inputs). Writes $00 (read & $4A = $00) and $25 (read & $4A = $4A). PA4 and PA7 are masked out. |
| 1b — PA HI OUT | DDRA=$4A (PA1,PA3,PA6 outputs → PA0,PA2,PA5 inputs). Writes $00 (read & $25 = $00) and $4A (read & $25 = $25). |
| 2a — PA4→PB3 | PA4 = output, PB3 = input (DDRB bit 3 temporarily cleared). PA4=1 → PB3 reads 1; PA4=0 → PB3 reads 0. |
| 2b — PB3→PA4 | PB3 = output (default), PA4 = input. PB3=1 → PA4 reads 1; PB3=0 → PA4 reads 0. |
| 3a — CB2→PA7 | CB2 as manual output drives PA7 as input. PCR[7:5]=111 → PA7 reads 1; PCR[7:5]=110 → PA7 reads 0. |
| 3b — PA7→CB2 NORM | PA7 output drives CB2 input, normal mode (PCR[7:5]=000). PA7 1→0 sets IFR bit 3; reading ORB clears it. |
| 3c — PA7→CB2 INDP | PA7 output drives CB2 input, independent mode (PCR[7:5]=001). PA7 1→0 sets IFR bit 3; reading ORB does NOT clear it; cleared by direct IFR write. |
| 4a — CA1 NEG FLAG | CA2 manual output drives CA1 1→0. Checks IFR bit 1 set; reading ORA (reg $01, with handshake) clears it. |
| 4b — CA1 POS FLAG | CA2 manual output drives CA1 0→1. Checks IFR bit 1 set; reading ORA clears it. |
| 5a — CB1 NEG FLAG | PIA1 PA7 drives CB1 1→0 (ACR SR disabled so CB1 = input; PCR bit 4=0). IFR bit 4 set; reading ORB clears it. |
| 5b — CB1 POS FLAG | PIA1 PA7 drives CB1 0→1 (PCR bit 4=1). IFR bit 4 set; reading ORB clears it. |
| 6a — CB1 NEG IRQ | Enables IER.CB1; PIA1 PA7 drives CB1 1→0; IRQ handler clears IFR.CB1 via direct IFR write; verifies CPU /IRQ fired. |
| 6b — CB2 NEG IRQ | Enables IER.CB2 (normal mode); VIA PA7 output drives CB2 1→0; IRQ handler clears IFR.CB2; verifies CPU /IRQ fired. |
| 6c — CA1 NEG IRQ | Enables IER.CA1; CA2 manual output drives CA1 1→0; IRQ handler clears IFR.CA1; verifies CPU /IRQ fired. |

---

### `07-userport-t2.a65` — PET Userport Test Module 2: VIA PA Latching and Write Handshake (Test 7)

Tests VIA PA input latching and CB2/CA2 write handshake using the same test fixture as Module 1 (see above for required connections).

PA input latch behaviour: IRA is transparent when IFR.CA1=0; it latches on the CA1 active edge; reading ORA returns the latched value and clears IFR.CA1, making IRA transparent again.

| Test | Description |
|------|-------------|
| 1a — PA LATCH LO NEG | DDRA=$25 (PA0,PA2,PA5 outputs). 23-step sequence: verifies transparent reads, latches on CA1 falling edge, ORA read clears flag and reopens latch, second latch cycle with inactive edge test. |
| 1b — PA LATCH HI NEG | DDRA=$4A (PA1,PA3,PA6 outputs); same 23-step sequence with CA1 falling edge. |
| 1c — PA LATCH LO POS | DDRA=$25; CA2 hi = active edge; same 23-step sequence with CA1 rising edge. |
| 1d — PA LATCH HI POS | DDRA=$4A; same as 1c with CA1 rising edge. |
| 1e — PA LATCH CB2→PA7 NEG | CB2 manual output drives PA7 as test data source; CA1 falling edge latches. |
| 1f — PA LATCH CB2→PA7 POS | CB2 manual output drives PA7; CA1 rising edge latches. |
| 1g — PA LATCH PB3→PA4 NEG | PB3 output drives PA4 as test data source; CA1 falling edge latches. |
| 1h — PA LATCH PB3→PA4 POS | PB3 output drives PA4; CA1 rising edge latches. |
| 2a — CB2 HANDSHAKE NEG | PCR: CB2 handshake out, CB1 neg edge trigger. PIA1 PA7 drives CB1=hi. Write ORB → CB2 lo; CB1 lo → CB2 hi; CB1 hi → CB2 hi. Repeated once. |
| 2b — CB2 HANDSHAKE POS | PCR: CB2 handshake out, CB1 pos edge trigger. PIA1 PA7 drives CB1=lo. Write ORB → CB2 lo; CB1 hi → CB2 hi; CB1 lo → CB2 hi. Repeated once. |
| 2c — CA2 PULSE / CA1 IFR | PCR: CA2 pulse output, CA1 positive edge. CA2 and CA1 are looped together. Write ORA → CA2 pulses low then back high → CA1 sees rising edge → IFR.CA1 must be set. |

---

### `08-sr-test-gen.a65` — VIA Shift Register Test: Reference Data Generator (GEN 8)

Runs the SR mode 1, mode 4, and mode 5 measurement loops used by `08-sr-test.a65` and saves the raw 256-byte results to CBM sequential files on device 8 (IEEE-488 disk drive).
Run this **once** on a known-good machine or in VICE (`make gen8`) to produce the reference files that `08-sr-test.a65` compares against.

Requires the userport test fixture (PIA1 PA7 must be an input to avoid bus conflict on CB1 in SR mode 1).

| Reference file written | Description |
|------------------------|-------------|
| `V.SR.M1G2.A` | SR mode 1 (shift in under T2), T2=$0110 |
| `V.SR.M1G2.B` | SR mode 1, T2=$0220 |
| `V.SR.M1G2.C` | SR mode 1, T2=$0330 |
| `V.SR.M1G2.D` | SR mode 1, T2=$0440 |
| `V.SR.M1NG3.A` | SR mode 1 no-arm, T2=$0110 |
| `V.SR.M1NG3.B` | SR mode 1 no-arm, T2=$0220 |
| `V.SR.M1NG3.C` | SR mode 1 no-arm, T2=$0330 |
| `V.SR.M1NG3.D` | SR mode 1 no-arm, T2=$0440 |
| `V.SR.M4G12.55.A` | SR mode 4 (shift out under free-running T2), SR=$55, T2=$0110 |
| `V.SR.M4G12.55.B` | SR mode 4, SR=$55, T2=$0220 |
| `V.SR.M4G12.55.C` | SR mode 4, SR=$55, T2=$0330 |
| `V.SR.M4G12.55.D` | SR mode 4, SR=$55, T2=$0440 |
| `V.SR.M4G13.AA.A` | SR mode 4, SR=$AA, T2=$0110 |
| `V.SR.M4G13.AA.B` | SR mode 4, SR=$AA, T2=$0220 |
| `V.SR.M4G13.AA.C` | SR mode 4, SR=$AA, T2=$0330 |
| `V.SR.M4G13.AA.D` | SR mode 4, SR=$AA, T2=$0440 |
| `V.SR.M5G7.55.A` | SR mode 5 (shift out under T2), SR=$55, T2=$0110 |
| `V.SR.M5G7.55.B` | SR mode 5, SR=$55, T2=$0220 |
| `V.SR.M5G7.55.C` | SR mode 5, SR=$55, T2=$0330 |
| `V.SR.M5G7.55.D` | SR mode 5, SR=$55, T2=$0440 |
| `V.SR.M5G8.AA.A` | SR mode 5, SR=$AA, T2=$0110 |
| `V.SR.M5G8.AA.B` | SR mode 5, SR=$AA, T2=$0220 |
| `V.SR.M5G8.AA.C` | SR mode 5, SR=$AA, T2=$0330 |
| `V.SR.M5G8.AA.D` | SR mode 5, SR=$AA, T2=$0440 |

---

### `08-sr-test.a65` — VIA Shift Register Tests (Test 8)

Tests the 6522 VIA shift register at $E840.  Reference files (produced by `via_sr_test_gen.prg`) must be present on device 8 before running Groups 2 and 3.

Requires the userport test fixture:
- Pin 5 (PIA1 PA7) → Pin 6 (CB1): PIA1 PA7 drives the CB1 clock
- Pin L (VIA PA7) ↔ Pin M (CB2): PA7/CB2 loopback for data

| Group / Test | Description |
|---|---|
| **GRP1: SR MODE 0 — external CB1 clock** | ACR SR = 000. CB1 rising edges shift CB2 data into SR (left-shift, new bit at bit 0). VIA does not count bits; IFR.SR is never set. |
| 1 — MODE 0 SEQUENCE | Verifies SR=$01, $03, $06 after individual CB1 pulses, then an 8-cycle alternating-CB2 loop confirms SR=$AA and IFR.SR=0 throughout. |
| **GRP2: SR MODE 1 — shift in under T2 control** | ACR SR = 001. T2 underflows clock the SR; CB2 held high via PA7 loopback. After 8 bits IFR.SR is set. 256 SR samples compared against reference files. |
| 2A — M1 T2=$0110 | Compares against `V.SR.M1G2.A`. |
| 2B — M1 T2=$0220 | Compares against `V.SR.M1G2.B`. |
| 2C — M1 T2=$0330 | Compares against `V.SR.M1G2.C`. |
| 2D — M1 T2=$0440 | Compares against `V.SR.M1G2.D`. |
| **GRP3: SR MODE 1 NO-ARM — shift in under T2 control** | Identical to Group 2 but the SR read that arms shifting is omitted; first shift occurs on the first T2 underflow after ACR is set. 256 samples compared against reference files. |
| 3A — M1N T2=$0110 | Compares against `V.SR.M1NG3.A`. |
| 3B — M1N T2=$0220 | Compares against `V.SR.M1NG3.B`. |
| 3C — M1N T2=$0330 | Compares against `V.SR.M1NG3.C`. |
| 3D — M1N T2=$0440 | Compares against `V.SR.M1NG3.D`. |
| **GRP4: SR MODE 1 IFR POLL — shift in under T2 control** | Same setup as Group 2 (armed). Polls IFR.SR up to 256 times; prints iteration count on pass; fails if IFR.SR not set within 256 polls. |
| 4A–4D | T2=$0110, $0220, $0330, $0440. |
| **GRP5: SR MODE 1 NO-ARM IFR POLL** | Same as Group 4 but SR arm read omitted (matching Group 3 setup). |
| 5A–5D | T2=$0110, $0220, $0330, $0440. |
| **GRP6: SR MODE 3 — shift in under external CB1 control** | ACR SR = 011. CB1 rising edges shift CB2 data into SR (MSB first). After 8 edges IFR.SR is set. Data is bit-banged in; SR is read back and compared to the original byte. |
| 6A — M3 DATA=$55 | Shifts $55; verifies IFR.SR=1 after 8 bits; SR read == $55; IFR.SR cleared by read. |
| 6B — M3 DATA=$AA | Same for $AA. |
| 6C — M3 DATA=$A5 | Same for $A5. |
| 6D — M3 DATA=$5A | Same for $5A. |
| **GRP7: SR MODE 5 SR=$55 — shift out under T2 control** | ACR SR = 101. VIA drives CB1 (clock) and CB2 (data). 256 combined CB1/CB2 samples compared against reference files. SR armed with $55. |
| 7A–7D | T2=$0110, $0220, $0330, $0440; files `V.SR.M5G7.55.A`–`.D`. |
| **GRP8: SR MODE 5 SR=$AA — shift out under T2 control** | Identical to Group 7 but SR armed with $AA. |
| 8A–8D | T2=$0110, $0220, $0330, $0440; files `V.SR.M5G8.AA.A`–`.D`. |
| **GRP9: SR MODE 5 CB1 POLL SR=$55** | Mode 5, SR=$55. Instead of sampling into a buffer, reconstructs the shifted-out byte bit by bit by polling CB1 low/high and sampling CB2 via PA7. Verifies IFR.SR is set after 8 bits and result == $55. |
| 9A–9D | T2=$011C, $0220, $0330, $0440. |
| **GRP10: SR MODE 5 CB1 POLL SR=$AA** | Identical to Group 9 but SR armed with $AA; result verified == $AA. |
| 10A–10D | T2=$011C, $0220, $0330, $0440. |
| **GRP11: SR MODE 7 — shift out under external CB1 control** | ACR SR = 111. CB1 is an external clock input driven via PIA1 PA7 loopback. Each falling edge of CB1 causes the VIA to present the next output bit (MSB first) on CB2. CB2 is read back via VIA PA7 (DDRA=$00). After 8 edges IFR.SR is set. The reconstructed byte is compared to the original payload. |
| 11A — M7 DATA=$55 | Shifts $55 out; verifies IFR.SR=0 before each falling CB1 edge; verifies IFR.SR=1 after 8 bits; result == $55. |
| 11B — M7 DATA=$AA | Same for $AA. |
| 11C — M7 DATA=$5A | Same for $5A. |
| 11D — M7 DATA=$A5 | Same for $A5. |
| **GRP12: SR MODE 4 SR=$55 — shift out under free-running T2 control** | ACR SR = 100. VIA drives CB1 (clock) and CB2 (data). 256 combined CB1/CB2 samples compared against reference files. SR armed with $55. |
| 12A–12D | T2=$0110, $0220, $0330, $0440; files `V.SR.M4G12.55.A`–`.D`. |
| **GRP13: SR MODE 4 SR=$AA — shift out under free-running T2 control** | Identical to Group 12 but SR armed with $AA. |
| 13A–13D | T2=$0110, $0220, $0330, $0440; files `V.SR.M4G13.AA.A`–`.D`. |
| **GRP14: SR MODE 4 CB1 POLL SR=$55** | Mode 4, SR=$55. Instead of sampling into a buffer, reconstructs 4 successive shifted-out bytes by polling CB1 low/high and sampling CB2 via PA7. Byte 1 must equal $55, bytes 2-4 must match byte 1, IFR.SR must stay clear after every byte, and a stalled shift reports `FAIL @FF <completed-byte-count>`. |
| 14A–14D | T2=$011C, $0220, $0330, $0440. |
| **GRP15: SR MODE 4 CB1 POLL SR=$AA** | Identical to Group 14 but SR armed with $AA; byte 1 must equal $AA and bytes 2-4 must match it. |
| 15A–15D | T2=$011C, $0220, $0330, $0440. |
