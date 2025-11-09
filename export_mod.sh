#!/bin/bash
# Export PollutionSolutionsLite mod to Factorio mods directory
# Usage: ./export_mod.sh [destination_path]
# If no destination provided, uses symlink (factorio-export/) or default Factorio mods directory

MOD_NAME="PollutionSolutionsLite"
MOD_SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Determine destination
if [ -n "$1" ]; then
  # User provided explicit path
  DEST_DIR="$1"
elif [ -L "$MOD_SOURCE_DIR/factorio" ]; then
  # Use symlink if available
  DEST_DIR="$MOD_SOURCE_DIR/factorio/mods"
else
  # Fall back to default based on OS
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    DEST_DIR="${HOME}/.factorio/mods"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    DEST_DIR="${HOME}/Library/Application Support/factorio/mods"
  elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Windows
    DEST_DIR="${APPDATA}/Factorio/mods"
  else
    echo "Error: Could not determine OS type. Please provide destination path as argument."
    echo "Usage: $0 <destination_path>"
    exit 1
  fi
fi

# Check if destination exists
if [ ! -d "$DEST_DIR" ]; then
  echo "Error: Destination directory does not exist: $DEST_DIR"
  exit 1
fi

# Check if source exists
if [ ! -d "$MOD_SOURCE_DIR" ]; then
  echo "Error: Source directory does not exist: $MOD_SOURCE_DIR"
  exit 1
fi

echo "=========================================="
echo "Exporting $MOD_NAME"
echo "=========================================="
echo "Source: $MOD_SOURCE_DIR"
echo "Destination: $DEST_DIR/$MOD_NAME"
echo ""

# Remove existing mod if present
if [ -d "$DEST_DIR/$MOD_NAME" ]; then
  echo "Removing existing mod directory..."
  rm -rf "$DEST_DIR/$MOD_NAME"
fi

# Copy mod (excluding .git directory)
echo "Copying mod files..."
rsync -av --exclude='.git' --exclude='.gitignore' --exclude='run_tests.lua' "$MOD_SOURCE_DIR/" "$DEST_DIR/$MOD_NAME/" 2>/dev/null || cp -r "$MOD_SOURCE_DIR" "$DEST_DIR/$MOD_NAME"

# Verify export
if [ -d "$DEST_DIR/$MOD_NAME" ] && [ -f "$DEST_DIR/$MOD_NAME/info.json" ]; then
  echo ""
  echo "✓ Export successful!"
  echo "Mod location: $DEST_DIR/$MOD_NAME"
  ls -lh "$DEST_DIR/$MOD_NAME/" | head -n 10
  exit 0
else
  echo ""
  echo "✗ Export failed!"
  exit 1
fi
