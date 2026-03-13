#!/usr/bin/env python3
"""
Generate PNG files from Mermaid (.mmd) diagrams using mmdc (Mermaid CLI).

Usage:
    python scripts/generate_diagram_pngs.py /path/to/diagrams --width=3000
    python scripts/generate_diagram_pngs.py diagram.mmd --width=3000
"""

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path


def find_chrome_executable() -> str | None:
    """
    Find Chrome/Chromium executable.

    Returns:
        Path to Chrome executable, or None if not found
    """
    # Try common paths in priority order
    common_paths = [
        '/usr/bin/google-chrome',      # Most common on Linux
        '/usr/bin/chromium',            # Chromium on Linux
        '/usr/bin/chromium-browser',   # Ubuntu/Debian
    ]

    for path in common_paths:
        if os.path.isfile(path):
            return path

    # Try which command
    for cmd in ['google-chrome', 'chromium', 'chromium-browser']:
        try:
            result = subprocess.run(
                ['which', cmd],
                capture_output=True,
                text=True,
                check=False
            )
            if result.returncode == 0:
                path = result.stdout.strip()
                if path and os.path.isfile(path):
                    return path
        except Exception:
            pass

    return None


def check_mmdc_available() -> bool:
    """Check if mmdc (Mermaid CLI) is installed."""
    return shutil.which('mmdc') is not None


def generate_png(mmd_file: Path, png_file: Path, width: int, chrome_path: str) -> bool:
    """
    Generate PNG from Mermaid diagram.

    Args:
        mmd_file: Path to .mmd file
        png_file: Path to output .png file
        width: Width in pixels
        chrome_path: Path to Chrome executable

    Returns:
        True if successful, False otherwise
    """
    try:
        env = os.environ.copy()
        env['PUPPETEER_EXECUTABLE_PATH'] = chrome_path

        result = subprocess.run(
            ['mmdc', '-i', str(mmd_file), '-o', str(png_file), '-w', str(width)],
            env=env,
            capture_output=True,
            text=True,
            check=False
        )

        if result.returncode != 0:
            print(f"  ✗ Failed: {mmd_file.name}", file=sys.stderr)
            if result.stderr:
                print(f"    Error: {result.stderr.strip()}", file=sys.stderr)
            return False

        return True

    except Exception as e:
        print(f"  ✗ Failed: {mmd_file.name} - {e}", file=sys.stderr)
        return False


def process_directory(directory: Path, width: int, chrome_path: str) -> tuple[int, int]:
    """
    Process all .mmd files in a directory.

    Args:
        directory: Directory containing .mmd files
        width: Width in pixels
        chrome_path: Path to Chrome executable

    Returns:
        Tuple of (successful, failed) counts
    """
    mmd_files = list(directory.glob('*.mmd'))

    if not mmd_files:
        print(f"No .mmd files found in {directory}")
        return 0, 0

    successful = 0
    failed = 0

    print(f"Generating PNGs for {len(mmd_files)} Mermaid diagram(s)...")
    print(f"Width: {width}px, Chrome: {chrome_path}\n")

    for mmd_file in sorted(mmd_files):
        png_file = mmd_file.with_suffix('.png')
        print(f"  {mmd_file.name} → {png_file.name}")

        if generate_png(mmd_file, png_file, width, chrome_path):
            successful += 1
        else:
            failed += 1

    return successful, failed


def main():
    parser = argparse.ArgumentParser(
        description='Generate PNG files from Mermaid diagrams'
    )
    parser.add_argument(
        'path',
        type=Path,
        help='Path to .mmd file or directory containing .mmd files'
    )
    parser.add_argument(
        '--width',
        type=int,
        default=10000,
        help='PNG width in pixels (default: 3000)'
    )
    parser.add_argument(
        '--chrome-path',
        type=Path,
        help='Path to Chrome/Chromium executable (default: auto-detect)'
    )

    args = parser.parse_args()

    # Check if mmdc is available
    if not check_mmdc_available():
        print("Error: mmdc (Mermaid CLI) not found", file=sys.stderr)
        print("Install with: npm install -g @mermaid-js/mermaid-cli", file=sys.stderr)
        return 1

    # Find Chrome executable
    if args.chrome_path:
        chrome_path = str(args.chrome_path)
        if not os.path.isfile(chrome_path):
            print(f"Error: Chrome executable not found: {chrome_path}", file=sys.stderr)
            return 1
    else:
        chrome_path = find_chrome_executable()
        if not chrome_path:
            print("Error: Chrome/Chromium not found", file=sys.stderr)
            print("Install Chrome or specify path with --chrome-path", file=sys.stderr)
            return 1

    # Process path
    if not args.path.exists():
        print(f"Error: Path does not exist: {args.path}", file=sys.stderr)
        return 1

    if args.path.is_dir():
        # Process directory
        successful, failed = process_directory(args.path, args.width, chrome_path)
    elif args.path.suffix == '.mmd':
        # Process single file
        png_file = args.path.with_suffix('.png')
        print(f"Generating PNG: {args.path.name} → {png_file.name}")
        print(f"Width: {args.width}px, Chrome: {chrome_path}\n")

        if generate_png(args.path, png_file, args.width, chrome_path):
            successful = 1
            failed = 0
        else:
            successful = 0
            failed = 1
    else:
        print(f"Error: Path must be a directory or .mmd file: {args.path}", file=sys.stderr)
        return 1

    # Summary
    print(f"\n{'='*60}")
    print(f"✅ PNG generation complete!")
    print(f"{'='*60}")
    print(f"Successful: {successful}")
    print(f"Failed: {failed}")
    print(f"Width: {args.width}px")

    return 0 if failed == 0 else 1


if __name__ == '__main__':
    exit(main())
