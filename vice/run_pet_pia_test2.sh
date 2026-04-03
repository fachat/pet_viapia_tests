#!/usr/bin/env bash
# Run PET PIA Test 2 in VICE xpet (PET 4032 model)
#
# Requires: VICE xpet binary in PATH
# Usage: bash vice/run_pet_pia_test2.sh [extra VICE options]
#
# The program is auto-started and prints test results on the
# PET screen.  Close the VICE window to exit.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PRG="${SCRIPT_DIR}/../build/pet_pia_test2"

if [ ! -f "$PRG" ]; then
    echo "ERROR: $PRG not found. Run 'make' first." >&2
    exit 1
fi

if ! command -v xpet >/dev/null 2>&1; then
    echo "ERROR: xpet not found in PATH. Install VICE." >&2
    exit 1
fi

exec xpet -model 4032 -autostart "$PRG" "$@"
