; ============================================================
; pet_kernal.inc
; PET-compatible KERNAL file I/O helpers
;
; Provides local implementations of SETNAM, SETLFS, PET_SAVE,
; and PET_LOAD for use from machine-language programs on the
; Commodore PET.  The PET KERNAL jump table does not expose
; SETNAM ($FFBD) or SETLFS ($FFBA); and the LOAD/SAVE entries
; ($FFD5/$FFD8) go through BASIC parsing which fails from ML.
; These routines bypass both problems by writing directly to
; the KERNAL zero-page variables and jumping to the inner
; LOAD/SAVE routines at $f356/$f6e3.
;
; Required constants (must be defined before including this file
; or defined here if not already defined by the including file):
;   KERNAL_FNLEN, KERNAL_LFN, KERNAL_SA, KERNAL_DEVNO,
;   KERNAL_FNLO, KERNAL_FNHI, KERNAL_STATUS
; ============================================================

; PET KERNAL zero-page file I/O variables.
; SETLFS and SETNAM are not present in the PET KERNAL jump
; table; the routines below write directly to these zero-page
; locations which the PET KERNAL LOAD/SAVE routines
; ($f356/$f6e3) read for filename / LFN / device / SA params.
KERNAL_FNLEN = $D1          ; filename length
KERNAL_LFN   = $D2          ; logical file number
KERNAL_SA    = $D3          ; secondary address
KERNAL_DEVNO = $D4          ; device number
KERNAL_FNLO  = $DA          ; filename pointer, low byte
KERNAL_FNHI  = $DB          ; filename pointer, high byte
KERNAL_STATUS = $96         ; KERNAL I/O status byte (bit 6 = EOF, other bits = error)

; ============================================================
; Subroutine: SETNAM  (PET-compatible implementation)
;
; The Commodore PET KERNAL does not provide SETNAM at $FFBD
; (that address holds a different routine).  This local
; implementation achieves the same effect by writing the
; filename parameters directly to the KERNAL zero-page
; variables that PET_LOAD and PET_SAVE consult.
;
; Entry: A = filename length
;        X = filename address, low byte
;        Y = filename address, high byte
; ============================================================
SETNAM:
        sta KERNAL_FNLEN        ; filename length
        stx KERNAL_FNLO         ; filename pointer low
        sty KERNAL_FNHI         ; filename pointer high
        rts

; ============================================================
; Subroutine: SETLFS  (PET-compatible implementation)
;
; The Commodore PET KERNAL does not provide SETLFS at $FFBA.
; This local implementation writes the logical-file /
; device / secondary-address parameters directly to the
; KERNAL zero-page variables.
;
; Entry: A = logical file number
;        X = device number
;        Y = secondary address
; ============================================================
SETLFS:
        sta KERNAL_LFN          ; logical file number
        stx KERNAL_DEVNO        ; device number
        sty KERNAL_SA           ; secondary address
        rts

; ============================================================
; Subroutine: PET_SAVE  (PET-compatible implementation)
;
; The PET KERNAL SAVE at $FFD8 goes through BASIC parsing
; which fails when called from ML.  This implementation
; bypasses that by storing the start/end addresses directly
; into the KERNAL zero-page variables and jumping to the
; inner SAVE routine at $f6e3.
;
; SETNAM and SETLFS must be called first to set the filename,
; logical file number, device number, and secondary address.
;
; Entry: A = zero-page address holding 2-byte start address
;            (low byte at ZP[A], high byte at ZP[A+1])
;        X = end address, low byte
;        Y = end address, high byte
; Returns with carry clear on success, carry set on error.
; Error is detected via KERNAL_STATUS ($96): any bit other than
; bit 6 (EOF, $40) indicates an error.
; Clobbers: A, X
; ============================================================
PET_SAVE:
.(
        stx $c9                 ; end address low  -> KERNAL EAP lo
        sty $ca                 ; end address high -> KERNAL EAP hi
        tax                     ; ZP pointer -> X
        lda $00,x               ; start address low  from ZP[A]
        sta $fb                 ; -> KERNAL SSTART lo
        lda $01,x               ; start address high from ZP[A+1]
        sta $fc                 ; -> KERNAL SSTART hi
        jsr $f6e3               ; PET inner SAVE
        lda KERNAL_STATUS       ; check I/O status
        and #$bf                ; mask out bit 6 (EOF, not an error)
        beq ok                  ; zero = no error
        sec                     ; error: set carry
        rts
ok:     clc                     ; success: clear carry
        rts
.)

; ============================================================
; Subroutine: PET_LOAD  (PET-compatible implementation)
;
; The PET KERNAL LOAD at $FFD5 goes through BASIC parsing
; which fails when called from ML.  This implementation
; bypasses that by storing the start address and load/verify
; flag directly into the KERNAL zero-page variables and
; jumping to the inner LOAD routine at $f356.
;
; SETNAM and SETLFS must be called first to set the filename,
; logical file number, device number, and secondary address.
; Use SA=1 in SETLFS to override the load address to X/Y
; (i.e., load to $fb/$fc regardless of the 2-byte file header).
;
; Entry: A = load/verify flag (0 = load, 1 = verify)
;        X = destination address, low byte  (stored in $fb)
;        Y = destination address, high byte (stored in $fc)
; Returns with carry clear on success, carry set on error.
; Error is detected via KERNAL_STATUS ($96): any bit other than
; bit 6 (EOF, $40) indicates an error.
; Clobbers: A, X, Y
; ============================================================
PET_LOAD:
.(
        stx $fb                 ; destination address low  -> KERNAL LOAD ptr lo
        sty $fc                 ; destination address high -> KERNAL LOAD ptr hi
        sta $9d                 ; load/verify flag
        jsr $f356               ; PET inner LOAD
        lda KERNAL_STATUS       ; check I/O status
        and #$bf                ; mask out bit 6 (EOF, not an error)
        beq ok                  ; zero = no error
        sec                     ; error: set carry
        rts
ok:     clc                     ; success: clear carry
        rts
.)
