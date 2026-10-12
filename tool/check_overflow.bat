@echo off
echo === Running UdyogaSethu Layout Overflow Test Suite ===
echo Testing all screen widths (320-600dp), text scales (1.0-2.0), and 5 regional languages...

echo 1/3: Running Screen Coverage Audit Test...
call flutter test test/screen_coverage_audit_test.dart
if %ERRORLEVEL% NEQ 0 (
  echo [ERROR] Screen coverage audit test failed!
  exit /b %ERRORLEVEL%
)

echo 2/3: Running Component and Screen Overflow Finder Matrix Suite...
call flutter test test/comprehensive_overflow_finder_test.dart
if %ERRORLEVEL% NEQ 0 (
  echo [ERROR] Comprehensive overflow test failed!
  exit /b %ERRORLEVEL%
)

echo 3/3: Running Farmer Home Responsive Matrix Suite...
call flutter test test/farmer_home_overflow_test.dart
if %ERRORLEVEL% NEQ 0 (
  echo [ERROR] Farmer home overflow tests failed!
  exit /b %ERRORLEVEL%
)

echo === Overflow Checks Passed! ZERO RenderFlex Overflows Detected. ===
