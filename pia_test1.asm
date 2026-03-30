; ============================================================
; pia_test1.asm
; 6520 PIA Test Module 1 - General functionality
;
; Tests PIA behaviour that does not require specific external
; I/O connections:
;   * DDR (Data Direction Register) read/write on all four
;     PIA ports (PIA1 A/B, PIA2 A/B)
;   * Control Register (CR) lower-bit read/write on all four
;     CRs (PIA1 CRA/CRB, PIA2 CRA/CRB)
;
; Each test saves the original register state, performs the
; check, and restores the original value so the system
; remains operational after the test suite finishes.
; Interrupts are disabled around each register access so the
; PET KERNAL keyboard scan cannot interfere.
;
; Target   : Commodore PET 4032
; Assembler: xa65  (command: xa -XMASM)
; Load     : CBM BASIC LOAD then RUN - or autostart in VICE
; ============================================================

; ============================================================
; Hardware addresses
; ============================================================
PIA1_BASE = $E810   ; PIA1 base address
PIA2_BASE = $E820   ; PIA2 base address

; Register offsets from PIA base address
PIA_ORA = 0         ; Port-A / DDR-A (CRA bit2=0->DDR, bit2=1->data)
PIA_ORB = 1         ; Port-B / DDR-B (CRB bit2=0->DDR, bit2=1->data)
PIA_CRA = 2         ; Control Register A
PIA_CRB = 3         ; Control Register B

; CBM KERNAL output routine
CHROUT   = $FFD2    ; Output character in A to current channel

; ============================================================
; Zero-page temporaries
; ($02-$09 are safe for standalone ML on PET when BASIC is
;  not actively running)
; ============================================================
STRPTR   = $02      ; 2-byte pointer used by print_str ($02-$03)
PASS_CNT = $04      ; running count of passed tests
FAIL_CNT = $05      ; running count of failed tests
PIAPTR   = $06      ; 2-byte pointer to PIA base address ($06-$07)

; ============================================================
; .PRG file header - first two bytes are the CBM load address
; ============================================================
* = $0401 - 2
        .word $0401         ; .prg load address (little-endian)

; ============================================================
; BASIC stub at $0401:  10 SYS 1037
;
; Layout:
;   $0401-$0402  next-line pointer -> $040B
;   $0403-$0404  line number = 10
;   $0405        SYS token ($9E)
;   $0406-$0409  "1037"  (decimal address of machine code)
;   $040A        line terminator ($00)
;   $040B-$040C  end-of-BASIC ($0000)
;   $040D        machine code begins  (= 1037 decimal)
; ============================================================
* = $0401
        .word basic_end     ; pointer to next BASIC line
        .word 10            ; BASIC line number
        .byte $9e           ; SYS token
        .byte "1037"        ; decimal address of code_start
        .byte 0             ; end of BASIC line
basic_end:
        .word 0             ; end of BASIC program

