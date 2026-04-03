#!/usr/bin/env bash
# Run PET Userport Test 1 in VICE xpet (PET 4032 model)
#
# Requires: VICE xpet binary in PATH
# Usage: bash vice/run_pet_userport_test1.sh [extra VICE options]
#
# The userport must have the following connections wired:
#   Pins C-D  = VIA PA0 - PA1
#   Pins E-F  = VIA PA2 - PA3
#   Pins H-J  = VIA PA4 - PA5
#   Pins K-L  = VIA PA6 - PA7
#   Pins 6-7  = VIA CB1 - VIA PB3
#   Pins M-5  = VIA CB2 - PIA1 PA7 (DIAG)
#   Pins 11-B = VIA CA2 - VIA CA1
#
# The program is auto-started and prints test results on the
# PET screen.  Close the VICE window to exit.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PRG="${SCRIPT_DIR}/../build/pet_userport_test1.prg"

if [ ! -f "$PRG" ]; then
    echo "ERROR: $PRG not found. Run 'make' first." >&2
    exit 1
fi

if ! command -v xpet >/dev/null 2>&1; then
    echo "ERROR: xpet not found in PATH. Install VICE." >&2
    exit 1
fi

exec xpet -model 4032 -autostart "$PRG" "$@"
