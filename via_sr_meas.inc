; ============================================================
; via_sr_meas.inc
; SR mode 1 measurement subroutine - shared between
; via_sr_test_gen.a65 and via_sr_test.a65.
;
; Both files include this file at the same fixed address ($0410,
; immediately after the 3-byte JMP at $040D).  Because the
; subroutine assembles to identical bytes at the identical address
; in both programs, branch targets always cross (or stay within)
; the same page boundaries, guaranteeing cycle-accurate timing
; reproducibility between the generator and test runs.
;
; Required symbols (defined in the including .a65 file):
;   VIA_BASE, VIA_SR, VIA_DDRA, VIA_ACR, VIA_PCR
;   VIA_T2CL, VIA_T2CH, VIA_ORA_NH
;   ACR_SR_NMASK, ACR_SR_IT2, ACR_SR_OFF
;   MEAS_BUF
;   SR_T2_LO  (zero-page: T2 initial value, low byte)
;   SR_T2_HI  (zero-page: T2 initial value, high byte)
;
; Note on hardware connections (required while this subroutine runs):
;   Pin L (VIA PA7) <-> Pin M (CB2): loopback; PA7 output drives CB2 high.
;   Pin 5 (PIA1 PA7) -> Pin 6 (CB1): in SR mode 1 the VIA drives CB1 as
;     an output clock.  PIA1 PA7 MUST be configured as an input before
;     calling this subroutine to avoid a bus conflict on the CB1 line.
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
        ; Read SR to arm shifting; VIA drives CB1 as output clock
        lda VIA_BASE+VIA_SR
        ; Sample SR 256 times in a tight loop
        ldx #0
meas_sr_m1_lp:
        lda VIA_BASE+VIA_SR     ; 4 cycles - read SR
        sta MEAS_BUF,x          ; 5 cycles
        inx                     ; 2 cycles
        bne meas_sr_m1_lp       ; 3 cycles (2 on last iteration)
        ; Disable SR
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_OFF
        sta VIA_BASE+VIA_ACR
        cli
        rts
