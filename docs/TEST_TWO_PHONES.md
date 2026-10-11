# Two-Phone End-to-End Testing Script: Real QR Ticket Flow

This document provides a complete, step-by-step testing script for verifying the real end-to-end QR ticket attendance and verification lifecycle across two devices.

---

## 1. Setup & Device Roles

| Role | Device / Window | Account Type | Screen / Entrypoint |
|---|---|---|---|
| **Phone A** | Device 1 (Mobile / Emulator A) | **Job Seeker** (`worker`) | `/jobs/ticket/:assignmentId` or `/seeker/digital-id` |
| **Phone B** | Device 2 (Mobile / Emulator B) | **Job Provider** (`provider`) | `/jobs/scan/:assignmentId` |

> **Note**: Both devices must be connected to the same Supabase project instance with Realtime enabled on `job_assignments` and `assignment_events`.

---

## 2. Happy Path Flow (Two Phones End-to-End)

### Step 1: Offer Acceptance & Ticket Issuance
1. **Phone B (Provider)** accepts the seeker's application for a scheduled job.
2. Server triggers ticket issuance:
   - `job_assignments.status` moves to `'ticket_issued'`.
   - Event `'ticket_issued'` is appended to `assignment_events`.
   - Admin settings define validity window (`ticket_valid_before_minutes`: 60, `ticket_valid_after_minutes`: 120).

### Step 2: Seeker Opens Ticket
1. **Phone A (Seeker)** opens either:
   - The Job Ticket screen: `/jobs/ticket/<assignment_id>`
   - Or the Digital ID card: `/seeker/digital-id` (which automatically selects the earliest upcoming accepted job ticket).
2. **Observe on Phone A**:
   - Ticket card displays: Booking Code (e.g., `#BOOK-1042`), Job Title, Wage, Start Time, and Employer Name.
   - Dynamic rotating QR code renders with live countdown (120 seconds).
   - "Rotating QR • Auto-refreshes in Xs" indicator pulses.
   - Offline banner is **NOT** visible while online.

### Step 3: Provider Scans Seeker's QR
1. **Phone B (Provider)** taps **"Scan Attendance QR"** (`/jobs/scan/<assignment_id>`).
2. Real camera viewport opens with target overlay and torch toggle.
3. Aim Phone B's camera at Phone A's rotating QR code.
4. **Observe on Phone B**:
   - Scanner invokes atomic `verify_ticket_scan` RPC / `qr-verify` Edge Function with `jobId`.
   - Audio beep / vibration confirms scan.
   - Success modal appears displaying:
     - Worker Name & Avatar Photo
     - Verified Badge (`is_verified_badge: true`)
     - Job Title confirmation
     - Green banner: *"Attendance Verified — Ready for Step 2"*

### Step 4: Realtime Seeker Phone Transition
1. **Observe on Phone A (Seeker)** without any manual refresh:
   - Realtime listener on `job_assignments` triggers immediately upon provider's scan.
   - SnackBar appears: **"Verified by employer! Opening workplace selfie..."**
   - Automatically navigates to **Step 2: Workplace Presence Verification** (`/jobs/verify-presence/<assignment_id>`).
   - If user stays on ticket screen, green banner shows *"Verified by employer! Ready for workplace selfie & GPS"*.

### Step 5: Step 2 Live Workplace Selfie & GPS Geofence
1. **On Phone A (Seeker)**:
   - App acquires current GPS coordinates.
   - App checks distance against the workplace location (must be within 150m geofence).
   - Seeker snaps a live front-camera selfie with workplace in the background.
   - App evaluates image brightness (rejects if too dark, with retry).
   - Face embedding is extracted and verified via server `face-verify` function against enrolled identity template.
   - Photo is securely uploaded to private storage bucket `job-evidence`.
   - Atomic RPC `record_step2_verification` commits the verification:
     - Sets `job_assignments.status` = `'in_progress_verified'`.
     - Appends `selfie_gps_verified` and `job_started` to `assignment_events`.
     - Sets `started_at` = `NOW()`.

### Step 6: Job Started & Timer Synchronization
1. **Observe on Phone A (Seeker)**:
   - Navigates to `/jobs/active/<assignment_id>`.
   - Work Timer starts ticking in real time with server-authoritative timestamp.
