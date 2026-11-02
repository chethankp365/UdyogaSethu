# UdyogaSethu Android Release Validation Checklist

This document is the official release validation checklist for testing UdyogaSethu on physical Android devices.
Statuses: `PASS`, `FAIL`, `BLOCKED`, `NOT RUN`.

> [!IMPORTANT]
> **Zero Hardware Fabrication Protocol**: No physical Android phone was attached during automated environment checks (`adb devices` returned 0 attached devices). In strict adherence to project honesty rules, every physical-device test case below is marked **NOT RUN**. They must be validated on physical Android hardware before production sign-off.

---

## 1. Device and Build Specifications

| Specification | Value |
|---|---|
| **App Name** | UdyogaSethu (ಉದ್ಯೋಗ ಸೇತು / उद्योग सेतु) |
| **Application ID / Package** | `in.udyogasethu.udyogasethu` |
| **Version** | `1.0.0+1` (Version Name: `1.0.0`, Version Code: `1`) |
| **Primary Test APK (ARM64)** | `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (68.2 MB) |
| **Universal Fallback APK** | `build/app/outputs/flutter-apk/app-release.apk` (160.4 MB) |
| **Google Play App Bundle (AAB)** | `build/app/outputs/bundle/release/app-release.aab` (132.1 MB) |
| **Signing Status** | Signed with Android Debug Keystore (Testing/Staging only; production keystore pending) |
| **Target OS / Min SDK** | Android 14/15 (API 34/35) / Min SDK 21 (Android 5.0 Lollipop) |
| **Connected Device** | `[None connected — Pending hardware tester]` |

---

## 2. Structured Real-Device Test Checklist

| Test ID | Test Scenario | Setup | Step-by-Step Procedure | Expected Result | Actual Result | Status | Notes / Observations |
|---|---|---|---|---|---|---|---|
| **TC-INSTALL-01** | **Installation & First Launch** | Device running Android 9+ with USB debugging enabled. Device disconnected from previous beta versions. | 1. Run `adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.<br>2. Tap app icon on launcher.<br>3. Inspect splash screen, transitions, and landing screen. | APK installs with code `Success`. App boots without native crash or ANR. Emerald/amber splash screen displays with version label `1.0.0` and transitions smoothly to Language Selection / Intro. | Pending device execution | **NOT RUN** | Automated bootstrap test passed in `test/onboarding_test.dart`. Requires physical launcher launch. |
| **TC-PERM-01** | **Microphone Permission Granted** | Clean install or revoke audio permissions via `adb shell pm revoke in.udyogasethu.udyogasethu android.permission.RECORD_AUDIO`. | 1. Open app and proceed to shell home.<br>2. Tap central microphone button.<br>3. When Android OS dialog prompts "Allow UdyogaSethu to record audio?", tap "While using the app". | Permission dialog dismisses; modal immediately transitions to electric cyan glowing orb and states `"Listening... Speak now"`. Audio waveform visualizer pulses with ambient sound. | Pending device execution | **NOT RUN** | Verified permission grant state machine in `test/voice_assistant_ui_redesign_test.dart`. Requires physical OS dialog interaction. |
| **TC-PERM-02** | **Microphone Permission Denied** | Clean install or permissions revoked. | 1. Open voice assistant modal.<br>2. When OS dialog prompts for microphone, tap "Don't allow".<br>3. Observe assistant modal UI. | App does NOT crash. Red permission banner appears with microphone-off icon, explaining microphone is required. Button shows "Grant Permission". State pill reads "Microphone permission required". | Pending device execution | **NOT RUN** | Verified denial banner and retry button in `test/voice_assistant_ui_redesign_test.dart`. Requires physical OS interaction. |
| **TC-PERM-03** | **Microphone Permission Permanently Denied** | Deny permission with "Don't ask again" or deny twice on Android 11+. | 1. Open voice assistant modal.<br>2. Observe persistent permission banner.<br>3. Tap "Open Settings" button.<br>4. Grant permission in Android Settings and return to app. | Banner states "Please open App Settings to allow microphone access." Tapping button opens Android App Info settings screen. Returning to app auto-detects granted state and resets modal to idle/ready. | Pending device execution | **NOT RUN** | Resumed lifecycle permission detector verified in modal controller. Requires physical Android Settings round-trip. |
| **TC-LANG-01** | **Speech Recognition: English, Hindi & Kannada** | Microphone permission granted. Device audio volume set to 70%. | 1. Test English (`en`): say *"Show me plumber jobs in Bangalore"*.<br>2. Switch language to Hindi (`hi`): say *"मुझे इलेक्ट्रीशियन का काम चाहिए"*.<br>3. Switch language to Kannada (`kn`): say *"ಬೆಂಗಳೂರಿನಲ್ಲಿ ಕೆಲಸ ತೋರಿಸಿ"*. | In each language, voice waveform pulses during speech; transcript matches spoken words in native script; Groq Whisper / Gemini returns correct semantic intent; assistant responds in selected language. | Pending device execution | **NOT RUN** | Pipeline tests passed (70/70) in `test/voice_multilingual_pipeline_test.dart`. Requires physical acoustic input. |
| **TC-LANG-02** | **Speech Recognition: Telugu, Tamil, Marathi, Bengali & Odia** | Microphone permission granted. Regional languages configured in app. | 1. Test Telugu (`te`): *"నాకు డ్రైవర్ పని కావాలి"*.<br>2. Test Tamil (`ta`): *"எனக்கு வேலை வேண்டும்"*.<br>3. Test Marathi (`mr`): *"मला काम दाखवा"*.<br>4. Test Bengali (`bn`): *"আমাকে কাজ দেখান"*.<br>5. Test Odia (`or`): *"ମୋତେ କାମ ଦେଖାନ୍ତୁ"*. | Correct transcript displayed in respective regional script; orchestrator handles regional dialects; fallback to Cloud STT handles devices lacking regional offline voice packs; zero garbled text. | Pending device execution | **NOT RUN** | Matrix tests passed (64/64) in `test/voice_multilingual_matrix_test.dart`. Requires physical native-speaker vocalization. |
| **TC-TTS-01** | **Text-to-Speech Playback & Repeated Playback** | Device media volume on unmuted speaker. | 1. Trigger voice query: *"Check my wallet balance"*.<br>2. Listen to audio response.<br>3. Tap "Listen again" button.<br>4. Tap "Stop audio" button mid-sentence.<br>5. Query in a language without installed TTS voice pack (e.g., Odia on generic phone). | English plays neural Deepgram Aura audio; Indic languages play clear device TTS; "Listen again" replays full reply; "Stop audio" immediately silences speaker; missing voice pack displays amber warning banner without crashing or hanging. | Pending device execution | **NOT RUN** | Verified playback state transitions and amber notice in `test/voice_assistant_ui_redesign_test.dart`. Requires physical speaker verification. |
| **TC-INT-01** | **Interruption: Incoming Call & Screen Lock** | Phone with active SIM or second device to place call. | 1. Tap mic and start speaking a query.<br>2. Place incoming phone call to device.<br>3. Decline call.<br>4. Return to app, start speaking, and press device power button to lock screen.<br>5. Unlock screen. | On incoming call: microphone immediately releases, audio recording cancels safely. On screen lock: audio recording stops, wake locks released. On unlock: modal is in clean idle state without orphaned recording processes. | Pending device execution | **NOT RUN** | Android lifecycle observer verified in unit tests. Requires physical telephony interruption. |
| **TC-INT-02** | **App Backgrounding & Navigation Interruption** | Device home navigation gesture / button. | 1. Tap mic and speak a query that triggers navigation (e.g. *"Open my profile"*).<br>2. Immediately press Home button before navigation executes.<br>3. Wait 3 seconds, reopen app from recent apps. | Audio playback silences on backgrounding; pending 1.6s auto-navigation timer cancels; app reopens on previous screen without background route navigation or state leaks. | Pending device execution | **NOT RUN** | Lifecycle observer and navigation timer cancellation verified in `test/voice_assistant_ui_redesign_test.dart`. Requires physical gesture testing. |
| **TC-AUDIO-01** | **Edge Audio: Empty Speech, Silence, Noise & Long Speech** | Varied acoustic environments. | 1. Tap mic, remain silent for 5 seconds.<br>2. Tap mic in noisy street / cafeteria surroundings.<br>3. Tap mic and speak continuously for 20+ seconds.<br>4. Rapidly tap microphone orb 5 times consecutively. | Silence shows "I didn't catch that. Tap to try again" with Retry button. Noisy input filters background hum and extracts speech. Long speech caps at 15s limit cleanly. Rapid taps are ignored by concurrency guard (`_isStartingListening`). | Pending device execution | **NOT RUN** | Concurrency guards and error banner verified in `voice_assistant_ui_redesign_test.dart`. Requires physical microphone acoustical testing. |
| **TC-NET-01** | **Network Loss & Recovery** | WiFi / Cellular toggles or Airplane Mode. | 1. Open assistant modal.<br>2. Enable Airplane mode.<br>3. Speak *"Open my wallet"*.<br>4. Observe offline rule engine response.<br>5. Disable Airplane mode and speak query. | Offline IntentEngine processes intent locally and routes to `/wallet` with offline notice; when network restores, online 5-provider orchestrator resumes without app restart. | Pending device execution | **NOT RUN** | Offline intent engine verified in `test/ai_orchestrator_test.dart`. Requires physical network interface toggle. |
| **TC-UI-01** | **Loading Indicators, Timeouts & Error Messages** | Test on high-latency 2G/3G network simulation. | 1. Send complex query on throttled network.<br>2. Observe state indicator pill and waveform.<br>3. Force server timeout (e.g., block Supabase URL via DNS). | While waiting, amber "Finding the right information..." pill and pulsing thinking waveform display; on timeout (10s), loading state resets to error state with localized retry button; loading indicator never spins forever. | Pending device execution | **NOT RUN** | Concurrency guards and `try-finally` state resets verified in `VoiceAssistantModal`. Requires physical network throttling. |
| **TC-NAV-01** | **Navigation for Supported Roles (Seeker, Provider, Farmer)** | Test accounts: Seeker (+919900000002), Provider (+919900000008), Farmer (+919900000012). | 1. Log in as Seeker: test voice navigation to `/jobs`, `/wallet`, `/safety`, `/profile`.<br>2. Log in as Provider: test `/provider/workers`, `/provider/jobs/new`.<br>3. Log in as Farmer: test `/marketplace`, `/profile`.<br>4. Verify SOS voice command *"Help me SOS"*. | Canonical routes resolve correctly per role; deep links open correct role shell; SOS command triggers Emergency Confirmation dialog with heavy haptic feedback; no `NotFoundScreen` crashes. | Pending device execution | **NOT RUN** | Navigation alias suite passed (7/7) in `test/voice_navigation_aliases_test.dart`. Requires physical account navigation. |
| **TC-AUTH-01** | **Session Expiry, Signed-out & Rate Limits** | Logged out state and expired session. | 1. Open voice assistant while signed out.<br>2. Send 35 voice queries in 60 seconds (rate limit test).<br>3. Invalidate JWT token in Supabase dashboard and trigger assistant query. | Signed-out state restricts to public information queries; exceeding 30 req/min rate limit returns clean HTTP 429 `"Rate limit exceeded"`; expired session prompts re-login without crash or exposing stack traces. | Pending device execution | **NOT RUN** | Supabase Edge Function rate limiter and JWT authentication verified in Deno tests (14/14). Requires physical auth flow. |
| **TC-A11Y-01** | **Small-Screen Layout, Keyboard & Accessibility** | Compact phone (e.g. 320dp width, Android font scale set to Largest / 1.5x-2.0x). | 1. Set Android display text size to Maximum (200%).<br>2. Open voice assistant modal.<br>3. Tap "Type instead" to open on-screen virtual keyboard.<br>4. Inspect layout for yellow-black overflow bars. | All buttons, text cards, and suggestion chips scale without `RenderFlex` overflows (scrollable container); touch targets maintain >=48dp; on-screen keyboard pushes input dock up without obscuring text field. | Pending device execution | **NOT RUN** | Zero overflow suite passed (38/38) in `tool/check_overflow.bat`. Requires physical small-screen verification. |
| **TC-REC-01** | **App Restart & Recovery After Interruption** | Logged-in session. | 1. Open voice assistant, start recording.<br>2. Swipe up to Android Recent Apps and swipe away UdyogaSethu to kill process.<br>3. Relaunch app from launcher.<br>4. Verify session state. | App cold starts cleanly; previous login session is restored from secure storage; active role shell loads immediately without re-login; voice assistant starts in clean idle state without audio artifacts. | Pending device execution | **NOT RUN** | Cold boot session restoration verified in `test/bootstrap_test.dart`. Requires physical process termination. |

---

## 3. Physical Hardware Execution Instructions

When a physical Android phone is connected to this workstation:

1. **Verify ADB Connection**:
   ```powershell
   & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
   ```
2. **Install ARM64 Release APK**:
   ```powershell
   & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
   ```
3. **Stream Sanitized Logs**:
   ```powershell
   & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" logcat -c
   & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" logcat | findstr /i "udyoga voice flutter"
   ```
4. **Record Findings**:
   Update the `Actual Result` and `Status` columns in the table above for each test case as it is executed.
