#!/usr/bin/env bash
# Run via_test1 in VICE xpet using pre-generated reference data.
#
# The vice/data/ directory (populated by run_via_test1_gen.sh) is
# mounted as IEEE-488 device 8.  The test program loads the 15
# reference SEQ files from that directory and compares them against
# live VIA measurements.
#
# Requires: VICE xpet binary in PATH
#           Reference data files in vice/data/ (run run_via_test1_gen.sh first)
# Usage: bash vice/run_via_test1.sh [extra VICE options]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PRG="${SCRIPT_DIR}/../build/via_test1.prg"
DATA_DIR="${SCRIPT_DIR}/data"

if [ ! -f "$PRG" ]; then
    echo "ERROR: $PRG not found. Run 'make' first." >&2
    exit 1
fi

if ! command -v xpet >/dev/null 2>&1; then
    echo "ERROR: xpet not found in PATH. Install VICE." >&2
    exit 1
fi

if [ ! -d "$DATA_DIR" ] || [ -z "$(ls -A "$DATA_DIR" 2>/dev/null)" ]; then
    echo "ERROR: Reference data not found in $DATA_DIR" >&2
    echo "       Run 'bash vice/run_via_test1_gen.sh' (or 'make run5') first to generate reference data." >&2
    exit 1
fi

exec xpet -model 4032 \
     -drive8type 1541 \
     -drive8 8 \
     -fsdevice8 "$DATA_DIR" \
     -autostart "$PRG" \
     "$@"
