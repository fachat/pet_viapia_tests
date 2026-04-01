#!/usr/bin/env bash
# Run via_test1_gen in VICE xpet to generate reference data files.
#
# This script mounts the vice/data/ directory as IEEE-488 device 8
# using VICE's filesystem device emulation.  The generator program
# writes the 15 reference SEQ files into that directory.
#
# After running this script, run_via_test1.sh to execute the test.
#
# Requires: VICE xpet binary in PATH
# Usage: bash vice/run_via_test1_gen.sh [extra VICE options]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PRG="${SCRIPT_DIR}/../build/via_test1_gen.prg"
DATA_DIR="${SCRIPT_DIR}/data"

if [ ! -f "$PRG" ]; then
    echo "ERROR: $PRG not found. Run 'make' first." >&2
    exit 1
fi

if ! command -v xpet >/dev/null 2>&1; then
    echo "ERROR: xpet not found in PATH. Install VICE." >&2
    exit 1
fi

mkdir -p "$DATA_DIR"

exec xpet -model 4032 \
     -drive8type 1541 \
     -drive8 8 \
     -fsdevice8 "$DATA_DIR" \
     -autostart "$PRG" \
     "$@"
