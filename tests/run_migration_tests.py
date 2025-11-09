#!/usr/bin/env python3
"""
Factorio 2.0 Migration Test Runner

Runs comprehensive tests to validate Factorio 2.0 API compatibility.
This can be run as part of CI/CD or locally during development.

Usage:
    python tests/run_migration_tests.py
    python tests/run_migration_tests.py --verbose
"""

import sys
import subprocess
from pathlib import Path
import argparse


def run_lua_tests(test_file: Path, verbose: bool = False) -> bool:
    """Run a Lua test file and return success status"""
    print(f"\n{'='*70}")
    print(f"Running: {test_file.name}")
    print(f"{'='*70}\n")
    
    try:
        result = subprocess.run(
            ['lua', str(test_file)],
            capture_output=not verbose,
            text=True,
            cwd=test_file.parent.parent,
            timeout=30
        )
        
        if verbose or result.returncode != 0:
            if result.stdout:
                print(result.stdout)
            if result.stderr:
                print("STDERR:", result.stderr, file=sys.stderr)
        
        return result.returncode == 0
        
    except subprocess.TimeoutExpired:
        print(f"✗ Test timed out: {test_file.name}")
        return False
    except FileNotFoundError:
        print("✗ Error: Lua interpreter not found. Please install Lua 5.2+")
        print("  Ubuntu/Debian: sudo apt-get install lua5.2")
        print("  Fedora: sudo dnf install lua")
        print("  macOS: brew install lua")
        return False
    except Exception as e:
        print(f"✗ Error running test: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description='Run Factorio 2.0 migration validation tests'
    )
    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='Show detailed test output'
    )
    parser.add_argument(
        '--test', '-t',
        help='Run specific test file (default: run all migration tests)'
    )
    args = parser.parse_args()
    
    # Find tests directory
    script_dir = Path(__file__).parent
    tests_dir = script_dir if script_dir.name == 'tests' else script_dir / 'tests'
    
    if not tests_dir.exists():
        print(f"✗ Error: Tests directory not found: {tests_dir}")
        sys.exit(1)
    
    # Determine which tests to run
    if args.test:
        test_files = [tests_dir / args.test]
    else:
        # Run all migration tests
        test_files = [
            tests_dir / 'test_factorio_2_migration.lua',
        ]
    
    # Verify test files exist
    test_files = [f for f in test_files if f.exists()]
    
    if not test_files:
        print("✗ Error: No test files found")
        sys.exit(1)
    
    print("=" * 70)
    print("Factorio 2.0 Migration Test Suite")
    print("=" * 70)
    print(f"\nTests to run: {len(test_files)}")
    for test_file in test_files:
        print(f"  - {test_file.name}")
    
    # Run tests
    results = {}
    for test_file in test_files:
        success = run_lua_tests(test_file, args.verbose)
        results[test_file.name] = success
    
    # Print summary
    print("\n" + "=" * 70)
    print("Test Suite Summary")
    print("=" * 70)
    
    passed = sum(1 for v in results.values() if v)
    failed = len(results) - passed
    
    print(f"\nTotal test files: {len(results)}")
    print(f"Passed: {passed}")
    print(f"Failed: {failed}")
    
    if failed > 0:
        print("\n✗ Failed tests:")
        for test_name, success in results.items():
            if not success:
                print(f"  - {test_name}")
        print()
        sys.exit(1)
    else:
        print("\n✓ All migration tests passed!")
        print()
        sys.exit(0)


if __name__ == '__main__':
    main()