2. **Observe on Phone B (Provider)**:
   - Active Job screen and Assignment Timeline update in real time.
   - Stage moves to **"Job In Progress / Started"**.

---

## 3. Negative & Security Edge-Case Test Scenarios

### Scenario A: Simultaneous Double Scan (Race Safety)
* **Goal**: Ensure two simultaneous scans can never double-activate a ticket.
* **Steps**:
  1. Have two scanners (or duplicate scan requests) scan the same valid ticket QR simultaneously within 50ms.
  2. **Expected Result**:
     - Exactly **one** scan succeeds and transitions status to `arrived`.
     - The second scan fails atomically with rejection code:
       `ALREADY_USED` (`"Already scanned at hh:mm"`).

### Scenario B: Expired Rotating QR Token
* **Goal**: Ensure stale or screenshot-shared QR tokens are rejected.
* **Steps**:
  1. On Phone A, let the 120-second countdown expire (or in Dev Menu `/dev/lifecycle`, tap **"Set Short TTL (15s)"**).
  2. Take a screenshot of the old QR code before it refreshes.
  3. Scan the screenshot after 120s (or 15s in test mode).
  4. **Expected Result**:
     - Scanner displays red rejection banner:
       `EXPIRED` (`"QR expired at hh:mm, ask the worker to refresh"`).
     - Network/server errors are handled separately with Retry.

### Scenario C: Wrong Employer Scan
* **Goal**: Prevent an unauthorized provider from claiming another employer's worker.
* **Steps**:
  1. Log into Phone B with a Provider account that does **NOT** own the job assignment.
  2. Attempt to scan Phone A's QR ticket.
  3. **Expected Result**:
     - Scanner rejects scan with code:
       `WRONG_EMPLOYER` (`"This ticket belongs to a different employer"`).
     - Assignment remains in `ticket_issued` status.

### Scenario D: Wrong Job Scan
* **Goal**: Prevent scanning a worker into Job A when they were assigned to Job B.
* **Steps**:
  1. Provider opens scanner configured with `job_id = JobA`.
  2. Worker presents ticket for `job_id = JobB`.
  3. **Expected Result**:
     - Scanner rejects with code:
       `WRONG_JOB` (`"This ticket is for a different job assignment"`).

### Scenario E: Tampered QR Code
* **Goal**: Prevent token forgery and payload manipulation.
* **Steps**:
  1. Generate or edit a QR code containing an altered payload or invalid HMAC signature.
  2. Scan with Phone B.
  3. **Expected Result**:
     - Scanner rejects with code:
       `TAMPERED` (`"Invalid or forged QR token signature"`).

### Scenario F: Outside Geofence (Step 2)
* **Goal**: Prevent remote check-in outside workplace boundaries.
* **Steps**:
  1. Complete Step 1 scan.
  2. On Phone A, trigger Step 2 with GPS location > 150m from job address.
  3. **Expected Result**:
     - Refusal bottom sheet displays:
       `OUTSIDE_GEOFENCE` (`"Outside the site geofence by X m (Y m away, limit 150 m)"`).
     - Assignment does not advance to `in_progress_verified`.

### Scenario G: Three Fails Manual Review Rule
* **Goal**: Prevent endless retries and flag fraud/impersonation for human audit.
* **Steps**:
  1. Fail Step 2 face verification or dark photo 3 times sequentially.
  2. **Expected Result**:
     - On 3rd failure:
       `MANUAL_REVIEW_REQUIRED` (`"Three failed verification attempts reached. Presence check submitted for admin manual review."`).

---

## 4. Dev Menu Verification Panel
To inspect real-time token states and force test parameters during manual testing:
1. Open `/dev/role` -> Tap **"⏱ Lifecycle Test Panel (/dev/lifecycle)"**.
2. **Features**:
   - Displays real-time assignment events stream.
   - Shows active token hash, expiry time, and live seconds remaining.
   - **"Set Short TTL (15s)"** button: instantly forces token rotation to 15 seconds.
   - Quick stage advance chips: `Accepted`, `Arrived`, `In Progress`, `Completed`.
   - One-tap health checks for `qr-issue`, `qr-verify`, and `face-verify`.
