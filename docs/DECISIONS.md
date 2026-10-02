# Architectural & Product Decisions Log

This document records key design, architectural, role model, and implementation decisions made during the development of UdyogaSethu.

| Decision ID | Summary | Status | Notes |
| ----------- | ------- | ------ | ----- |
| D1 | Job Provider = households and employers who hire workers; providers can also buy farm produce and subscriptions | Adopted | Core Role Definition |
| D2 | Seeker types: informal, student, part_time | Adopted | Seeker Classification |
| D3 | Role tree appears before login for new users; choice is stored locally then written after first sign-in | Adopted | Pre-login Role Onboarding |
| D4 | Multi-role accounts with a role switcher; seeker type can change later | Adopted | Account Flexibility |
| D5 | Admin is the same Flutter codebase, responsive, role-gated | Adopted | Unified Architecture |
| D6 | Five languages fully translated (en, kn, hi, te, ta); mr, bn, or fall back to English until P10.2 | Adopted | Multilingual Strategy |
| D7 | Riverpod without codegen, go_router, supabase_flutter | Adopted | State & Navigation Stack |
| D8 | AI = Gemini API via ai-assist | Adopted | AI Assistant Backend |
| D9 | Temporarily removed permission_handler during P0.2 scaffold to avoid Android compileSdk 37 conflict with AGP 9.1.0; will be re-added in the specific prompt/phase that needs it (e.g. Phase 3/4) | Adopted | Build Compatibility |
| D10 | Account Linking Rules: Worker or farmer accounts must always have a verified phone number. Google-first auth forces phone verification via updateUser(phone) & OTP. Phone-first auth allows linking Google in Settings via manual identity linking; duplicate Google emails across different phone numbers are blocked. | Adopted | Auth & Identity Linking |

## Technical & Simulation Decisions

*No simulation decisions recorded yet.*
