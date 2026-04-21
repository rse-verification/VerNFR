#!/usr/bin/env bash

# Exit on any error
set -e

# Function to show usage
usage() {
    echo "Usage: $0 --folder <path> --modname <module_name> "
    exit 1
}



# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --modname)
            MODNAME="$2"
            shift 2
            ;;
        --folder)
            FOLDER="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Check that all files are provided
if [ -z "$MODNAME" ] || [ -z "$FOLDER" ]; then
    echo "Error: Missing required parameters."
    usage
fi

H_FILE="$FOLDER/$MODNAME.h"
C_FILE="$FOLDER/$MODNAME.c"
ISPEC_FILE="$FOLDER/$MODNAME.is"

# Verify that files exist
for f in "$C_FILE" "$H_FILE" "$ISPEC_FILE"; do
    if [ ! -f "$f" ]; then
        echo "Error: File not found - $f"
        exit 1
    fi
done


echo ""
echo "###########################################"
echo "Checking rule CFR1 (only callable functions called)"
frama-c -vernfr -nfr-check-calls -keep-unused-functions "all" -nfr-ispec "$ISPEC_FILE"  "$C_FILE"
echo "###########################################"

echo ""
echo "###########################################"
echo "Checking rule CFR3 (no function pointers)"
frama-c -vernfr -nfr-fun-ptrs -keep-unused-functions "all" -nfr-ispec "$ISPEC_FILE" "$C_FILE"
echo "###########################################"

echo ""
echo "###########################################"
echo "Checking rule CFR4 (no function defs in h-file)"
frama-c -vernfr -nfr-no-fun-defs -keep-unused-functions "all" -keep-unused-types -nfr-ispec "$ISPEC_FILE" "$H_FILE"
echo "###########################################"

echo ""
echo "###########################################"
echo "Checking rule CFR5 (only include h-files)"
matches=$(grep -nE '#\s*include\s*["<][^">]+\.c[">]' "$C_FILE" || true)

if [[ -n "$matches" ]]; then
    echo "Warning: Found .c files including other .c files: $matches"
fi
echo "###########################################"

echo ""
echo "###########################################"
echo "Checking rule CFR6 that all entry-points are declared, and CFR11 that the types are correct"
frama-c -vernfr -nfr-all-entries-declared -keep-unused-functions "all" -nfr-ispec "$ISPEC_FILE"  "$H_FILE"
echo "###########################################"

echo ""
echo "###########################################"
echo "Checking rule CFR7 that all entry-points are defined"
frama-c -vernfr -nfr-all-entries-defined -keep-unused-functions "all" -nfr-ispec "$ISPEC_FILE" "$C_FILE"
echo "###########################################"

echo ""
echo "###########################################"
echo "Checking rule CFR8 and CFR9, that non-entry-points are declared as non-static, and are declared in the c-file"
frama-c -vernfr -nfr-only-entries -keep-unused-functions "all" -nfr-ispec "$ISPEC_FILE" "$C_FILE"
echo "###########################################"

