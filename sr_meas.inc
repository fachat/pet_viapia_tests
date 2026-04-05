; ============================================================
; sr_meas.inc
; SR measurement subroutines - shared between
; 08_sr_test_gen.a65 and 08_sr_test.a65.
;
; Both files include this file at the same fixed address ($0410,
; immediately after the 3-byte JMP at $040D).  Because the
; subroutines assemble to identical bytes at the identical address
; in both programs, branch targets always cross (or stay within)
; the same page boundaries, guaranteeing cycle-accurate timing
; reproducibility between the generator and test runs.
;
; Required symbols (defined in the including .a65 file):
;   VIA_BASE, VIA_SR, VIA_DDRA, VIA_ACR, VIA_PCR
;   VIA_T2CL, VIA_T2CH, VIA_ORA_NH
;   PIA1_BASE, PIA_ORA
;   ACR_SR_NMASK, ACR_SR_IT2, ACR_SR_OT2, ACR_SR_OFF
;   MEAS_BUF
;   SR_T2_LO  (zero-page: T2 initial value, low byte)
;   SR_T2_HI  (zero-page: T2 initial value, high byte)
;   SR_INIT   (zero-page: initial value written to SR in meas_sr_mode5 after
;              setting ACR to mode 5, arming the shift-out sequence)
;   SR_IFR_PRE  (zero-page: receives IFR & IFR_SR before arming; expected 0)
;   SR_IFR_POST (zero-page: receives IFR & IFR_SR after sample loop; expected IFR_SR)
;
; Note on hardware connections:
;   meas_sr_mode1 / meas_sr_mode1_noarm:
;     Pin L (VIA PA7) <-> Pin M (CB2): loopback; PA7 output drives CB2 high.
;     Pin 5 (PIA1 PA7) -> Pin 6 (CB1): VIA drives CB1 as output clock;
;       PIA1 PA7 MUST be an input to avoid a bus conflict on CB1.
;   meas_sr_mode5:
;     Pin M (CB2) -> Pin L (VIA PA7): loopback; VIA PA7 = input reads CB2 data.
;     Pin 6 (CB1) -> Pin 5 (PIA1 PA7): loopback; PIA1 PA7 = input reads CB1 clock.
;       Both PIA1 PA7 and VIA PA7 MUST be inputs (PIA1 DDRA PA7=0, VIA DDRA=$00).
; ============================================================

; ============================================================
; Subroutine: meas_sr_mode1
;
; Measures SR behavior in mode 1 (shift in under T2 control).
; The caller sets SR_T2_LO and SR_T2_HI (zero-page) to the
; desired 16-bit initial T2 value before calling.
;
; Setup sequence:
;   1. Disable SR (ACR SR = 000); write 0 to SR.
;   2. Set CB2 to input mode (PCR bits 7:5 = 000).
;   3. Set DDRA = $80 (PA7 = output; rest = input).
;   4. Set PA7 = 1 via ORA_NH; CB2 = high via loopback (data = 1).
;   5. Load T2 with SR_T2_HI:SR_T2_LO and start counting.
;   6. Set SR to mode 1 (ACR SR = 001 = shift in via T2).
;   7. Read SR to arm shifting; VIA drives CB1 as output clock.
;   8. Sample SR 256 times in a tight loop, storing in MEAS_BUF.
;   9. Disable SR (ACR SR = 000).
;
; Timing of the tight loop (all iterations identical):
;   LDA abs       4 cycles   read SR
;   STA abs,X     5 cycles   store to MEAS_BUF,X
;   INX           2 cycles
;   BNE rel       3 cycles   (2 on last iteration)
;   = 14 cycles per iteration (13 for the last one)
;
; NOTE: This subroutine modifies VIA DDRA (sets $80) and VIA PCR
;       (clears CB2 mode bits 7:5 to 000).  It does not restore
;       them; the calling program is responsible for overall state
;       save/restore around the test run.
;
; Result: MEAS_BUF[0..255] = 256 SR readings
; Clobbers: A, X
; ============================================================
meas_sr_mode1:
        sei
        ; Disable SR (mode 0) and clear SR register
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK       ; SR mode = 000 (disabled)
        sta VIA_BASE+VIA_ACR
        lda #0
        sta VIA_BASE+VIA_SR     ; write 0 to SR
        ; Set CB2 as input (PCR bits 7:5 = 000)
        lda VIA_BASE+VIA_PCR
        and #$1F                ; clear CB2 mode bits 7:5
        sta VIA_BASE+VIA_PCR
        ; Set PA7 as output and drive it high (CB2 = high via loopback)
        lda #$80
        sta VIA_BASE+VIA_DDRA   ; PA7 = output, rest = input
        sta VIA_BASE+VIA_ORA_NH ; PA7 = 1 -> CB2 = high via loopback
        ; Load T2 with SR_T2_HI:SR_T2_LO and start counting
        lda SR_T2_LO
        sta VIA_BASE+VIA_T2CL
        lda SR_T2_HI
        sta VIA_BASE+VIA_T2CH   ; load counter, start T2
        ; Set SR to mode 1: shift in under T2 control
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_IT2
        sta VIA_BASE+VIA_ACR
        ; Verify IFR.SR is clear before arming
        lda VIA_BASE+VIA_IFR
        and #IFR_SR
        sta SR_IFR_PRE
        ; Read SR to arm shifting; VIA drives CB1 as output clock
        lda VIA_BASE+VIA_SR
        ; Sample SR 256 times in a tight loop
        ldx #0
