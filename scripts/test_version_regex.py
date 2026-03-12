#!/usr/bin/env python3
"""
Test the VERSION regex pattern from collect_architectures.py
"""

import re

# Test cases for VERSION line in Makefile
test_cases = [
    ("VERSION = 3.3.0", "3.3.0"),
    ("VERSION ?= 3.3.0", "3.3.0"),
    ("VERSION := 3.3.0", "3.3.0"),
    ("VERSION = 3.3.0 # comment", "3.3.0"),
    ("VERSION ?= 3.3.0   # comment with spaces", "3.3.0"),
    ("VERSION := 3.3.0\t# tab before comment", "3.3.0"),
    ('VERSION = "3.3.0"', "3.3.0"),
    ("VERSION = '3.3.0'", "3.3.0"),
    ("VERSION = (3.3.0)", "3.3.0"),
    ("VERSION=3.3.0", "3.3.0"),  # no spaces
    ("VERSION = 2.18.0", "2.18.0"),
    ("VERSION ?= v3.3.0", "v3.3.0"),  # with v prefix (will be stripped later)
    ("\tVERSION = 3.3.0", "3.3.0"),  # indented with tab (ifeq blocks)
    ("\t\tVERSION = 3.3.0", "3.3.0"),  # double-indented
    ("    VERSION = 3.3.0", "3.3.0"),  # indented with spaces
]

# The regex from collect_architectures.py (updated to allow leading whitespace)
pattern = r'^\s*VERSION\s*[\?:]?=\s*([^\s#]+)'

print("Testing VERSION regex pattern")
print("Pattern:", pattern)
print("\n" + "="*80 + "\n")

all_passed = True

for test_input, expected in test_cases:
    match = re.search(pattern, test_input, re.MULTILINE)
    if match:
        raw_version = match.group(1).strip()
        # Apply the same cleaning as in the script
        version = raw_version.strip('"').strip("'").strip('(').strip(')')

        if version == expected:
            print(f"✓ PASS: '{test_input}'")
            print(f"        → '{version}'")
        else:
            print(f"✗ FAIL: '{test_input}'")
            print(f"        Expected: '{expected}'")
            print(f"        Got:      '{version}'")
            all_passed = False
    else:
        print(f"✗ FAIL: '{test_input}'")
        print(f"        Expected: '{expected}'")
        print(f"        Got:      No match")
        all_passed = False
    print()

print("="*80)
if all_passed:
    print("✓ All tests passed!")
else:
    print("✗ Some tests failed")
    exit(1)
