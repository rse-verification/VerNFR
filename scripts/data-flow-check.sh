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
echo "Checking rule DFR1 (only static vars in the module)"
frama-c -vernfr -nfr-static-vars -keep-unused-functions "all" "$C_FILE" -nfr-ispec "$ISPEC_FILE"
echo "###########################################"


echo ""
echo "###########################################"
echo "Checking rule DFR4 (Not rely on default zero-init for global vars)"
frama-c -vernfr -nfr-proper-init -keep-unused-functions "all" -nfr-ispec "$ISPEC_FILE" "$C_FILE" 
echo "###########################################"

echo ""
echo "###########################################"
echo "Checking rule DFR5 (No pointer literals)"
frama-c -vernfr -nfr-check-ptr-literals -keep-unused-functions "all" "$C_FILE"
echo "###########################################"

echo ""
echo "###########################################"
echo "Checking rule DFR6 (Using defined types)"
frama-c -vernfr -nfr-typedefs -keep-unused-functions "all" "$C_FILE"
echo "###########################################"

