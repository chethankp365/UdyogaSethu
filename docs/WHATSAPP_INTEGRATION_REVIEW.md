# WhatsApp Integration Architecture & Security Review

**Project Evaluated:** [OpenWA](https://github.com/rmyndharis/OpenWA) vs. Official WhatsApp Business Cloud API  
**Evaluation Scope:** Outbound transactional notifications (Job alerts, booking confirmations, escrow deposits, and produce orders) for UdyogaSethu (`in.udyogasethu`).  
**Auditor Roles:** Senior Backend/DevOps Engineer, Application Security Auditor, Compliance Officer.  
**Date:** October 2026  
**Final Verdict:**  
- **OpenWA:** **REJECTED FOR PRODUCTION** (High account-ban risk, reverse-engineered Web client, brittle session state). Permitted only as an offline research spike.  
- **Official WhatsApp Business Cloud API:** **APPROVED AS PRODUCTION STANDARD** (Full Meta SLA, pre-approved HSM templates, regulatory compliance, DPDP Act & opt-in consent support).

---

## 1. Executive Summary

UdyogaSethu delivers mission-critical notifications to blue-collar workers, rural farmers, and urban employers across India. Notifications include booking acceptances, OTP/QR tickets, payment confirmations, and escrow milestone releases.

This review contrasts **OpenWA** (an unofficial automation wrapper built on reverse-engineered WhatsApp Web protocols) against the **Official WhatsApp Business Platform (Cloud API)** managed by Meta.

### Primary Decision
- **Production Standard:** The platform will strictly use the **Official WhatsApp Business Platform (Cloud API)** via server-side Supabase Edge Functions (`whatsapp-notify`).
- **OpenWA Demarcation:** OpenWA **must never** be connected to real user phone numbers or production communication queues. Its reliance on headless browser Puppeteer/Baileys sessions violates WhatsApp Terms of Service and guarantees account suspension.

---

## 2. Comparative Analysis: OpenWA vs. Official WhatsApp Cloud API

| Evaluation Criteria | OpenWA (Unofficial / Reverse-Engineered) | Official WhatsApp Business Cloud API |
|---|---|---|
| **Underlying Protocol** | Reverse-engineered WhatsApp Web client (`baileys` / `whatsapp-web.js` over WebSocket). | Direct REST HTTPS Meta Graph API (`v20.0`). |
| **Account Ban & Suspension Risk** | **EXTREMELY HIGH**. Meta actively detects and terminates non-official web clients sending automated messages. | **ZERO RISK**. Official authorized business phone number verified by Meta. |
| **Session & Auth Stability** | **Brittle**. Requires scanning QR code from a physical phone. Session keys expire or disconnect if the phone reboots, disconnects, or updates. | **Permanent & Cloud-Hosted**. Uses system-user Bearer tokens (`WHATSAPP_CLOUD_API_TOKEN`) with high availability SLA. |
| **Throughput & Rate Limits** | Unofficial throttling; sending > 50 messages/hour frequently flags the account as spam. | Tiered scaling: 1,000 to 100,000+ business-initiated conversations per 24 hours. |
| **Message Templates & Delivery** | Freeform text only (no verified HSM templates). Leads to user blocking and spam reports. | Pre-approved bilingual HSM templates in English, Kannada, Hindi, Telugu, Tamil, Marathi, Bengali, and Odia. |
| **Security & Privacy** | Session credentials, message history, and authentication blobs stored on a self-hosted server filesystem. | End-to-end transport encryption over TLS 1.3, SOC2 compliant infrastructure, no intermediate scraping. |
| **Cost & Pricing** | Free software, but high operational cost (host phone hardware, proxy IPs, constant re-authentication). | Pay-per-conversation utility pricing (Meta charges ~₹0.30 to ₹0.40 per utility template in India). |

---

## 3. Production Notification Architecture (Official Cloud API)

### 3.1 Design Invariants
1. **Triggered Exclusively by Trusted Backend Events:**
   - Notifications are dispatched **only** by database triggers or verified Edge Functions (e.g. `payment-webhook`, `release_assignment_escrow`, `post_job`).
   - A mobile client can **never** trigger a WhatsApp message directly via client-supplied arguments.
2. **Opt-In & Consent Compliance:**
   - In accordance with the Digital Personal Data Protection (DPDP) Act and Meta Messaging Policies, notifications require prior explicit consent stored in `public.consent_logs` (purpose: `whatsapp_notifications`).
   - Users can opt out anytime from their Account / Privacy Settings (`whatsappNotifyOptIn: false`).
3. **Sensitive Data Protection:**
   - Notification previews must **never** include sensitive financial details, passwords, full bank account numbers, or unmasked phone numbers.
   - Messages link back to the native app: e.g. *"Your job booking is confirmed! Open UdyogaSethu to view details: https://udyogasethu.in/jobs/active/..."*.
4. **Native Chat Separation:**
   - In-app chat (via Supabase Realtime) remains the **primary native user-to-user communication system**.
   - WhatsApp is used strictly for asynchronous one-way transactional alerts and reminders, never as a duplicate conversational thread.

---

## 4. Supported Transactional Events & Template Specifications

| Event | Template Name | Target User | Sample Content (English) |
|---|---|---|---|
| **Booking Confirmed** | `job_booking_confirmed_v1` | Worker & Employer | *"Namaste {{1}}, your booking for {{2}} on {{3}} has been confirmed. Open UdyogaSethu to view site address."* |
| **Escrow Deposited** | `escrow_deposit_success_v1` | Worker | *"Good news {{1}}! Employer {{2}} has deposited {{3}} into secure escrow for your job. Payment is guaranteed upon completion."* |
| **Escrow Released** | `escrow_payout_released_v1` | Worker | *"Payment of {{1}} has been transferred to your UdyogaSethu Wallet. Thank you for your hard work!"* |
| **Produce Order Shipped** | `produce_order_shipped_v1` | Buyer | *"Your order of {{1}} from Farmer {{2}} has been dispatched. Expected delivery: {{3}}."* |

---

## 5. Security & Secret Management

- **Required Secrets (Configured strictly in Supabase Vault / Edge Function Secrets):**
  - `WHATSAPP_CLOUD_API_TOKEN`: System-user permanent access token from Meta Business Manager.
  - `WHATSAPP_PHONE_NUMBER_ID`: Unique phone number ID assigned by Meta Graph API.
  - `WHATSAPP_WEBHOOK_VERIFY_TOKEN`: Random 32-character secret for webhook verification.
- **Client Zero-Knowledge:**
  - Neither Flutter nor client-side network inspectors ever receive or transmit WhatsApp API tokens.

---

## 6. Implementation Summary & Release Recommendation

1. **Edge Function:** Created `supabase/functions/whatsapp-notify/index.ts` supporting standard Meta Graph API v20.0 dispatch, with built-in sandbox mock mode when running in local development or without configured secrets.
2. **Preferences UI:** Added a localized WhatsApp notification toggle in User Settings / Privacy Centre.
3. **Verdict:** OpenWA is safely quarantined as an unapproved research prototype; production notifications adhere strictly to Meta's Business Cloud API standards.
