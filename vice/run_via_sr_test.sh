#!/usr/bin/env bash
# Run via_sr_test in VICE xpet using pre-generated SR reference data.
#
# The D64 disk image (populated with reference data by run_via_sr_test_gen.sh)
# is attached as IEEE-488 device 8.  The test program loads the reference
# files from that image and compares them against live VIA measurements.
#
# Requires: VICE xpet binary in PATH
#           Reference data in the D64 image (run run_via_sr_test_gen.sh first)
# Usage: bash vice/run_via_sr_test.sh <d64_image> [extra VICE options]

D64="${1:?Usage: $0 <d64_image> [extra VICE options]}"
shift

if [ ! -f "$D64" ]; then
    echo "ERROR: $D64 not found. Run 'make gen6' first." >&2
    exit 1
fi

if ! command -v xpet >/dev/null 2>&1; then
    echo "ERROR: xpet not found in PATH. Install VICE." >&2
    exit 1
fi

exec xpet -model 4032 \
     -8 "$D64" \
     -keybuf $'load"via_sr_test",8,1\nrun\n' \
     "$@"