meas_sr_m1_lp:
        lda VIA_BASE+VIA_SR     ; 4 cycles - read SR
        sta MEAS_BUF,x          ; 5 cycles
        inx                     ; 2 cycles
        bne meas_sr_m1_lp       ; 3 cycles (2 on last iteration)
        ; Verify IFR.SR is set after sampling
        lda VIA_BASE+VIA_IFR
        and #IFR_SR
        sta SR_IFR_POST
        ; Disable SR
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_OFF
        sta VIA_BASE+VIA_ACR
        cli
        rts

; ============================================================
; Subroutine: meas_sr_mode1_noarm
;
; Identical to meas_sr_mode1 except the "arm" read of SR
; (lda VIA_BASE+VIA_SR immediately after setting ACR to mode 1)
; is omitted.  In this variant the first shift clock does not
; occur until the first T2 underflow, so the timing of the
; first edge relative to mode-enable is different.
;
; See meas_sr_mode1 for full documentation.  The setup and
; sample loop are identical; only the arm read is absent.
;
; Result: MEAS_BUF[0..255] = 256 SR readings
; Clobbers: A, X
; ============================================================
meas_sr_mode1_noarm:
        sei
        ; Disable SR (mode 0) and clear SR register
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK       ; SR mode = 000 (disabled)
        sta VIA_BASE+VIA_ACR
        lda #0
        sta VIA_BASE+VIA_SR     ; write 0 to SR
        ; Set CB2 as input (PCR bits 7:5 = 000)
        lda VIA_BASE+VIA_PCR
        and #$1F                ; clear CB2 mode bits 7:5
        sta VIA_BASE+VIA_PCR
        ; Set PA7 as output and drive it high (CB2 = high via loopback)
        lda #$80
        sta VIA_BASE+VIA_DDRA   ; PA7 = output, rest = input
        sta VIA_BASE+VIA_ORA_NH ; PA7 = 1 -> CB2 = high via loopback
        ; Load T2 with SR_T2_HI:SR_T2_LO and start counting
        lda SR_T2_LO
        sta VIA_BASE+VIA_T2CL
        lda SR_T2_HI
        sta VIA_BASE+VIA_T2CH   ; load counter, start T2
        ; Set SR to mode 1: shift in under T2 control
        ; NOTE: no arm read here - first shift occurs on first T2 underflow
        ; Verify IFR.SR is clear before triggering
        lda VIA_BASE+VIA_IFR
        and #IFR_SR
        sta SR_IFR_PRE
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_IT2
        sta VIA_BASE+VIA_ACR
        ; Sample SR 256 times in a tight loop
        ldx #0
meas_sr_m1n_lp:
        lda VIA_BASE+VIA_SR     ; 4 cycles - read SR
        sta MEAS_BUF,x          ; 5 cycles
        inx                     ; 2 cycles
        bne meas_sr_m1n_lp      ; 3 cycles (2 on last iteration)
        ; Verify IFR.SR is set after sampling
        lda VIA_BASE+VIA_IFR
        and #IFR_SR
        sta SR_IFR_POST
        ; Disable SR
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_OFF
        sta VIA_BASE+VIA_ACR
        cli
        rts