; ============================================================
; Machine code entry point  ($040D = 1037 decimal)
; ============================================================
* = $040D
main:
        ; Initialise pass/fail counters
        lda #0
        sta PASS_CNT
        sta FAIL_CNT

        ; Clear screen
        lda #$93
        jsr CHROUT

        ; Print banner
        lda #<msg_banner
        ldx #>msg_banner
        jsr print_str

        ; Test 1 - PIA1 DDR A
        lda #<msg_p1da
        ldx #>msg_p1da
        jsr print_str

        lda #<PIA1_BASE
        sta PIAPTR
        lda #>PIA1_BASE
        sta PIAPTR+1
        ldy #PIA_ORA        ; DDR-A register offset
        jsr test_ddr
        jsr print_result

        ; Test 2 - PIA1 DDR B
        lda #<msg_p1db
        ldx #>msg_p1db
        jsr print_str

        ; PIAPTR still = PIA1_BASE
        ldy #PIA_ORB        ; DDR-B register offset
        jsr test_ddr
        jsr print_result

        ; Test 3 - PIA2 DDR A
        lda #<msg_p2da
        ldx #>msg_p2da
        jsr print_str

        lda #<PIA2_BASE
        sta PIAPTR
        lda #>PIA2_BASE
        sta PIAPTR+1
        ldy #PIA_ORA        ; DDR-A register offset
        jsr test_ddr
        jsr print_result

        ; Test 4 - PIA2 DDR B
        lda #<msg_p2db
        ldx #>msg_p2db
        jsr print_str

        ; PIAPTR still = PIA2_BASE
        ldy #PIA_ORB        ; DDR-B register offset
        jsr test_ddr
        jsr print_result

        ; Test 5 - PIA1 Control Register A
        lda #<msg_p1ca
        ldx #>msg_p1ca
        jsr print_str

        lda #<PIA1_BASE
        sta PIAPTR
        lda #>PIA1_BASE
        sta PIAPTR+1
        ldy #PIA_CRA        ; CRA register offset
        jsr test_cr
        jsr print_result

        ; Test 6 - PIA1 Control Register B
        lda #<msg_p1cb
        ldx #>msg_p1cb
        jsr print_str

        ; PIAPTR still = PIA1_BASE
        ldy #PIA_CRB        ; CRB register offset
        jsr test_cr
        jsr print_result

        ; Test 7 - PIA2 Control Register A
        lda #<msg_p2ca
        ldx #>msg_p2ca
        jsr print_str

        lda #<PIA2_BASE
        sta PIAPTR
        lda #>PIA2_BASE
        sta PIAPTR+1
        ldy #PIA_CRA        ; CRA register offset
        jsr test_cr
        jsr print_result

        ; Test 8 - PIA2 Control Register B
        lda #<msg_p2cb
        ldx #>msg_p2cb
        jsr print_str

        ; PIAPTR still = PIA2_BASE
        ldy #PIA_CRB        ; CRB register offset
        jsr test_cr
        jsr print_result

        ; Summary
        lda #<msg_divider
        ldx #>msg_divider
        jsr print_str

        lda FAIL_CNT
        bne t1_some_fail

        lda #<msg_all_pass
        ldx #>msg_all_pass
        jsr print_str
        jmp t1_done

t1_some_fail:
        lda #<msg_some_fail
        ldx #>msg_some_fail
        jsr print_str

t1_done:
        rts                 ; return to BASIC

; ============================================================
; Subroutine: test_ddr
;
; Exercises the DDR register for the PIA port identified by
; PIAPTR (base address) and Y (DDR register offset: PIA_ORA=0
; for port A, PIA_ORB=1 for port B).  The CR register is at
; offset Y+2 (PIA_CRA or PIA_CRB).  CR bit 2 is cleared to
; select DDR access, then restored afterwards.
; Four patterns ($FF/$55/$AA/$00) are written and read back.
;
; Inputs:  PIAPTR - ZP pointer to the PIA base address
;          Y      - DDR register offset (PIA_ORA or PIA_ORB)
; Returns: A = 0 (pass) or A = 1 (fail)
; Clobbers: X, Y
; ============================================================
test_ddr:
        sei
        tya                 ; A = DDR register offset
        tax                 ; X = DDR offset (preserved for restore)
        clc
        adc #2              ; A = CR register offset (DDR+2)
        tay                 ; Y = CR offset
        lda (PIAPTR),y      ; read current CR
        pha                 ; save original CR
        and #$FB            ; clear bit 2 -> select DDR mode
        sta (PIAPTR),y      ; write updated CR

        txa                 ; A = DDR offset
        tay                 ; Y = DDR offset

        lda #$FF
        sta (PIAPTR),y
        lda (PIAPTR),y
        cmp #$FF
        bne td_fail

        lda #$55
        sta (PIAPTR),y
        lda (PIAPTR),y
        cmp #$55
        bne td_fail

        lda #$AA
        sta (PIAPTR),y
        lda (PIAPTR),y
        cmp #$AA
        bne td_fail

        lda #$00
        sta (PIAPTR),y
        lda (PIAPTR),y
        cmp #$00
        bne td_fail

        txa                 ; A = DDR offset
        clc
        adc #2              ; A = CR offset
        tay                 ; Y = CR offset
        pla                 ; A = original CR
        sta (PIAPTR),y      ; restore CR
        cli
        lda #0              ; pass
        rts

