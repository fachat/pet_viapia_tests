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
PIA1_ORA = $E810    ; PIA1 Port-A / DDR-A (CRA bit2=0->DDR, bit2=1->data)
PIA1_ORB = $E811    ; PIA1 Port-B / DDR-B
PIA1_CRA = $E812    ; PIA1 Control Register A
PIA1_CRB = $E813    ; PIA1 Control Register B

PIA2_ORA = $E820    ; PIA2 Port-A / DDR-A
PIA2_ORB = $E821    ; PIA2 Port-B / DDR-B
PIA2_CRA = $E822    ; PIA2 Control Register A
PIA2_CRB = $E823    ; PIA2 Control Register B

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
DDRPTR   = $06      ; 2-byte pointer to the DDR/data register ($06-$07)
CRPTR    = $08      ; 2-byte pointer to the control register ($08-$09)

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
        sta STRPTR
        lda #>msg_banner
        sta STRPTR+1
        jsr print_str

        ; Test 1 - PIA1 DDR A
        lda #<msg_p1da
        sta STRPTR
        lda #>msg_p1da
        sta STRPTR+1
        jsr print_str

        lda #<PIA1_ORA
        sta DDRPTR
        lda #>PIA1_ORA
        sta DDRPTR+1
        lda #<PIA1_CRA
        sta CRPTR
        lda #>PIA1_CRA
        sta CRPTR+1
        jsr test_ddr
        jsr print_result

        ; Test 2 - PIA1 DDR B
        lda #<msg_p1db
        sta STRPTR
        lda #>msg_p1db
        sta STRPTR+1
        jsr print_str

        lda #<PIA1_ORB
        sta DDRPTR
        lda #>PIA1_ORB
        sta DDRPTR+1
        lda #<PIA1_CRB
        sta CRPTR
        lda #>PIA1_CRB
        sta CRPTR+1
        jsr test_ddr
        jsr print_result

        ; Test 3 - PIA2 DDR A
        lda #<msg_p2da
        sta STRPTR
        lda #>msg_p2da
        sta STRPTR+1
        jsr print_str

        lda #<PIA2_ORA
        sta DDRPTR
        lda #>PIA2_ORA
        sta DDRPTR+1
        lda #<PIA2_CRA
        sta CRPTR
        lda #>PIA2_CRA
        sta CRPTR+1
        jsr test_ddr
        jsr print_result

        ; Test 4 - PIA2 DDR B
        lda #<msg_p2db
        sta STRPTR
        lda #>msg_p2db
        sta STRPTR+1
        jsr print_str

        lda #<PIA2_ORB
        sta DDRPTR
        lda #>PIA2_ORB
        sta DDRPTR+1
        lda #<PIA2_CRB
        sta CRPTR
        lda #>PIA2_CRB
        sta CRPTR+1
        jsr test_ddr
        jsr print_result

        ; Test 5 - PIA1 Control Register A
        lda #<msg_p1ca
        sta STRPTR
        lda #>msg_p1ca
        sta STRPTR+1
        jsr print_str

        lda #<PIA1_CRA
        sta CRPTR
        lda #>PIA1_CRA
        sta CRPTR+1
        jsr test_cr
        jsr print_result

        ; Test 6 - PIA1 Control Register B
        lda #<msg_p1cb
        sta STRPTR
        lda #>msg_p1cb
        sta STRPTR+1
        jsr print_str

        lda #<PIA1_CRB
        sta CRPTR
        lda #>PIA1_CRB
        sta CRPTR+1
        jsr test_cr
        jsr print_result

        ; Test 7 - PIA2 Control Register A
        lda #<msg_p2ca
        sta STRPTR
        lda #>msg_p2ca
        sta STRPTR+1
        jsr print_str

        lda #<PIA2_CRA
        sta CRPTR
        lda #>PIA2_CRA
        sta CRPTR+1
        jsr test_cr
        jsr print_result

        ; Test 8 - PIA2 Control Register B
        lda #<msg_p2cb
        sta STRPTR
        lda #>msg_p2cb
        sta STRPTR+1
        jsr print_str

        lda #<PIA2_CRB
        sta CRPTR
        lda #>PIA2_CRB
        sta CRPTR+1
        jsr test_cr
        jsr print_result

        ; Summary
        lda #<msg_divider
        sta STRPTR
        lda #>msg_divider
        sta STRPTR+1
        jsr print_str

        lda FAIL_CNT
        bne t1_some_fail

        lda #<msg_all_pass
        sta STRPTR
        lda #>msg_all_pass
        sta STRPTR+1
        jsr print_str
        jmp t1_done

