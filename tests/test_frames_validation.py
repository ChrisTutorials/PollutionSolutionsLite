#!/usr/bin/env python3
"""
Test: Validate frames=1 is explicitly set when deepcopying base game sprites

This test ensures that when we deepcopy entities from the base game, we explicitly
set frames=1 to avoid inheriting multi-frame sprite sheet configurations that don't
match our custom graphics.

Issue discovered: Base game entities like storage-tank use frames=2 or more, which
causes sprite rectangle errors when our custom sprites have different dimensions.

Example error:
  The given sprite rectangle (left_top=220x0, right_bottom=440x108) is outside 
  the actual sprite size (left_top=0x0, right_bottom=220x108).

Root cause: frames=2 makes Factorio try to read 2 horizontal frames, doubling the width.
"""

import re
import sys
from pathlib import Path

def check_frames_in_file(file_path):
    """Check if deepcopied entities have explicit frames=1 set."""
    content = file_path.read_text()
    errors = []
    warnings = []
    
    # Find all deepcopy calls
    deepcopy_pattern = r'util\.table\.deepcopy\(data\.raw\["([^"]+)"\]\["([^"]+)"\]\)'
    deepcopies = list(re.finditer(deepcopy_pattern, content))
    
    if not deepcopies:
        return errors, warnings
    
    print(f"\n📂 {file_path.name}:")
    print(f"  Found {len(deepcopies)} deepcopy operations")
    
    for match in deepcopies:
        entity_type = match.group(1)
        entity_name = match.group(2)
        start_pos = match.start()
        
        # Find the variable name being assigned
        line_start = content.rfind('\n', 0, start_pos) + 1
        line_content = content[line_start:start_pos]
        var_match = re.search(r'(\w+)\s*=\s*$', line_content)
        
        if not var_match:
            warnings.append(f"  ⚠️  Could not find variable name for {entity_type}/{entity_name}")
            continue
            
        var_name = var_match.group(1)
        print(f"  🔍 {var_name} = deepcopy({entity_type}/{entity_name})")
        
        # Check if this entity modifies sprite properties
        # Look for patterns like: var_name.pictures = ..., var_name.animation = ..., etc.
        sprite_props = [
            'pictures', 'picture', 'animation', 'animations', 
            'sprite', 'sprites', 'spine_animation', 'particle'
        ]
        
        has_sprite_modification = False
        for prop in sprite_props:
            # Pattern: var_name.prop.something or var_name.prop =
            if re.search(rf'{var_name}\.{prop}[\.\s=]', content):
                has_sprite_modification = True
                print(f"    ✓ Modifies {prop}")
                
                # Check if frames=1 is set for this property
                # Look for patterns like: var_name.prop.frames = 1
                frames_pattern = rf'{var_name}\.{prop}.*?frames\s*=\s*1'
                if not re.search(frames_pattern, content, re.DOTALL):
                    errors.append(
                        f"  ❌ {var_name}.{prop} modified but frames=1 not explicitly set!\n"
                        f"     Entity: {entity_type}/{entity_name}\n"
                        f"     File: {file_path}\n"
                        f"     Fix: Add {var_name}.{prop}.frames = 1"
                    )
        
        if has_sprite_modification:
            # Also check for nested sheet modifications
            # Pattern: var_name.pictures.picture.sheets[1].frames = 1
            if re.search(rf'{var_name}\.(pictures|animation).*?sheets', content):
                if not re.search(rf'{var_name}\..*?\.frames\s*=\s*1', content):
                    warnings.append(
                        f"  ⚠️  {var_name} has sheets but frames=1 not clearly visible\n"
                        f"     This might be OK if frames is set in sheet definition\n"
                        f"     File: {file_path}"
                    )
    
    return errors, warnings

def main():
    """Main test function."""
    print("=" * 70)
    print("TEST: Validate frames=1 on deepcopied sprites")
    print("=" * 70)
    
    # Find all prototype files
    prototype_files = list(Path('prototypes').glob('*.lua'))
    
    all_errors = []
    all_warnings = []
    
    for file_path in sorted(prototype_files):
        errors, warnings = check_frames_in_file(file_path)
        all_errors.extend(errors)
        all_warnings.extend(warnings)
    
    # Print summary
    print("\n" + "=" * 70)
    print("SUMMARY")
    print("=" * 70)
    
    if all_warnings:
        print(f"\n⚠️  {len(all_warnings)} warnings:")
        for warning in all_warnings:
            print(warning)
    
    if all_errors:
        print(f"\n❌ {len(all_errors)} ERRORS:")
        for error in all_errors:
            print(error)
        print("\n💡 TIP: When using deepcopy on entities with sprites, always set:")
        print("   entity.pictures.picture.sheets[1].frames = 1")
        print("   entity.animation.frames = 1")
        print("   entity.spine_animation.frames = 1")
        print("   etc.")
        return 1
    else:
        print("\n✅ All deepcopied sprites have frames=1 explicitly set!")
        return 0

if __name__ == '__main__':
    sys.exit(main())