td_fail:
        txa                 ; A = DDR offset
        clc
        adc #2              ; A = CR offset
        tay                 ; Y = CR offset
        pla                 ; A = original CR
        sta (PIAPTR),y      ; restore CR
        cli
        lda #1              ; fail
        rts

; ============================================================
; Subroutine: test_cr
;
; Verifies that bits 5:0 of the control register at PIAPTR
; base + Y offset are writable and readable.  Bits 7:6 are
; read-only interrupt flags and are masked out during
; comparison.  The original register value is always restored.
;
; Inputs:  PIAPTR - ZP pointer to the PIA base address
;          Y      - CR register offset (PIA_CRA=2 or PIA_CRB=3)
; Returns: A = 0 (pass) or A = 1 (fail)
; Clobbers: Y (unchanged - Y stays at CR offset throughout)
; ============================================================
test_cr:
        sei
        lda (PIAPTR),y      ; read current CR
        pha                 ; save original CR

        ; Write $3F (all six writable bits set), read back
        lda #$3F
        sta (PIAPTR),y
        lda (PIAPTR),y
        and #$3F            ; mask off read-only interrupt flags
        cmp #$3F
        bne tc_fail

        ; Write $00 (all six writable bits clear), read back
        lda #$00
        sta (PIAPTR),y
        lda (PIAPTR),y
        and #$3F
        cmp #$00
        bne tc_fail

        pla
        sta (PIAPTR),y      ; restore original CR
        cli
        lda #0              ; pass
        rts

tc_fail:
        pla
        sta (PIAPTR),y      ; restore original CR
        cli
        lda #1              ; fail
        rts

; ============================================================
; Subroutine: print_result
;
; Prints "OK" or "FAIL" (with CR) and updates counters.
; Input: A = 0 -> pass,  A != 0 -> fail
; ============================================================
print_result:
        cmp #0
        bne pr_fail

        inc PASS_CNT
        lda #<msg_ok
        ldx #>msg_ok
        jsr print_str
        rts

pr_fail:
        inc FAIL_CNT
        lda #<msg_fail
        ldx #>msg_fail
        jsr print_str
        rts

; ============================================================
; Subroutine: print_str
;
; Prints a null-terminated string via CHROUT.
; The string address is passed in A (low byte) and X (high
; byte); the routine stores them into STRPTR itself.
;
; Inputs:  A = low byte of string address
;          X = high byte of string address
; ============================================================
print_str:
        sta STRPTR          ; store low byte of address
        stx STRPTR+1        ; store high byte of address
ps_loop:
        ldy #0
        lda (STRPTR),y      ; fetch character
        beq ps_done
        jsr CHROUT
        inc STRPTR          ; advance pointer (low byte)
        bne ps_loop
        inc STRPTR+1        ; low byte wrapped: carry into high byte
        jmp ps_loop
ps_done:
        rts

; ============================================================
; Message strings  (null-terminated, CBM uppercase charset)
; ============================================================
msg_banner:
        .byte "PIA TEST MODULE 1", $0d
        .byte "----------------", $0d
        .byte 0

msg_p1da:   .byte "PIA1 DDRA: ", 0
msg_p1db:   .byte "PIA1 DDRB: ", 0
msg_p2da:   .byte "PIA2 DDRA: ", 0
msg_p2db:   .byte "PIA2 DDRB: ", 0
msg_p1ca:   .byte "PIA1 CRA:  ", 0
msg_p1cb:   .byte "PIA1 CRB:  ", 0
msg_p2ca:   .byte "PIA2 CRA:  ", 0
msg_p2cb:   .byte "PIA2 CRB:  ", 0

msg_ok:     .byte "OK", $0d, 0
msg_fail:   .byte "FAIL", $0d, 0

msg_divider:   .byte "----------------", $0d, 0
msg_all_pass:  .byte "ALL TESTS PASSED", $0d, 0
msg_some_fail: .byte "SOME TESTS FAILED", $0d, 0
