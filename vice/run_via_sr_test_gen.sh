#!/usr/bin/env bash
# Run via_sr_test_gen in VICE xpet to generate SR reference data files.
#
# The D64 disk image is attached as IEEE-488 device 8 via -8.  The PET
# BASIC LOAD command is injected via the keyboard buffer so that the
# disk is mounted as a fully writable drive before the program runs.
# The generator writes the SR reference files back into the same D64 image.
#
# Using -8 + -keybuf (rather than -autostart) avoids VICE creating a
# temporary disk copy, which would discard all generated output files
# on exit and prevent KERNAL write access during the run.
#
# After running this script, run run_via_sr_test.sh (or 'make run6') to
# execute the test against the generated data.
#
# Usage: bash vice/run_via_sr_test_gen.sh <d64_image> [extra VICE options]
# Requires: VICE xpet binary in PATH

D64="${1:?Usage: $0 <d64_image> [extra VICE options]}"
shift

if [ ! -f "$D64" ]; then
    echo "ERROR: $D64 not found. Run 'make' first." >&2
    exit 1
fi

if ! command -v xpet >/dev/null 2>&1; then
    echo "ERROR: xpet not found in PATH. Install VICE." >&2
    exit 1
fi

exec xpet -model 4032 \
     -8 "$D64" \
     -keybuf $'load"via_sr_test_gen",8,1\nrun\n' \
     "$@"
