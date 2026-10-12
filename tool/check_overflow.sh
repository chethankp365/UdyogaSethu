#!/usr/bin/env bash
set -e

echo "=== Running UdyogaSethu Layout Overflow Test Suite ==="
echo "Testing all screen widths (320-600dp), text scales (1.0-2.0), and 5 regional languages..."

echo "1/3: Running Screen Coverage Audit Test..."
flutter test test/screen_coverage_audit_test.dart

echo "2/3: Running Component and Screen Overflow Finder Matrix Suite..."
flutter test test/comprehensive_overflow_finder_test.dart

echo "3/3: Running Farmer Home Responsive Matrix Suite..."
flutter test test/farmer_home_overflow_test.dart

echo "=== Overflow Checks Passed! ZERO RenderFlex Overflows Detected. ==="
