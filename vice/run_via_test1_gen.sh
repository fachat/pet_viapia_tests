#!/usr/bin/env bash
# Run via_test1_gen in VICE xpet to generate reference data files.
#
# The D64 disk image is attached as IEEE-488 device 8 by passing it to
# -autostart.  VICE mounts the image directly (no temporary disk is
# created), so the reference SEQ files written by the generator are
# saved back into the persistent D64 image.
#
# After running this script, run run_via_test1.sh (or 'make run5') to
# execute the test against the generated data.
#
# Usage: bash vice/run_via_test1_gen.sh <d64_image> [extra VICE options]
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
     -autostart "$D64" \
     "$@"
