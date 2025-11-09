#!/usr/bin/env python3
"""
Test: Validate global → storage migration for Factorio 2.0

This test ensures control.lua doesn't use the deprecated 'global' table
which was renamed to 'storage' in Factorio 2.0.

Issue: In Factorio 2.0, the global persistent data table was renamed:
  Factorio 1.x: global.myData = {}
  Factorio 2.0: storage.myData = {}

Error if not fixed:
  attempt to index global 'global' (a nil value)
  
This test scans control.lua and other runtime scripts for 'global.' usage.
"""

import re
import sys
from pathlib import Path

def check_for_global_usage(file_path):
    """Check if file uses deprecated 'global' table."""
    content = file_path.read_text()
    errors = []
    
    # Find all uses of 'global.' (but not in comments)
    lines = content.split('\n')
    
    for line_num, line in enumerate(lines, 1):
        # Skip comment lines
        if line.strip().startswith('--'):
            continue
            
        # Check for global. usage (word boundary to avoid 'settings.global')
        if re.search(r'\bglobal\.', line):
            # Make sure it's not settings.global which is still valid
            if not re.search(r'settings\.global', line):
                errors.append({
                    'line': line_num,
                    'content': line.strip(),
                    'file': file_path
                })
    
    return errors

def main():
    """Main test function."""
    print("=" * 70)
    print("TEST: Validate global → storage migration (Factorio 2.0)")
    print("=" * 70)
    
    # Check control.lua and any other Lua files in root
    lua_files = [
        Path('control.lua'),
    ]
    
    # Also check scripts directory if it exists
    scripts_dir = Path('scripts')
    if scripts_dir.exists():
        lua_files.extend(scripts_dir.glob('*.lua'))
    
    all_errors = []
    
    for file_path in lua_files:
        if not file_path.exists():
            continue
            
        print(f"\n📂 Checking {file_path}...")
        errors = check_for_global_usage(file_path)
        
        if errors:
            print(f"  ❌ Found {len(errors)} uses of deprecated 'global' table:")
            for error in errors:
                print(f"    Line {error['line']}: {error['content']}")
            all_errors.extend(errors)
        else:
            print(f"  ✅ No deprecated 'global' usage found")
    
    # Print summary
    print("\n" + "=" * 70)
    print("SUMMARY")
    print("=" * 70)
    
    if all_errors:
        print(f"\n❌ {len(all_errors)} ERRORS found!")
        print("\n💡 FIX: Replace 'global' with 'storage' in Factorio 2.0:")
        print("   Factorio 1.x: global.myData = {}")
        print("   Factorio 2.0: storage.myData = {}")
        print("\n   Note: 'settings.global' is still valid and doesn't need changing")
        print("\n   Quick fix: sed -i 's/\\bglobal\\./storage./g' control.lua")
        return 1
    else:
        print("\n✅ All files use correct 'storage' table for Factorio 2.0!")
        print("   (Or no persistent data storage detected)")
        return 0

if __name__ == '__main__':
    sys.exit(main())