t1_some_fail:
        lda #<msg_some_fail
        sta STRPTR
        lda #>msg_some_fail
        sta STRPTR+1
        jsr print_str

t1_done:
        rts                 ; return to BASIC

; ============================================================
; Subroutine: test_ddr
;
; Exercises the DDR register pointed to by DDRPTR through
; four patterns ($FF, $55, $AA, $00).  CR bit 2 is cleared
; to select DDR access, then restored afterwards.
;
; Inputs:  DDRPTR - ZP pointer to the port/DDR register
;          CRPTR  - ZP pointer to the control register
; Returns: A = 0 (pass) or A = 1 (fail)
; ============================================================
test_ddr:
        sei                 ; disable interrupts during access
        ldy #0
        lda (CRPTR),y       ; read current CR
        pha                 ; save original CR
        and #$FB            ; clear bit 2 -> select DDR mode
        sta (CRPTR),y

        lda #$FF
        sta (DDRPTR),y
        lda (DDRPTR),y
        cmp #$FF
        bne td_fail

        lda #$55
        sta (DDRPTR),y
        lda (DDRPTR),y
        cmp #$55
        bne td_fail

        lda #$AA
        sta (DDRPTR),y
        lda (DDRPTR),y
        cmp #$AA
        bne td_fail

        lda #$00
        sta (DDRPTR),y
        lda (DDRPTR),y
        cmp #$00
        bne td_fail

        pla                 ; restore original CR
        ldy #0
        sta (CRPTR),y
        cli
        lda #0              ; pass
        rts

td_fail:
        pla                 ; restore original CR
        ldy #0
        sta (CRPTR),y
        cli
        lda #1              ; fail
        rts

; ============================================================
; Subroutine: test_cr
;
; Verifies that bits 5:0 of the control register are
; writable and readable.  Bits 7:6 are read-only interrupt
; flags and are masked out during comparison.
; The original register value is always restored.
;
; Inputs:  CRPTR - ZP pointer to the control register
; Returns: A = 0 (pass) or A = 1 (fail)
; ============================================================
test_cr:
        sei
        ldy #0
        lda (CRPTR),y       ; read current CR
        pha                 ; save original CR

        ; Write $3F (all six writable bits set), read back
        lda #$3F
        sta (CRPTR),y
        lda (CRPTR),y
        and #$3F            ; mask off read-only interrupt flags
        cmp #$3F
        bne tc_fail

        ; Write $00 (all six writable bits clear), read back
        lda #$00
        sta (CRPTR),y
        lda (CRPTR),y
        and #$3F
        cmp #$00
        bne tc_fail

        pla
        ldy #0
        sta (CRPTR),y       ; restore original CR
        cli
        lda #0              ; pass
        rts

tc_fail:
        pla
        ldy #0
        sta (CRPTR),y       ; restore original CR
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
        sta STRPTR
        lda #>msg_ok
        sta STRPTR+1
        jsr print_str
        rts

pr_fail:
        inc FAIL_CNT
        lda #<msg_fail
        sta STRPTR
        lda #>msg_fail
        sta STRPTR+1
        jsr print_str
        rts

; ============================================================
; Subroutine: print_str
;
; Prints null-terminated string at STRPTR via CHROUT.
; Advances STRPTR through the string one byte at a time.
; ============================================================
print_str:
ps_loop:
        ldy #0
        lda (STRPTR),y      ; fetch character (Y always 0)
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
