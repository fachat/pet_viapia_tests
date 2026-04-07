#!/usr/bin/env bash
# Run the test menu launcher in VICE xpet (PET 4032 model).
#
# The combined disk image (containing the menu and all test programs)
# is attached as IEEE-488 device 8.  The menu program is loaded and
# started via the VICE keyboard buffer.
#
# Usage: bash vice/run-menu.sh <d64_image> [extra VICE options]
# Requires: VICE xpet binary in PATH

D64="${1:?Usage: $0 <d64_image> [extra VICE options]}"
shift

if [ ! -f "$D64" ]; then
    echo "ERROR: $D64 not found. Run 'make menu' first." >&2
    exit 1
fi

if ! command -v xpet >/dev/null 2>&1; then
    echo "ERROR: xpet not found in PATH. Install VICE." >&2
    exit 1
fi

exec xpet -model 4032 \
     -8 "$D64" \
     -keybuf $'load"menu",8,1\nrun\n' \
     "$@"