; ============================================================
; Subroutine: meas_sr_mode5
;
; Measures SR mode 5 (shift out under T2 control) behavior.
; The VIA drives CB1 as the output shift clock and shifts the
; SR data out on CB2.  Both lines are read back via loopback:
;   CB1 -> Pin 6 -> Pin 5 -> PIA1 PA7 (input)
;   CB2 -> Pin M -> Pin L -> VIA PA7  (input, DDRA=$00)
;
; The caller sets SR_T2_LO and SR_T2_HI (zero-page) to the
; desired 16-bit initial T2 value before calling.
; PIA1 PA7 MUST already be configured as an input before calling
; (VIA drives CB1 as an output clock; a PIA1 PA7 output would
;  conflict on CB1).
;
; Setup sequence:
;   1. Disable SR (ACR SR = 000); write 0 to SR.
;   2. Set CB2 as input (PCR bits 7:5 = 000).
;   3. Set DDRA = $00 (all PA = input; reads CB2 via PA7 loopback).
;   4. Load T2 with SR_T2_HI:SR_T2_LO and start counting.
;   5. Set SR to mode 5 (ACR SR = 101 = shift out via T2).
;   5a. Write SR_INIT to SR to arm the shift-out sequence.
;   6. Sample CB1 and CB2 256 times in a tight loop.
;   7. Disable SR (ACR SR = 000).
;
; Sampling combines CB1 (clock) and CB2 (data) into one byte:
;   lda PIA1_BASE+PIA_ORA   ; read PIA1 PA7 (CB1 clock via loopback)
;   asl                     ; CB1 bit 7 -> carry flag
;   lda VIA_BASE+VIA_ORA_NH ; read VIA  PA7 (CB2 data via loopback)
;   and #$80                ; keep only bit 7
;   ror                     ; carry -> bit 7; CB2 -> bit 6
;   Result: bit 7 = CB2 data (SR out), bit 6 = CB1 clock
;
; Timing of the tight loop (all iterations identical):
;   LDA abs       4 cycles   read PIA1 ORA (CB1)
;   ASL           2 cycles   CB1 bit7 -> carry
;   LDA abs       4 cycles   read VIA ORA_NH (CB2)
;   AND imm       2 cycles
;   ROR           2 cycles
;   STA abs,X     5 cycles   store to MEAS_BUF,X
;   INX           2 cycles
;   BNE rel       3 cycles   (2 on last iteration)
;   = 24 cycles per iteration (23 for the last one)
;
; NOTE: This subroutine modifies VIA DDRA (sets $00) and VIA PCR
;       (clears CB2 mode bits 7:5 to 000).  It does not restore
;       them; the calling program is responsible for overall state
;       save/restore around the test run.
;
; Result: MEAS_BUF[0..255] = 256 combined CB1/CB2 samples
; Clobbers: A, X
; ============================================================
meas_sr_mode5:
        sei
        ; Disable SR (mode 0) and clear SR register
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK       ; SR mode = 000 (disabled)
        sta VIA_BASE+VIA_ACR
        lda #0
        sta VIA_BASE+VIA_SR     ; write 0 to SR
        ; Set CB2 as input (PCR bits 7:5 = 000)
        lda VIA_BASE+VIA_PCR
        and #$1F                ; clear CB2 mode bits 7:5
        sta VIA_BASE+VIA_PCR
        ; Set all VIA PA as inputs (DDRA = $00)
        lda #0
        sta VIA_BASE+VIA_DDRA
        ; Load T2 with SR_T2_HI:SR_T2_LO and start counting
        lda SR_T2_LO
        sta VIA_BASE+VIA_T2CL
        lda SR_T2_HI
        sta VIA_BASE+VIA_T2CH   ; load counter, start T2
        ; Set SR to mode 5: shift out under T2 control
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_OT2
        sta VIA_BASE+VIA_ACR
        ; Verify IFR.SR is clear before arming the shift-out
        lda VIA_BASE+VIA_IFR
        and #IFR_SR
        sta SR_IFR_PRE
        ; Write SR_INIT to SR to arm the shift-out sequence
        lda SR_INIT
        sta VIA_BASE+VIA_SR
        ; Sample 256 combined CB1/CB2 readings in a tight loop
        ldx #0
meas_sr_m5_lp:
        lda PIA1_BASE+PIA_ORA   ; 4 cycles - read CB1 via PIA1 PA7 loopback
        asl                     ; 2 cycles - CB1 (bit 7) -> carry
        lda VIA_BASE+VIA_ORA_NH ; 4 cycles - read CB2 via VIA PA7 loopback
        and #$80                ; 2 cycles - keep only bit 7 (PA7 = CB2)
        ror                     ; 2 cycles - carry->bit7 (CB1); CB2->bit6
        sta MEAS_BUF,x          ; 5 cycles
        inx                     ; 2 cycles
        bne meas_sr_m5_lp       ; 3 cycles (2 on last iteration)
        ; Verify IFR.SR is set after sampling
        lda VIA_BASE+VIA_IFR
        and #IFR_SR
        sta SR_IFR_POST
        ; Disable SR
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_OFF
        sta VIA_BASE+VIA_ACR
        cli
        rts
