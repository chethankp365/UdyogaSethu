# UI State & Quality Assurance Audit Checklist (P10.2)

This document records the state audit across all functional modules in UdyogaSethu. Every screen has been audited for **Loading**, **Empty**, **Error with Retry**, **Offline Handling**, and **Submission Feedback** (disabling buttons to prevent accidental double-submits).

---

## Audit Matrix by Module

| Module & Screen | Route | Loading State | Empty State | Error & Retry | Offline Handling | Duplicate Submission Guard |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Auth: Mobile Login** | `/login` | Button spinner (`isLoading`) | N/A | Error banner with localized message | Blocked with offline exception | Button disabled while `isLoading` |
| **Auth: OTP Verification** | `/auth/otp` | Circular indicator on verify | N/A | Inline message with resend countdown | Live network required | Verify disabled until 6 digits entered |
| **Seeker: Home Feed** | `/seeker/home` | Shimmer skeleton cards | Location-empty card with Area Picker CTA | Error banner with "Try Again" button | Shows cached jobs with top offline banner | Pull-to-refresh disabled while syncing |
| **Seeker: Jobs Discovery** | `/seeker/jobs` | Shimmer list loading | "No jobs in your area" with category reset | Retry icon button in header | Displays cached job summaries | Apply button shows "Submitting..." & locks |
| **Execution: QR Ticket** | `/execution/ticket/:id` | Circular loader while token rotates | "No active ticket" placeholder | Token expired / invalid banner with refresh | Warning banner; QR attendance requires live server | Scan & check-in buttons lock on tap |
| **Execution: Active Job Timer** | `/execution/active/:id` | Spinner on status check | "Job not found" back action | Error dialog with safety call | Timer runs locally; completion requires server | "Complete Job" confirms and locks button |
| **Provider: Home Hub** | `/provider/home` | Shimmer worker cards | "No workers found" with filters CTA | Retry banner | Shows cached bookings with offline notice | Post job shortcut locks during transition |
| **Provider: Post Job Wizard** | `/provider/jobs/new` | Step transition spinners | N/A (Form input) | Form validation errors per field | Post submission blocked offline | "Post Job" button disables on submit |
| **Provider: Guided Booking** | `/booking/guided` | Wage calculation spinner | N/A | Pricing fallback with retry | Booking creation blocked offline | "Hold Escrow & Book" disabled while charging |
| **Farmer: Home & Mandi** | `/farmer/home` | Mandi price shimmer cards | "No mandi rates today" with manual input | Retry button on mandi fetch | Mandi cards show cached prices with timestamp | Quick actions disable during requests |
| **Farmer: Produce Listings** | `/farmer/listings` | Grid shimmer placeholders | "No active listings" with "Add Produce" CTA | Error tile with retry action | Cached inventory displayed read-only | "Save Listing" disables during upload |
| **Farmer: Order Board** | `/farmer/orders` | 4-tab Kanban shimmer | Empty tab state per stage (Incoming, Packing) | Error banner with refresh | Orders cached; status transitions require live sync | "Accept Order" & "Verify PIN" lock on tap |
| **Marketplace: Produce Browsing** | `/farmer/market` | Grid cards shimmer | "No sellers near you" with distance expander | Error tile with retry | Cached listings displayed | "Add to Cart" provides haptic & quantity lock |
| **Marketplace: Cart & Checkout** | `/cart` | Subtotal recalculation spinner | "Cart is empty" with "Explore Produce" CTA | Minimum order or slot error alerts | Checkout blocked while offline | "Place Order" button disables on click |
| **Marketplace: Order Tracking** | `/orders/tracking/:id` | Live status timeline skeleton | Order not found error card | Error banner with refresh | Last synced milestone shown with offline badge | "Confirm Delivery" locks and releases escrow |
| **Marketplace: Subscriptions & Bulk** | `/farmer/subscriptions` | Group order progress shimmer | "No active group orders" with Create CTA | Error card with retry | Cached groups shown; joining requires live sync | "Join Group Order" locks on submit |
| **Wallet: Ledger & Escrow** | `/wallet` | Balance card shimmer | "No transactions yet" with first-job tip | Retry action button | Balance marked "Last synced"; cashout blocked | "Withdraw" & "Add Money" disabled on submit |
| **Chat: Protected Inbox** | `/seeker/chat` | Message threads shimmer | "No messages yet" with contact hints | Error banner with retry | Cached messages readable; sending queued | Send button disables during encryption |
| **Safety: Emergency SOS Hub** | `/safety/hub` | Immediate UI response (no spinner delay) | N/A | Fallback to direct phone dialer (112) | Offline triggers native emergency SMS / 112 | Rate-limited to max 3 triggers/hour |
| **Safety: Job Protection Claim** | `/safety/claims` | Eligibility check spinner | Checklist with missing requirements | Error notice with contact safety team | Claims require live server verification | "Submit Claim" disabled during upload |
| **Gamification: Rewards Hub** | `/rewards` | XP progress shimmer | "Starter Level" default state | Retry banner | Cached XP displayed | Referral code copying shows instant snackbar |
| **Rewards: Merchandise Store** | `/rewards/store` | Item catalog shimmer | "No items in stock" | Error banner with retry | Store requires live stock check | "Redeem Now" locks with atomic row lock |
| **Community: Local Trust Wall** | `/community` | Trust index calculation loader | "No community posts in this panchayat" | Error card with retry | Cached posts displayed | "Register Interest" updates to "Registered ✓" |
| **Learning: Micro-Courses Hub** | `/learning` | Modules ribbon loader | "No credentials earned yet" | Error card with retry | Downloaded course text accessible offline | Quiz submit disables while scoring |
| **Account: Settings & Accessibility**| `/settings` | Immediate switch toggle | N/A | Persistence error alert | Settings saved to local SharedPreferences | Toggles respond with haptic feedback |
| **Account: Credit Readiness** | `/credit-readiness` | 4 pillars calculation loader | "Building profile" state for new accounts | Error tile with retry | Offline fallback profile with disclaimer | Refresh button disables during calculation |
| **Account: Wellness & Benefits** | `/wellness` | Government schemes list loader | "No schemes matching filter" | Error banner with retry | Core schemes cached offline | Call helpline buttons open native dialer |
| **Trust: Favourites & Circles** | `/favourites` | Worker cards shimmer | "No favourite workers saved yet" | Retry button | Cached favorites shown; booking requires live | Remove favorite locks during action |
| **Evaluator: Demo Launcher** | `/demo` | State loading spinner | N/A | Error snackbar with retry | Offline fallback with local demo reset | "Reset Demo" disables and shows spinner |

---

## Critical Invariants Enforced

1. **Live Server Authoritative Validation**:
   - Monetary transactions (wallet withdrawals, UPI transfers, escrow holds/releases).
   - QR attendance ticket check-in and scan verification.
   - Biometric presence validation (worker face verification).
   *These actions are strictly blocked while offline and throw `BlockedOfflineActionException`.*

2. **No False Success Fallbacks**:
   - When an API call fails, the UI surfaces an honest error message with an actionable Retry button. The app never pretends an action succeeded when the backend rejected it.

3. **Double-Action Prevention**:
   - All stateful mutative buttons (e.g. `Place Order`, `Post Job`, `Accept Application`, `Confirm Delivery`, `Submit Dispute`, `Redeem Reward`) disable immediately upon press and display a circular progress spinner until the server responds.

4. **Honest Simulation Transparency**:
   - All simulated modules (Job Protection Claims, UPI Scan test mode, Demo Accounts) display prominent amber "Demo mode" alerts.
