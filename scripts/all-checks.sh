#!/usr/bin/env bash

# Exit on any error
set -e

# Function to show usage
usage() {
    echo "Usage: $0 --folder <path> --modname <module_name> --main <main_function_name>"
    exit 1
}

MAIN="main"

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
        --main)
        MAIN="$2"
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

# Example: Print the file names
echo "Code file:   $C_FILE"
echo "Header file: $H_FILE"
echo "ISpec file:  $ISPEC_FILE"

# ------------------------------------------------------
# Add your actual processing logic here
# For example: compile, analyze, or combine the files
# ------------------------------------------------------

# Example placeholder
echo "Processing files..."

echo "Running control flow check..."
./control-flow-check.sh --folder "$FOLDER" --modname "$MODNAME" --main "$MAIN"
echo "Control flow check completed successfully."
echo "############################################"
echo "############################################"
echo "############################################"
echo ""
echo ""

echo "############################################"
echo "Running data flow check..."
./data-flow-check.sh --folder "$FOLDER" --modname "$MODNAME" --main "$MAIN"
echo "Data flow check completed successfully."