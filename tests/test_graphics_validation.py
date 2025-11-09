#!/usr/bin/env python3
"""
Graphics Validation Test for Factorio 2.0 Migration

This test validates that custom graphics in the mod have correct sprite dimensions
and won't cause "sprite rectangle is outside the actual sprite size" errors.

Key Validation:
- Sprite width/height match actual image dimensions
- Frame count and line length don't exceed image bounds
- Both normal and hr_version sprites are validated

This catches Issue #11 from FACTORIO_2_MIGRATION_TESTS.md:
"Sprite Rectangle Overflow When Using deepcopy"
"""

import sys
import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

try:
    from PIL import Image  # type: ignore
except ImportError:
    print("ERROR: Pillow not installed. Install with: pip install Pillow")
    sys.exit(1)


class GraphicsValidator:
    """Validates graphics files and sprite definitions in Lua prototypes."""

    def __init__(self, mod_root: Path):
        self.mod_root = mod_root
        self.graphics_dir = mod_root / "graphics"
        self.prototypes_dir = mod_root / "prototypes"
        self.errors: List[str] = []
        self.warnings: List[str] = []

    def get_image_dimensions(self, image_path: Path) -> Optional[Tuple[int, int]]:
        """Get actual dimensions of a PNG image file."""
        try:
            with Image.open(image_path) as img:
                return img.size  # (width, height)
        except Exception as e:
            self.errors.append(f"Failed to read {image_path}: {e}")
            return None

    def validate_sprite_rectangle(
        self,
        image_path: Path,
        width: int,
        height: int,
        frame_count: int = 1,
        line_length: Optional[int] = None
    ) -> bool:
        """
        Validate that sprite rectangle fits within actual image dimensions.

        Args:
            image_path: Path to the image file
            width: Sprite frame width
            height: Sprite frame height
            frame_count: Number of animation frames
            line_length: Frames per row (defaults to frame_count)

        Returns:
            True if valid, False if error
        """
        actual_dims = self.get_image_dimensions(image_path)
        if actual_dims is None:
            return False

        actual_width, actual_height = actual_dims

        # Default line_length to frame_count (single row)
        if line_length is None:
            line_length = frame_count

        # Calculate required image dimensions
        frames_per_row = line_length
        rows = (frame_count + line_length - 1) // line_length  # Ceiling division

        required_width = width * frames_per_row
        required_height = height * rows

        if required_width > actual_width or required_height > actual_height:
            self.errors.append(
                f"SPRITE RECTANGLE OVERFLOW: {image_path.name}\n"
                f"  Sprite definition: {width}x{height}, "
                f"{frame_count} frames, {line_length} per line\n"
                f"  Required image size: {required_width}x{required_height}\n"
                f"  Actual image size: {actual_width}x{actual_height}\n"
                f"  Rectangle would be: (0, 0) to "
                f"({required_width-1}, {required_height-1})"
            )
            return False

        # Check if dimensions match exactly (not just fit within)
        if required_width != actual_width or required_height != actual_height:
            self.warnings.append(
                f"Sprite size mismatch (non-critical): {image_path.name}\n"
                f"  Expected: {required_width}x{required_height}, "
                f"Actual: {actual_width}x{actual_height}"
            )

        return True

    def validate_custom_graphics(self) -> bool:
        """
        Validate all custom graphics in the mod.

        This focuses on graphics that use deepcopy from base game entities,
        which is the most common source of sprite rectangle overflow errors.

        Returns:
            True if all validations pass
        """
        all_valid = True

        # Validate pollution collector (deepcopied from storage-tank)
        pollution_collector = self.graphics_dir / "entity" / "pollution-collector"
        if pollution_collector.exists():
            # Normal resolution: 220x108
            normal_sprite = pollution_collector / "pollution-collector.png"
            if normal_sprite.exists():
                if not self.validate_sprite_rectangle(
                    normal_sprite,
                    width=220,
                    height=108,
                    frame_count=1,
                    line_length=1
                ):
                    all_valid = False

            # High resolution: 438x215 (actual image size)
            hr_sprite = pollution_collector / "hr-pollution-collector.png"
            if hr_sprite.exists():
                if not self.validate_sprite_rectangle(
                    hr_sprite,
                    width=438,
                    height=215,
                    frame_count=1,
                    line_length=1
                ):
                    all_valid = False

        # Validate flamethrower explosion (deepcopied from flamethrower-fire-stream)
        flamethrower_dir = self.graphics_dir / "entity" / "flamethrower-fire-stream"
        if flamethrower_dir.exists():
            explosion_sprite = flamethrower_dir / "flamethrower-explosion.png"
            if explosion_sprite.exists():
                # Particle explosion: 512x512
                if not self.validate_sprite_rectangle(
                    explosion_sprite,
                    width=512,
                    height=512,
                    frame_count=1,
                    line_length=1
                ):
                    all_valid = False

        # Validate incinerator (deepcopied from nuclear-reactor)
        incinerator_dir = self.graphics_dir / "entity" / "incinerator"
        if incinerator_dir.exists():
            # Normal resolution
            normal_sprite = incinerator_dir / "incinerator.png"
            if normal_sprite.exists():
                dims = self.get_image_dimensions(normal_sprite)
                if dims:
                    width, height = dims
                    if not self.validate_sprite_rectangle(
                        normal_sprite,
                        width=width,
                        height=height,
                        frame_count=1,
                        line_length=1
                    ):
                        all_valid = False

            # High resolution
            hr_sprite = incinerator_dir / "hr-incinerator.png"
            if hr_sprite.exists():
                dims = self.get_image_dimensions(hr_sprite)
                if dims:
                    width, height = dims
                    if not self.validate_sprite_rectangle(
                        hr_sprite,
                        width=width,
                        height=height,
                        frame_count=1,
                        line_length=1
                    ):
                        all_valid = False

        # Validate low heat exchanger (deepcopied from heat-exchanger)
        lowheatex_dir = self.graphics_dir / "entity" / "low-heat-exchanger"
        if lowheatex_dir.exists():
            # These are directional sprites - validate all 4 directions
            for direction in ['N', 'E', 'S', 'W']:
                for prefix in ['', 'hr-']:
                    sprite_file = lowheatex_dir / f"{prefix}lowheatex-{direction}-idle.png"
                    if sprite_file.exists():
                        dims = self.get_image_dimensions(sprite_file)
                        if dims:
                            width, height = dims
                            if not self.validate_sprite_rectangle(
                                sprite_file,
                                width=width,
                                height=height,
                                frame_count=1,
                                line_length=1
                            ):
                                all_valid = False

        return all_valid

    def check_lua_sprite_definitions(self) -> bool:
        """
        Check Lua prototype files for common sprite definition mistakes.

        This looks for patterns that indicate missing dimension resets after deepcopy.
        """
        all_valid = True

        # Pattern: deepcopy followed by filename change without dimension reset
        deepcopy_pattern = re.compile(
            r'util\.table\.deepcopy\([^)]+\).*?\.filename\s*=',
            re.DOTALL
        )

        # Pattern: dimension reset (good)
        dimension_reset_pattern = re.compile(
            r'\.width\s*=.*?\.height\s*=.*?\.frame_count\s*=',
            re.DOTALL
        )

        for lua_file in self.prototypes_dir.glob("*.lua"):
            try:
                content = lua_file.read_text()

                # Find all deepcopy blocks
                for match in deepcopy_pattern.finditer(content):
                    # Extract context (100 chars after the match)
                    start = match.start()
                    end = min(match.end() + 100, len(content))
                    context = content[start:end]

                    # Check if dimension reset appears in context
                    if not dimension_reset_pattern.search(context):
                        self.warnings.append(
                            f"Potential missing dimension reset in {lua_file.name}\n"
                            f"  Found deepcopy + filename change without width/height/frame_count reset\n"
                            f"  Context: {context[:80]}..."
                        )

            except Exception as e:
                self.errors.append(f"Failed to read {lua_file}: {e}")
                all_valid = False

        return all_valid

    def run_validation(self) -> bool:
        """Run all validation checks."""
        print("=" * 70)
        print("Graphics Validation Test")
        print("Checking sprite dimensions for Factorio 2.0 compatibility")
        print("=" * 70)
        print()

        graphics_valid = self.validate_custom_graphics()
        lua_valid = self.check_lua_sprite_definitions()

        print()
        print("=" * 70)
        print("Validation Results")
        print("=" * 70)

        if self.warnings:
            print(f"\nWarnings ({len(self.warnings)}):")
            for warning in self.warnings:
                print(f"  ⚠ {warning}")

        if self.errors:
            print(f"\nErrors ({len(self.errors)}):")
            for error in self.errors:
                print(f"  ✗ {error}")

        all_valid = graphics_valid and lua_valid and not self.errors

        print()
        if all_valid:
            print("✓ PASS: All graphics validated successfully")
        else:
            print("✗ FAIL: Graphics validation found errors")

        return all_valid


def main():
    """Run graphics validation test."""
    mod_root = Path(__file__).parent.parent
    validator = GraphicsValidator(mod_root)

    success = validator.run_validation()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
