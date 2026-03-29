; ============================================================
; pia_test2.asm
; 6520 PIA Test Module 2 - PET-specific I/O tests
;
; Tests PIA behaviour using the I/O connections of the two
; 6520 PIAs present in the Commodore PET 4032:
;
;   PIA 1 ($E810-$E813) - Keyboard matrix interface
;     Test 1: DDR-A = $FF  (row drivers are outputs)
;     Test 2: DDR-B = $00  (column sense lines are inputs)
;     Test 3: Keyboard scan - deassert all rows, Port-B
;             must read $FF when no key is pressed
;
;   PIA 2 ($E820-$E823) - IEEE-488 bus interface
;     Test 4: DDR-A is read/writable (data direction register)
;     Test 5: IEEE-488 handshake lines idle - nNRFD and nNDAC
;             inputs must read high when no device is attached
;
; Each test saves the affected register state before the
; check and restores it afterwards.  Interrupts are disabled
; around register accesses to prevent KERNAL interference.
;
; Target  : Commodore PET 4032
; Assembler: xa65  (command: xa)
; Load    : CBM BASIC LOAD then RUN  - or autostart in VICE
; ============================================================

; ============================================================
; Hardware addresses
; ============================================================
PIA1_ORA = $E810    ; PIA1 Port-A / DDR-A
PIA1_ORB = $E811    ; PIA1 Port-B / DDR-B
PIA1_CRA = $E812    ; PIA1 Control Register A
PIA1_CRB = $E813    ; PIA1 Control Register B

PIA2_ORA = $E820    ; PIA2 Port-A / DDR-A  (IEEE-488 data bus)
PIA2_ORB = $E821    ; PIA2 Port-B / DDR-B  (IEEE-488 control)
PIA2_CRA = $E822    ; PIA2 Control Register A
PIA2_CRB = $E823    ; PIA2 Control Register B

; PIA2 Port-B (IEEE-488 control lines) bit masks
; bit 0: nDAV  - output (Data Valid, active-low)
; bit 1: nNRFD - input  (Not Ready For Data, pulled high when idle)
; bit 2: nNDAC - input  (Not Data Accepted, pulled high when idle)
; bit 3: nATN  - output (Attention, active-low)
; bit 4: nEOI  - bidirectional
; bit 5: nSRQ  - input  (Service Request, pulled high when idle)
IEEE_NRFD_MASK  = $02
IEEE_NDAC_MASK  = $04
IEEE_NRFD_NDAC  = (IEEE_NRFD_MASK | IEEE_NDAC_MASK)

; CBM KERNAL
CHROUT   = $FFD2    ; Output character in A

; ============================================================
; Zero-page temporaries (same layout as pia_test1)
; ============================================================
STRPTR   = $02      ; 2-byte string pointer for print_str ($02-$03)
PASS_CNT = $04      ; running pass count
FAIL_CNT = $05      ; running fail count
DDRPTR   = $06      ; 2-byte pointer to DDR register ($06-$07)
CRPTR    = $08      ; 2-byte pointer to CR register  ($08-$09)

; ============================================================
; .PRG load address header
; ============================================================
* = $0401 - 2
        .word $0401         ; .prg load address (little-endian)

; ============================================================
; BASIC stub:  10 SYS 1037
; (identical header size to Module 1 - machine code at $040D)
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

        ; --------------------------------------------------------
        ; Test 1 - PIA1 DDR-A should equal $FF
        ;
        ; The PET KERNAL configures Port-A as all outputs so it
        ; can drive the keyboard row select lines.  Read DDR-A
        ; and verify it equals $FF.
        ; --------------------------------------------------------
        lda #<msg_t1
        sta STRPTR
        lda #>msg_t1
        sta STRPTR+1
        jsr print_str

        sei
        lda PIA1_CRA        ; save CRA
        pha
        and #$FB            ; clear bit 2 -> select DDR access
        sta PIA1_CRA
        lda PIA1_ORA        ; read DDR-A into A
        tax                 ; stash in X
        pla                 ; restore original CRA
        sta PIA1_CRA
        cli
        txa                 ; DDR-A value back in A
        cmp #$FF
        beq t1_pass
        lda #1
        jmp t1_result
t1_pass:
        lda #0
t1_result:
        jsr print_result

        ; --------------------------------------------------------
        ; Test 2 - PIA1 DDR-B should equal $00
        ;
        ; The KERNAL configures Port-B as all inputs to read the
        ; keyboard column sense lines.
        ; --------------------------------------------------------
        lda #<msg_t2
        sta STRPTR
        lda #>msg_t2
        sta STRPTR+1
        jsr print_str

        sei
        lda PIA1_CRB        ; save CRB
        pha
        and #$FB            ; clear bit 2 -> select DDR access
        sta PIA1_CRB
        lda PIA1_ORB        ; read DDR-B into A
        tax                 ; stash in X
        pla                 ; restore original CRB
        sta PIA1_CRB
        cli
        txa                 ; DDR-B value back in A
        cmp #$00
        beq t2_pass
        lda #1
        jmp t2_result
t2_pass:
        lda #0
