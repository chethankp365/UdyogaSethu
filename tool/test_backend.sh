#!/usr/bin/env bash
set -eo pipefail

echo "===================================================="
echo " UdyogaSethu Backend Test Runner (tool/test_backend.sh)"
echo "===================================================="

# Run the Dart SQL validation and test executor
dart run tool/test_backend.dart

echo "Backend test runner completed successfully."
