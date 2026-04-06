#!/usr/bin/env bash
# Run via_test1 in VICE xpet using pre-generated reference data.
#
# The D64 disk image (populated with reference data by run_04_via_test1_gen.sh)
# is attached as IEEE-488 device 8.  The test program loads the reference
# SEQ files from that image and compares them against live VIA measurements.
#
# Requires: VICE xpet binary in PATH
#           Reference data in the D64 image (run run_04_via_test1_gen.sh first)
# Usage: bash vice/run_04_via_test1.sh <d64_image> [extra VICE options]

D64="${1:?Usage: $0 <d64_image> [extra VICE options]}"
shift

if [ ! -f "$D64" ]; then
    echo "ERROR: $D64 not found. Run 'make gen4' first." >&2
    exit 1
fi

if ! command -v xpet >/dev/null 2>&1; then
    echo "ERROR: xpet not found in PATH. Install VICE." >&2
    exit 1
fi

exec xpet -model 4032 \
     -8 "$D64" \
     -keybuf $'load"04_via_test1",8,1\nrun\n' \
     "$@"