t2_result:
        jsr print_result

        ; --------------------------------------------------------
        ; Test 3 - Keyboard scan: no key pressed -> Port-B = $FF
        ;
        ; Deassert all keyboard rows (set Port-A = $FF) then read
        ; the column sense lines.  With no key pressed every
        ; column line is pulled high, so Port-B must read $FF.
        ; --------------------------------------------------------
        lda #<msg_t3
        sta STRPTR
        lda #>msg_t3
        sta STRPTR+1
        jsr print_str

        sei
        ; Save CRA, then enable data-register access (bit 2 = 1)
        lda PIA1_CRA
        pha                 ; stack: CRA
        ora #$04
        sta PIA1_CRA
        ; Save CRB, then enable data-register access
        lda PIA1_CRB
        pha                 ; stack: CRB, CRA
        ora #$04
        sta PIA1_CRB
        ; Save current Port-A output latch, then deassert all rows
        lda PIA1_ORA
        pha                 ; stack: Port-A, CRB, CRA
        lda #$FF
        sta PIA1_ORA        ; all rows deasserted (high = not selected)
        ; Read keyboard columns
        lda PIA1_ORB        ; column state -> A
        tax                 ; stash in X (free from stack manipulation)
        ; Restore Port-A, CRB, CRA in reverse push order
        pla                 ; A = orig Port-A
        sta PIA1_ORA
        pla                 ; A = orig CRB
        sta PIA1_CRB
        pla                 ; A = orig CRA
        sta PIA1_CRA
        cli
        txa                 ; column state back in A
        cmp #$FF
        beq t3_pass
        lda #1
        jmp t3_result
t3_pass:
        lda #0
t3_result:
        jsr print_result

        ; --------------------------------------------------------
        ; Test 4 - PIA2 DDR-A read/write (IEEE-488 data direction)
        ;
        ; Exercises the DDR via the shared test_ddr subroutine.
        ; --------------------------------------------------------
        lda #<msg_t4
        sta STRPTR
        lda #>msg_t4
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

        ; --------------------------------------------------------
        ; Test 5 - IEEE-488 handshake lines idle check
        ;
        ; With no IEEE-488 device connected the nNRFD and nNDAC
        ; inputs are pulled high by the bus termination.  Read
        ; PIA2 Port-B in data-register mode and verify both bits
        ; are 1 (i.e. the bus is in its idle/released state).
        ; --------------------------------------------------------
        lda #<msg_t5
        sta STRPTR
        lda #>msg_t5
        sta STRPTR+1
        jsr print_str

        sei
        lda PIA2_CRB        ; save CRB
        pha
        ora #$04            ; select Port-B data register
        sta PIA2_CRB
        lda PIA2_ORB        ; read IEEE-488 control lines
        tax                 ; stash in X
        pla                 ; restore original CRB
        sta PIA2_CRB
        cli
        txa                 ; control-line state back in A
        and #IEEE_NRFD_NDAC ; test nNRFD and nNDAC bits
        cmp #IEEE_NRFD_NDAC
        beq t5_pass
        lda #1
        jmp t5_result
t5_pass:
        lda #0
t5_result:
        jsr print_result

        ; --------------------------------------------------------
        ; Summary
        ; --------------------------------------------------------
        lda #<msg_divider
        sta STRPTR
        lda #>msg_divider
        sta STRPTR+1
        jsr print_str

        lda FAIL_CNT
        bne m2_some_fail

        lda #<msg_all_pass
        sta STRPTR
        lda #>msg_all_pass
        sta STRPTR+1
        jsr print_str
        jmp m2_done

m2_some_fail:
        lda #<msg_some_fail
        sta STRPTR
        lda #>msg_some_fail
        sta STRPTR+1
        jsr print_str

m2_done:
        rts                 ; return to BASIC

; ============================================================
; Subroutine: test_ddr
;
; Same implementation as Module 1.  Tests the DDR register
; pointed to by DDRPTR with patterns $FF/$55/$AA/$00 after
; clearing CR bit 2 to select DDR access.  Original CR is
; always restored.
;
; Inputs  : DDRPTR - ZP pointer to the port/DDR register
;           CRPTR  - ZP pointer to the control register
; Returns : A = 0  pass
;           A = 1  fail
; ============================================================
test_ddr:
        sei
        ldy #0
        lda (CRPTR),y
        pha
        and #$FB
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

        pla
        ldy #0
        sta (CRPTR),y
        cli
        lda #0
        rts

td_fail:
        pla
        ldy #0
        sta (CRPTR),y
        cli
        lda #1
        rts

; ============================================================
; Subroutine: print_result
;
; Prints "OK" or "FAIL" (with CR) and updates counters.
; Input : A = 0 -> pass,  A != 0 -> fail
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
; Messages (null-terminated, CBM uppercase charset)
; ============================================================
msg_banner:
        .byte "PIA TEST MODULE 2", $0d
        .byte "PET-SPECIFIC I/O", $0d
        .byte "----------------", $0d
        .byte 0

msg_t1: .byte "PIA1 DDRA=$FF:  ", 0
msg_t2: .byte "PIA1 DDRB=$00:  ", 0
msg_t3: .byte "KBD SCAN IDLE:  ", 0
msg_t4: .byte "PIA2 DDRA R/W:  ", 0
msg_t5: .byte "IEEE IDLE LINES:", 0

msg_ok:         .byte "OK", $0d, 0
msg_fail:       .byte "FAIL", $0d, 0
msg_divider:    .byte "----------------", $0d, 0
msg_all_pass:   .byte "ALL TESTS PASSED", $0d, 0
msg_some_fail:  .byte "SOME TESTS FAILED", $0d, 0
