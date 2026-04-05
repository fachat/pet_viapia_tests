; ============================================================
; meas.inc
; VIA measurement subroutines - shared between 05_via_test1_gen.a65
; and 05_via_test1.a65.
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
;   ACR_SR_NMASK, ACR_SR_IT2, ACR_SR_OFF
;   ACR_T2_NMASK
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
; Subroutines: meas_sr_it2_ah / meas_sr_it2_al
;
; Scenario A - SR shift-in via T2, T2 pre-set to $04FF then $0210.
;
; Setup sequence:
;   1. SR disabled, T2 in timed (CPU-clock) mode.
;   2. Set T2 to $04FF (write T2CL=$FF, T2CH=$04).
;   3. Set SR to shift-in-via-T2 mode (ACR bits 4-2 = 001).
;   4. Set T2 to $0210 (write T2CL=$10, T2CH=$02).
;   5. Read SR to arm shifting (CB1 driven as output clock).
;
; NOTE: In SR shift-in modes, the VIA drives CB1 as an output
;       clock.  CB1 must NOT be hard-wired as an input on the
;       board; doing so creates a bus conflict on that line.
;
; meas_sr_it2_ah: samples T2CH (counter high byte) 256 times.
; meas_sr_it2_al: samples T2CL (counter low byte)  256 times.
;
; Result: MEAS_BUF[0..255] = 256 T2CH (or T2CL) readings
; Clobbers: A, X
; ============================================================
meas_sr_it2_ah:
        sei
        ; SR disabled, T2 in timed (CPU-clock) mode
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK       ; clear SR mode bits (SR off)
        and #ACR_T2_NMASK       ; clear T2 mode bit (timer mode)
        sta VIA_BASE+VIA_ACR
        ; Set T2 to $04FF
        lda #$FF
        sta VIA_BASE+VIA_T2CL   ; T2 latch low = $FF
        lda #$04
        sta VIA_BASE+VIA_T2CH   ; load counter $04FF, start T2
        ; Set SR to shift in under T2 (ACR bits 4-2 = 001)
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_IT2
        sta VIA_BASE+VIA_ACR
        ; Set T2 to $0210
        lda #$10
        sta VIA_BASE+VIA_T2CL   ; T2 latch low = $10
        lda #$02
        sta VIA_BASE+VIA_T2CH   ; load counter $0210, start T2
        ; Read SR to arm shifting; CB1 is driven as output clock
        lda VIA_BASE+VIA_SR
        ; Sample T2CH 256 times
        ldx #0
meas_sr_it2_ah_lp:
        lda VIA_BASE+VIA_T2CH   ; 4 cycles
        sta MEAS_BUF,x          ; 5 cycles
        inx                     ; 2 cycles
        bne meas_sr_it2_ah_lp   ; 3 cycles (2 on last)
        ; Disable SR
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_OFF
        sta VIA_BASE+VIA_ACR
        cli
        rts

meas_sr_it2_al:
        sei
        ; SR disabled, T2 in timed (CPU-clock) mode
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        and #ACR_T2_NMASK
        sta VIA_BASE+VIA_ACR
        ; Set T2 to $04FF
        lda #$FF
        sta VIA_BASE+VIA_T2CL
        lda #$04
        sta VIA_BASE+VIA_T2CH
        ; Set SR to shift in under T2
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_IT2
        sta VIA_BASE+VIA_ACR
        ; Set T2 to $0210
        lda #$10
        sta VIA_BASE+VIA_T2CL
        lda #$02
        sta VIA_BASE+VIA_T2CH
        ; Read SR to arm shifting
        lda VIA_BASE+VIA_SR
        ; Sample T2CL 256 times (clears IFR5 on each read)
        ldx #0
meas_sr_it2_al_lp:
        lda VIA_BASE+VIA_T2CL   ; 4 cycles - read counter, clears IFR5
        sta MEAS_BUF,x          ; 5 cycles
        inx                     ; 2 cycles
        bne meas_sr_it2_al_lp   ; 3 cycles (2 on last)
        ; Disable SR
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_OFF
        sta VIA_BASE+VIA_ACR
        cli
        rts

; ============================================================
; Subroutines: meas_sr_it2_bh / meas_sr_it2_bl
;
; Scenario B - SR shift-in via T2, T2 set directly to $0210.
;
; Setup sequence:
;   1. SR disabled, T2 in timed (CPU-clock) mode.
;   2. Set T2 to $0210 (write T2CL=$10, T2CH=$02).
;   3. Set SR to shift-in-via-T2 mode (ACR bits 4-2 = 001).
;   4. Read SR to arm shifting.
;
; meas_sr_it2_bh: samples T2CH (counter high byte) 256 times.
; meas_sr_it2_bl: samples T2CL (counter low byte)  256 times.
;
; Result: MEAS_BUF[0..255] = 256 T2CH (or T2CL) readings
; Clobbers: A, X
; ============================================================
meas_sr_it2_bh:
        sei
        ; SR disabled, T2 in timed (CPU-clock) mode
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        and #ACR_T2_NMASK
        sta VIA_BASE+VIA_ACR
        ; Set T2 to $0210
        lda #$10
        sta VIA_BASE+VIA_T2CL
        lda #$02
        sta VIA_BASE+VIA_T2CH   ; load counter $0210, start T2
        ; Set SR to shift in under T2
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_IT2
        sta VIA_BASE+VIA_ACR
        ; Read SR to arm shifting
        lda VIA_BASE+VIA_SR
        ; Sample T2CH 256 times
        ldx #0
