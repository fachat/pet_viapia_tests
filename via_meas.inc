; ============================================================
; via_meas.inc
; VIA measurement subroutines - shared between via_test1_gen.a65
; and via_test1.a65.
;
; Both files include this file at the same fixed address ($0410,
; immediately after the 3-byte JMP at $040D).  Because the
; subroutines assemble to identical bytes at identical addresses
; in both programs, branch targets always cross (or stay within)
; the same page boundaries, guaranteeing cycle-accurate timing
; reproducibility between the generator and test runs.
;
; Required symbols (defined in the including .a65 file):
;   VIA_BASE, VIA_T1CL, VIA_T1CH, VIA_T1LL, VIA_T1LH
;   VIA_T2CL, VIA_T2CH, VIA_SR, VIA_ACR
;   ACR_SR_NMASK, ACR_SR_OT2, ACR_SR_OFF
;   MEAS_BUF
; ============================================================

; ============================================================
; Subroutine: meas_t1
;
; Loads T1 with a 16-bit value (low byte in A, high byte = $00)
; using the latch registers, starts the timer by writing T1CH,
; then reads T1CL 256 times in a tight loop storing results in
; MEAS_BUF.  ACR must already be configured for the desired
; T1 mode (single-shot or free-run) before calling.
;
; Timing of the tight loop (all iterations identical):
;   LDA abs       4 cycles   read T1CL
;   STA abs,X     5 cycles   store to MEAS_BUF,X
;   INX           2 cycles
;   BNE rel       3 cycles   (2 on last iteration)
;   = 14 cycles per iteration (13 for the last one)
;
; Cycles from T1CH write to first T1CL read: ~6 cycles
; (LDX #0: 2 cycles + first 4 cycles of LDA abs)
;
; Entry: A = latch low byte (latch high byte is always $00)
; Result: MEAS_BUF[0..255] = 256 T1CL readings
; Clobbers: A, X
; ============================================================
meas_t1:
        sei
        sta VIA_BASE+VIA_T1LL   ; write T1 latch low
        lda #$00
        sta VIA_BASE+VIA_T1LH   ; write T1 latch high (clears IFR6)
        sta VIA_BASE+VIA_T1CH   ; write T1CH: loads T1CL <- T1LL, starts timer
        ldx #0
meas_t1_lp:
        lda VIA_BASE+VIA_T1CL   ; 4 cycles - read counter, clears IFR6
        sta MEAS_BUF,x          ; 5 cycles
        inx                     ; 2 cycles
        bne meas_t1_lp          ; 3 cycles (taken) / 2 (not taken on X=0 wrap)
        cli
        rts

; ============================================================
; Subroutine: meas_t1_rst
;
; Tests resetting T1 to a new latch value mid-count.
; Phase 1: loads T1 with latch=$FF, reads T1CL 128 times.
; Reset:   writes new latch=$80 and restarts T1.
; Phase 2: reads T1CL 128 more times (X wraps from 128 to 0).
;
; The 128-iteration loops use CPX to terminate, which adds
; 2 cycles per iteration compared to the plain meas_t1 loop.
; Both phases have identical per-iteration timing (16 cycles)
; so the reference data fully captures the restart effect.
;
; Result: MEAS_BUF[0..127]   = phase-1 readings (latch=$FF)
;         MEAS_BUF[128..255] = phase-2 readings (latch=$80)
; ============================================================
meas_t1_rst:
        sei
        ; phase 1: load T1 latch=$FF, start
        lda #$FF
        sta VIA_BASE+VIA_T1LL
        lda #$00
        sta VIA_BASE+VIA_T1LH
        sta VIA_BASE+VIA_T1CH   ; start T1 with $00FF
        ldx #0
meas_t1_rst_lp1:
        lda VIA_BASE+VIA_T1CL   ; 4 cycles
        sta MEAS_BUF,x          ; 5 cycles
        inx                     ; 2 cycles
        cpx #128                ; 2 cycles
        bne meas_t1_rst_lp1     ; 3 cycles (taken) / 2 (not taken)
        ; reset T1 to new latch=$80 mid-count
        lda #$80
        sta VIA_BASE+VIA_T1LL
        lda #$00
        sta VIA_BASE+VIA_T1LH
        sta VIA_BASE+VIA_T1CH   ; restart T1 with $0080
        ; phase 2: read 128 more times (x=128..255, wraps to 0)
meas_t1_rst_lp2:
        lda VIA_BASE+VIA_T1CL   ; 4 cycles
        sta MEAS_BUF,x          ; 5 cycles
        inx                     ; 2 cycles
        cpx #0                  ; 2 cycles  (will be 0 after 128 more INX from 128)
        bne meas_t1_rst_lp2     ; 3 cycles (taken) / 2 (not taken)
        cli
        rts

; ============================================================
; Subroutine: meas_t2
;
; Loads T2 with a 16-bit value (low byte in A, high byte = $00)
; and reads T2CL 256 times in a tight loop.  ACR bit 5 must
; be 0 (T2 in timer/CPU-clock mode) before calling.
;
; Unlike T1, T2 has no latch-high register; the high byte is
; written directly to the counter via T2CH.  After T2 reaches
; zero, the counter continues decrementing (wraps through
; $FFFF) - this behaviour is captured in the recorded data for
; small latch values.
;
; Timing: identical loop structure to meas_t1 (14 cycles/iter).
;
; Entry: A = latch low byte (high byte always $00)
; Result: MEAS_BUF[0..255] = 256 T2CL readings
; Clobbers: A, X
; ============================================================
meas_t2:
        sei
        sta VIA_BASE+VIA_T2CL   ; write T2 latch low
        lda #$00
        sta VIA_BASE+VIA_T2CH   ; write T2CH: loads T2CL <- latch, starts timer
        ldx #0
meas_t2_lp:
        lda VIA_BASE+VIA_T2CL   ; 4 cycles - read counter, clears IFR5
        sta MEAS_BUF,x          ; 5 cycles
        inx                     ; 2 cycles
        bne meas_t2_lp          ; 3 cycles (taken) / 2 (not taken)
        cli
        rts

; ============================================================
; Subroutine: meas_sr_t2
;
; Configures the SR in shift-out / T2-clock mode (ACR=101),
; loads T2 latch with period=5, writes $AA to SR to start
; shifting, then reads SR 256 times.
;
; In this mode each T2 timeout (every 6 CPU cycles = latch+1)
; shifts one bit out on CB2.  After 8 complete shifts IFR
; bit 2 is set and shifting stops; the SR value at that point
; freezes.  The 256 readings thus capture the shift-out
; sequence followed by the final static value.
;
; Result: MEAS_BUF[0..255] = 256 SR readings
; Clobbers: A, X
; ============================================================
meas_sr_t2:
        sei
        ; configure SR: shift out under T2 (ACR bits 4-2 = 101)
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_OT2
        sta VIA_BASE+VIA_ACR
        ; set T2 latch for SR clock period (latch+1 = 6 cycles)
        lda #$05
        sta VIA_BASE+VIA_T2CL
        ; write data to SR - this starts the shift-out sequence
        lda #$AA
        sta VIA_BASE+VIA_SR
        ; read SR 256 times
        ldx #0
meas_sr_t2_lp:
        lda VIA_BASE+VIA_SR     ; 4 cycles
        sta MEAS_BUF,x          ; 5 cycles
        inx                     ; 2 cycles
        bne meas_sr_t2_lp       ; 3 cycles (taken) / 2 (not taken)
        ; disable SR
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_OFF
        sta VIA_BASE+VIA_ACR
        cli
        rts

; ============================================================
; Subroutine: meas_sr_stop
;
; Tests stopping the SR mid-operation by writing a new value
; while shifting is in progress.
; Phase 1: write $FF to SR (starts shifting), read SR 64 times.
; Restart: write $55 to SR (resets / restarts shifting).
; Phase 2: read SR 192 more times.
;
; Uses T2 latch=10 (11-cycle SR clock period) so that
; multiple shift steps occur within the 64-iteration window.
;
; Result: MEAS_BUF[0..63]    = phase-1 readings (data=$FF)
;         MEAS_BUF[64..255]  = phase-2 readings (data=$55)
; ============================================================
meas_sr_stop:
        sei
        ; configure SR: shift out under T2
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_OT2
        sta VIA_BASE+VIA_ACR
        ; T2 latch = 10 (11-cycle SR clock period)
        lda #$0A
        sta VIA_BASE+VIA_T2CL
        ; write initial value to SR - starts shifting
        lda #$FF
        sta VIA_BASE+VIA_SR
        ; phase 1: 64 reads (X = 0..63)
        ldx #0
meas_sr_stop_lp1:
        lda VIA_BASE+VIA_SR     ; 4 cycles
        sta MEAS_BUF,x          ; 5 cycles
        inx                     ; 2 cycles
        cpx #64                 ; 2 cycles
        bne meas_sr_stop_lp1    ; 3 cycles (taken) / 2 (not taken)
        ; restart SR with new value mid-operation
        lda #$55
        sta VIA_BASE+VIA_SR
        ; phase 2: 192 more reads (X = 64..255, wraps at 0)
meas_sr_stop_lp2:
        lda VIA_BASE+VIA_SR     ; 4 cycles
        sta MEAS_BUF,x          ; 5 cycles
        inx                     ; 2 cycles
        cpx #0                  ; 2 cycles
        bne meas_sr_stop_lp2    ; 3 cycles (taken) / 2 (not taken)
        ; disable SR
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_OFF
        sta VIA_BASE+VIA_ACR
        cli
        rts
