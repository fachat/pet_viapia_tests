#!/usr/bin/env bash
# Run PET Userport Test 2 in VICE xpet (PET 4032 model)
#
# Requires: VICE xpet binary in PATH
# Usage: bash vice/run-07-userport-t2.sh [extra VICE options]
#
# The userport must have the following connections wired
# (same fixture as 06-userport-t1):
#   Pin C  (PA0)     - Pin D  (PA1)  : PA0/PA1 loopback
#   Pin E  (PA2)     - Pin F  (PA3)  : PA2/PA3 loopback
#   Pin H  (PA4)     - Pin 7  (PB3)  : PA4 / PB3 cross-loopback
#   Pin J  (PA5)     - Pin K  (PA6)  : PA5/PA6 loopback
#   Pin L  (PA7)     - Pin M  (CB2)  : PA7 / CB2 cross-loopback
#   Pin 5 (PIA1 PA7) - Pin 6  (CB1)  : PIA1 PA7 drives CB1
#   Pin B  (CA1)     - Pin 11 (CA2)  : CA2 manual output drives CA1
#
# The program is auto-started and prints test results on the
# PET screen.  Close the VICE window to exit.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PRG="${SCRIPT_DIR}/../build/07-userport-t2"

if [ ! -f "$PRG" ]; then
    echo "ERROR: $PRG not found. Run 'make' first." >&2
    exit 1
fi

if ! command -v xpet >/dev/null 2>&1; then
    echo "ERROR: xpet not found in PATH. Install VICE." >&2
    exit 1
fi

exec xpet -model 4032 -autostart "$PRG" "$@"
