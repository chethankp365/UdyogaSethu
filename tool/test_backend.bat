@echo off
setlocal enabledelayedexpansion

echo ====================================================
echo  UdyogaSethu Backend Test Runner (tool\test_backend.bat)
echo ====================================================

dart run tool\test_backend.dart
if errorlevel 1 (
    echo [ERROR] Backend SQL tests failed with exit code %errorlevel%.
    exit /b %errorlevel%
)

echo [SUCCESS] Backend test runner completed successfully.
exit /b 0
