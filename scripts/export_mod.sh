#!/bin/bash#!/bin/bash

# Export PollutionSolutionsLite mod to Factorio mods directory# Export PollutionSolutionsLite mod to Factorio mods directory

# Usage: ./export_mod.sh [destination_path]# Usage: ./export_mod.sh [destination_path]

# If no destination provided, uses symlink (factorio-export/) or default Factorio mods directory# If no destination provided, uses symlink (factorio-export/) or default Factorio mods directory



MOD_NAME="PollutionSolutionsLite"MOD_NAME="PollutionSolutionsLite"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

MOD_SOURCE_DIR="$(dirname "$SCRIPT_DIR")"MOD_SOURCE_DIR="$(dirname "$SCRIPT_DIR")"



# Determine destination# Determine destination

if [ -n "$1" ]; thenif [ -n "$1" ]; then

  # User provided explicit path  # User provided explicit path

  DEST_DIR="$1"  DEST_DIR="$1"

elif [ -L "$MOD_SOURCE_DIR/factorio" ]; thenelif [ -L "$MOD_SOURCE_DIR/factorio" ]; then

  # Use symlink if available  # Use symlink if available

  DEST_DIR="$MOD_SOURCE_DIR/factorio/mods"  DEST_DIR="$MOD_SOURCE_DIR/factorio/mods"

elseelse

  # Fall back to default based on OS  # Fall back to default based on OS

  if [[ "$OSTYPE" == "linux-gnu"* ]]; then  if [[ "$OSTYPE" == "linux-gnu"* ]]; then

    # Linux    # Linux

    DEST_DIR="${HOME}/.factorio/mods"    DEST_DIR="${HOME}/.factorio/mods"

  elif [[ "$OSTYPE" == "darwin"* ]]; then  elif [[ "$OSTYPE" == "darwin"* ]]; then

    # macOS    # macOS

    DEST_DIR="${HOME}/Library/Application Support/factorio/mods"    DEST_DIR="${HOME}/Library/Application Support/factorio/mods"

  elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then  elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then

    # Windows    # Windows

    DEST_DIR="${APPDATA}/Factorio/mods"    DEST_DIR="${APPDATA}/Factorio/mods"

  else  else

    echo "Error: Could not determine OS type. Please provide destination path as argument."    echo "Error: Could not determine OS type. Please provide destination path as argument."

    echo "Usage: $0 <destination_path>"    echo "Usage: $0 <destination_path>"

    exit 1    exit 1

  fi  fi

fifi



# Check if destination exists# Check if destination exists

if [ ! -d "$DEST_DIR" ]; thenif [ ! -d "$DEST_DIR" ]; then

  echo "Error: Destination directory does not exist: $DEST_DIR"  echo "Error: Destination directory does not exist: $DEST_DIR"

  exit 1  exit 1

fifi



# Check if source exists# Check if source exists

if [ ! -d "$MOD_SOURCE_DIR" ]; thenif [ ! -d "$MOD_SOURCE_DIR" ]; then

  echo "Error: Source directory does not exist: $MOD_SOURCE_DIR"  echo "Error: Source directory does not exist: $MOD_SOURCE_DIR"

  exit 1  exit 1

fifi



echo "=========================================="echo "=========================================="

echo "Exporting $MOD_NAME"echo "Exporting $MOD_NAME"

echo "=========================================="echo "=========================================="

echo "Source: $MOD_SOURCE_DIR"echo "Source: $MOD_SOURCE_DIR"

echo "Destination: $DEST_DIR/$MOD_NAME"echo "Destination: $DEST_DIR/$MOD_NAME"

echo ""echo ""



# Remove existing mod if present# Remove existing mod if present

if [ -d "$DEST_DIR/$MOD_NAME" ]; thenif [ -d "$DEST_DIR/$MOD_NAME" ]; then

  echo "Removing existing mod directory..."  echo "Removing existing mod directory..."

  rm -rf "$DEST_DIR/$MOD_NAME"  rm -rf "$DEST_DIR/$MOD_NAME"

fifi



# Copy mod (excluding .git directory and development files)# Copy mod (excluding .git directory and development files)

echo "Copying mod files..."

rsync -av --exclude='.git' --exclude='.gitignore' --exclude='.github' --exclude='scripts' --exclude='docs' --exclude='tests' --exclude='run_tests.lua' --exclude='factorio' --exclude='.internal-bugs' "$MOD_SOURCE_DIR/" "$DEST_DIR/$MOD_NAME/" 2>/dev/null || cp -r "$MOD_SOURCE_DIR" "$DEST_DIR/$MOD_NAME"



# Verify export# Verify export

if [ -d "$DEST_DIR/$MOD_NAME" ] && [ -f "$DEST_DIR/$MOD_NAME/info.json" ]; thenif [ -d "$DEST_DIR/$MOD_NAME" ] && [ -f "$DEST_DIR/$MOD_NAME/info.json" ]; then

  echo ""  echo ""

  echo "✓ Export successful!"  echo "✓ Export successful!"

  echo "Mod location: $DEST_DIR/$MOD_NAME"  echo "Mod location: $DEST_DIR/$MOD_NAME"

  ls -lh "$DEST_DIR/$MOD_NAME/" | head -n 10  ls -lh "$DEST_DIR/$MOD_NAME/" | head -n 10

  exit 0  exit 0

elseelse

  echo ""  echo ""

  echo "✗ Export failed!"  echo "✗ Export failed!"

  exit 1  exit 1

fifi

