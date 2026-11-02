# UdyogaSethu Android Real-Device Testing Guide

This guide provides repeatable Windows PowerShell commands for testing UdyogaSethu on a physical Android phone or emulator.

---

## 1. Prerequisites & Environment Setup

On Windows workstations, `adb.exe` is located in the Android SDK platform-tools folder:
`$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe`

You can alias `adb` in your current PowerShell terminal session:
```powershell
Set-Alias adb "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
```

### 1.1 Verify Connected Hardware
Ensure your Android phone has **Developer Options** and **USB Debugging** enabled, and is connected via a USB cable.

```powershell
# Check Flutter device recognition
flutter devices

# Check ADB daemon recognition
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
```

Expected output when a device is connected:
```text
List of devices attached
RFCW10XXXXX    device
```

If the device shows `unauthorized`, unlock the phone and tap **"Always allow from this computer"** on the RSA prompt.

---

## 2. Release Artifact Verification & Build

### 2.1 Verify Existing Built Artifacts
Verify the optimized ARM64 test APK on disk:
```powershell
Get-Item "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" | Select-Object Name, Length, LastWriteTime
```

*Expected Size*: ~68.2 MB (71,534,602 bytes).

### 2.2 Rebuild Command (If artifact is missing or code changed)
```powershell
flutter build apk --release --split-per-abi
```
> [!NOTE]
> `--split-per-abi` generates ABI-specific release APKs (`app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk`, `app-x86_64-release.apk`), reducing APK download size by over 57% compared to the 160MB universal fat APK.

---

## 3. Installation on Connected Device

Install the optimized ARM64 release APK with the `-r` (replace existing application) flag:
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
```

If installing fails due to signature mismatch from a previous debug build, uninstall the previous version first:
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" uninstall in.udyogasethu.udyogasethu
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
```

---

## 4. Launching the App & Collecting Sanitized Logs

### 4.1 Launch Application via ADB
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell monkey -p in.udyogasethu.udyogasethu -c android.intent.category.LAUNCHER 1
```

### 4.2 Clear Previous Logs and Stream Live Logs
Before running tests, clear logcat buffers:
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" logcat -c
```

Stream logs filtered for UdyogaSethu, voice pipeline, and Flutter engine:
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" logcat | findstr /i "udyoga voice flutter flutter_tts"
```

### 4.3 Save Sanitized Session Logs to File
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" logcat -d | findstr /i "udyoga voice flutter" > "docs\device_test_run.log"
```

> [!SECURITY]
> Verify that no Bearer tokens, passwords, Supabase service-role keys, or raw phone numbers appear in `device_test_run.log`.

---

## 5. Checking Android Runtime Permissions

Inspect granted/denied permission state for the UdyogaSethu package:
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell dumpsys package in.udyogasethu.udyogasethu | findstr /i "RECORD_AUDIO CAMERA ACCESS_FINE_LOCATION POST_NOTIFICATIONS"
```

### 5.1 Simulate Permission Grant / Revoke via ADB
To test TC-PERM-01 and TC-PERM-02 reproducibly without reinstalling:

```powershell
# Revoke Microphone Permission
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell pm revoke in.udyogasethu.udyogasethu android.permission.RECORD_AUDIO

# Grant Microphone Permission
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell pm grant in.udyogasethu.udyogasethu android.permission.RECORD_AUDIO

# Revoke Camera Permission
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell pm revoke in.udyogasethu.udyogasethu android.permission.CAMERA

# Revoke Location Permission
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell pm revoke in.udyogasethu.udyogasethu android.permission.ACCESS_FINE_LOCATION
```

---

## 6. Simulating Interruptions & Hardware Events

### 6.1 Simulate App Backgrounding & Resumption
```powershell
# Send app to background (Press Home button)
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell input keyevent KEYCODE_HOME

# Return app to foreground
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell monkey -p in.udyogasethu.udyogasethu -c android.intent.category.LAUNCHER 1
```

### 6.2 Simulate Screen Lock & Unlock
```powershell
# Toggle Screen Power (Locks screen)
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell input keyevent KEYCODE_POWER

# Unlock screen
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell input keyevent KEYCODE_WAKEUP
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell wm dismiss-keyguard
```

### 6.3 Simulate Process Kill (Crash Recovery Test)
```powershell
# Force stop application
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell am force-stop in.udyogasethu.udyogasethu

# Cold start application
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell monkey -p in.udyogasethu.udyogasethu -c android.intent.category.LAUNCHER 1
```

---

## 7. Failure Reproduction & Documentation Workflow

When a physical device test fails:

1. **Capture Device Screenshot**:
   ```powershell
   & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell screencap -p /sdcard/failure.png
   & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" pull /sdcard/failure.png docs/failure_tc_xx.png
   & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell rm /sdcard/failure.png
   ```

2. **Capture Full Logcat Dump with Timestamp**:
   ```powershell
   & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" logcat -d -v time > docs/failure_logcat_tc_xx.txt
   ```

3. **Record in `docs/ANDROID_RELEASE_CHECKLIST.md`**:
   - Update `Status` to `FAIL`
   - Record exact device model, Android OS version, and failure notes.

---

## 8. Automated Re-Validation Suite

Before deploying fixes or preparing subsequent test builds, re-run local automated validation:

```powershell
# 1. Static Analysis (Zero Warnings)
flutter analyze

# 2. Localization Key Parity Check
dart run tool/check_l10n.dart

# 3. Secret & Credential Scanning
dart run tool/secret_scan.dart

# 4. Voice Assistant UI & Failure Handling Tests
flutter test test/voice_assistant_ui_redesign_test.dart

# 5. Multilingual Voice Matrix & Pipeline Tests
flutter test test/voice_multilingual_matrix_test.dart
flutter test test/voice_multilingual_pipeline_test.dart
flutter test test/voice_navigation_aliases_test.dart

# 6. Zero Overflow Suite across 320-600dp and 1.0-2.0x text scale
tool\check_overflow.bat
```
