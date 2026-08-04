; ============================================================
; hw.inc
; Hardware register definitions shared by all test programs
;
; Defines:
;   - IOBASE and base addresses for PIA1, PIA2, VIA
;   - PIA (6520) register offsets
;   - VIA (6522) register offsets
;   - VIA ACR field masks and mode constants
;   - VIA IFR / IER bit masks
;   - VIA PCR CB2 mode constants
;   - CBM KERNAL entry points
;   - Zero-page variables common to all test programs
;
; Target   : Commodore PET 4032
; Assembler: xa65
; ============================================================

; ============================================================
; I/O base address
; ============================================================
#ifndef IOBASE
#define IOBASE $e800
#endif

; ============================================================
; Chip base addresses
; ============================================================
PIA1_BASE = IOBASE + $10    ; PIA1 base address (keyboard + IEEE EOI)
PIA2_BASE = IOBASE + $20    ; PIA2 base address (IEEE-488 data bus)
VIA_BASE  = IOBASE + $40    ; VIA (6522) base address

; ============================================================
; PIA (6520) register offsets from PIA base address
; (CRA/CRB bit 2 selects DDR mode (0) or data register (1))
; ============================================================
PIA_ORA = 0         ; Port A / DDR-A
PIA_CRA = 1         ; Control Register A
PIA_ORB = 2         ; Port B / DDR-B
PIA_CRB = 3         ; Control Register B

; ============================================================
; VIA (6522) register offsets from VIA_BASE
; ============================================================
VIA_ORB   = $00     ; Port B data register
VIA_ORA   = $01     ; Port A data (read: clears CA1/CA2 IFR bits)
VIA_DDRB  = $02     ; Port B data direction register (1=output)
VIA_DDRA  = $03     ; Port A data direction register (1=output)
VIA_T1CL  = $04     ; T1 counter low  (read: clears IFR bit 6)
VIA_T1CH  = $05     ; T1 counter high (write: loads T1CL from T1LL, starts)
VIA_T1LL  = $06     ; T1 latch low    (read/write: latch only)
VIA_T1LH  = $07     ; T1 latch high   (write: clears IFR bit 6; read: latch)
VIA_T2CL  = $08     ; T2 counter low  (write: latch; read: counter, clears IFR bit 5)
VIA_T2CH  = $09     ; T2 counter high (write: loads T2CL from latch, starts)
VIA_SR    = $0A     ; Shift register
VIA_ACR   = $0B     ; Auxiliary control register
VIA_PCR   = $0C     ; Peripheral control register
VIA_IFR   = $0D     ; Interrupt flag register
VIA_IER   = $0E     ; Interrupt enable register
VIA_ORA_NH = $0F    ; Port A data, no handshake (no IFR side-effect)

; ============================================================
; VIA ACR T1 mode (bits 7:6)
; ============================================================
ACR_T1_MASK  = $C0  ; mask for T1 mode bits
ACR_T1_NMASK = $3F  ; inverse: clears T1 mode field
ACR_T1_SS    = $00  ; 00 -> single-shot, no PB7
ACR_T1_FR    = $80  ; 10 -> free-run,    no PB7

; ============================================================
; VIA ACR T2 mode (bit 5)
; ============================================================
ACR_T2_MASK  = $20  ; mask for T2 mode bit
ACR_T2_NMASK = $DF  ; inverse: clears T2 mode bit

; ============================================================
; VIA ACR SR (shift-register) mode (bits 4:2)
;   000=off  001=in/T2  010=in/phi2  011=in/CB1
;   100=out/T2-free  101=out/T2  110=out/phi2  111=out/CB1
; ============================================================
ACR_SR_MASK  = $1C  ; mask for SR mode bits
ACR_SR_NMASK = $E3  ; inverse: clears SR mode bits
ACR_SR_OFF   = $00  ; 000 -> SR disabled
ACR_SR_IT2   = $04  ; 001 -> shift in under T2 control
ACR_SR_IE1   = $0C  ; 011 -> shift in under external CB1 control
ACR_SR_OT2   = $14  ; 101 -> shift out under T2 control
ACR_SR_OCB1  = $1C  ; 111 -> shift out under external CB1 control

; ============================================================
; VIA IFR / IER bit masks
; ============================================================
IFR_T1 = $40        ; bit 6 = T1 timeout
IFR_T2 = $20        ; bit 5 = T2 timeout
IFR_SR = $04        ; bit 2 = SR complete

; ============================================================
; VIA PCR CB2 mode constants (bits 7:5)
; ============================================================
PCR_CB2_HI    = $E0 ; CB2 manual output high (bits 7:5 = 111)
PCR_CB2_LO    = $C0 ; CB2 manual output low  (bits 7:5 = 110)
PCR_CB2_NMASK = $1F ; inverse: clears CB2 mode bits 7:5

; ============================================================
; CBM KERNAL entry points
; ============================================================
CHROUT = $FFD2      ; Output character in A to current channel
GETIN  = $FFE4      ; Read character from current channel into A

; ============================================================
; Zero-page variables common to all test programs
; ($02-$05 are safe for standalone ML on PET)
; ============================================================
STRPTR   = $02      ; 2-byte string pointer for print_str ($02-$03)
PASS_CNT = $04      ; running count of passed tests
FAIL_CNT = $05      ; running count of failed tests