meas_sr_it2_bh_lp:
        lda VIA_BASE+VIA_T2CH   ; 4 cycles
        sta MEAS_BUF,x          ; 5 cycles
        inx                     ; 2 cycles
        bne meas_sr_it2_bh_lp   ; 3 cycles (2 on last)
        ; Disable SR
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_OFF
        sta VIA_BASE+VIA_ACR
        cli
        rts

meas_sr_it2_bl:
        sei
        ; SR disabled, T2 in timed (CPU-clock) mode
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        and #ACR_T2_NMASK
        sta VIA_BASE+VIA_ACR
        ; Set T2 to $0210
        lda #$10
        sta VIA_BASE+VIA_T2CL
        lda #$02
        sta VIA_BASE+VIA_T2CH
        ; Set SR to shift in under T2
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_IT2
        sta VIA_BASE+VIA_ACR
        ; Read SR to arm shifting
        lda VIA_BASE+VIA_SR
        ; Sample T2CL 256 times (clears IFR5 on each read)
        ldx #0
meas_sr_it2_bl_lp:
        lda VIA_BASE+VIA_T2CL   ; 4 cycles - read counter, clears IFR5
        sta MEAS_BUF,x          ; 5 cycles
        inx                     ; 2 cycles
        bne meas_sr_it2_bl_lp   ; 3 cycles (2 on last)
        ; Disable SR
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_OFF
        sta VIA_BASE+VIA_ACR
        cli
        rts

; ============================================================
; Subroutines: meas_sr_it2_ch / meas_sr_it2_cl
;
; Scenario C - SR shift-in via T2, T2=$0210, 16-cycle wait,
;              then update T2 latch low byte only to $20.
;
; Setup sequence:
;   1. SR disabled, T2 in timed (CPU-clock) mode.
;   2. Set T2 to $0210 (write T2CL=$10, T2CH=$02).
;   3. Wait 16 cycles (8 NOPs) for the T2 low byte to reach $00
;      (the first low-byte underflow: $10 decrements to $00).
;   4. Write T2CL=$20 only (latch low byte; no counter reload).
;   5. Set SR to shift-in-via-T2 mode (ACR bits 4-2 = 001).
;   6. Read SR to arm shifting.
;
; meas_sr_it2_ch: samples T2CH (counter high byte) 256 times.
; meas_sr_it2_cl: samples T2CL (counter low byte)  256 times.
;
; Result: MEAS_BUF[0..255] = 256 T2CH (or T2CL) readings
; Clobbers: A, X
; ============================================================
meas_sr_it2_ch:
        sei
        ; SR disabled, T2 in timed (CPU-clock) mode
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        and #ACR_T2_NMASK
        sta VIA_BASE+VIA_ACR
        ; Set T2 to $0210
        lda #$10
        sta VIA_BASE+VIA_T2CL
        lda #$02
        sta VIA_BASE+VIA_T2CH   ; start T2 at $0210
        ; Wait 16 cycles (8 NOPs x 2 cycles each) for low byte
        ; to count down from $10 to $00 (first low-byte underflow)
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        ; Update T2 latch low byte to $20 only (counter not reloaded)
        lda #$20
        sta VIA_BASE+VIA_T2CL
        ; Set SR to shift in under T2
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_IT2
        sta VIA_BASE+VIA_ACR
        ; Read SR to arm shifting
        lda VIA_BASE+VIA_SR
        ; Sample T2CH 256 times
        ldx #0
meas_sr_it2_ch_lp:
        lda VIA_BASE+VIA_T2CH   ; 4 cycles
        sta MEAS_BUF,x          ; 5 cycles
        inx                     ; 2 cycles
        bne meas_sr_it2_ch_lp   ; 3 cycles (2 on last)
        ; Disable SR
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_OFF
        sta VIA_BASE+VIA_ACR
        cli
        rts

meas_sr_it2_cl:
        sei
        ; SR disabled, T2 in timed (CPU-clock) mode
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        and #ACR_T2_NMASK
        sta VIA_BASE+VIA_ACR
        ; Set T2 to $0210
        lda #$10
        sta VIA_BASE+VIA_T2CL
        lda #$02
        sta VIA_BASE+VIA_T2CH   ; start T2 at $0210
        ; Wait 16 cycles (8 NOPs x 2 cycles each) for low byte
        ; to count down from $10 to $00 (first low-byte underflow)
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        ; Update T2 latch low byte to $20 only (counter not reloaded)
        lda #$20
        sta VIA_BASE+VIA_T2CL
        ; Set SR to shift in under T2
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_IT2
        sta VIA_BASE+VIA_ACR
        ; Read SR to arm shifting
        lda VIA_BASE+VIA_SR
        ; Sample T2CL 256 times (clears IFR5 on each read)
        ldx #0
meas_sr_it2_cl_lp:
        lda VIA_BASE+VIA_T2CL   ; 4 cycles - read counter, clears IFR5
        sta MEAS_BUF,x          ; 5 cycles
        inx                     ; 2 cycles
        bne meas_sr_it2_cl_lp   ; 3 cycles (2 on last)
        ; Disable SR
        lda VIA_BASE+VIA_ACR
        and #ACR_SR_NMASK
        ora #ACR_SR_OFF
        sta VIA_BASE+VIA_ACR
        cli
        rts
