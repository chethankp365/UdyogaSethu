# UdyogaSethu UI Reference & Visual Source of Truth

This document serves as the exact visual and UI specification for all screens depicted in the reference designs (`UdyogaSetu Built Project.pdf` and `UdyogaSetu - 1.pdf` prototype slides). All Flutter screen implementations must conform strictly to the layouts, element orders, visible texts, chips, buttons, icons, colors, and theme modes listed below.

---

## Global Design Tokens & Styling Rules

* **Primary Palette**:
  * Forest/Emerald Green: `#0D6548` (Primary Headers, Dark Hero Cards, Active State Highlights)
  * Bright Teal/Green: `#00875A` / `#10B981` (Primary Action Buttons, Verified Badges, Selected Pills)
  * Pale Mint Tint: `#E6F4EA` / `#F0FDF4` (Card Backgrounds, Light Highlights, Pill Backgrounds)
  * Accent Amber/Orange: `#FF9900` / `#F59E0B` / `#E65100` (Agri Ads, Weather Alerts, Call-to-Action Highlights)
  * Safety Red/SOS: `#DC2626` / `#EF4444` (Emergency SOS Buttons, No-Show Alerts)
* **Backgrounds & Themes**:
  * **Light Theme**: Background `#F8FAFC` or `#FFFFFF`, Cards `#FFFFFF` with `#E2E8F0` border, Text Dark `#1E293B`, Text Muted `#64748B`.
  * **Dark Navy Panel Style**: Background `#0B132B` / `#0F172A`, Cards `#1E293B` or `#132238` with green/teal borders, Text `#F8FAFC`, Subtext `#94A3B8`.
* **Central Voice Button**: Floating mic button (`#00875A` / `#10B981`) anchored centrally in the bottom navigation bar across all main screens.

---

# SECTION 1: BUILT PROJECT SCREENS

## Screen 1: Splash / Landing Page 1
* **Theme**: Light Theme
* **Approximate Hex Colors**: Background `#FFFFFF`, Card Border `#A7F3D0`, Progress Orange `#F59E0B`, Text `#0F172A`.
* **Visible Texts**:
  * Header/Logo: `UDYOGA SETU`
  * Tagline: `Bridging Work. Empowering Lives.`
  * Progress Label: `Initializing UdyogaSethu...`
  * Progress Percentage: `60%`
  * Feature Pills: `AI Matching`, `Secure`, `Verified`
  * Footer: `Version 1.0.0`
* **Element Order (Top to Bottom)**:
  1. Top Status Bar (9:41, 5G)
  2. UdyogaSethu Brand Logo
  3. Main Tagline (`Bridging Work. Empowering Lives.`)
  4. Central Banner Illustration (City skyline & multi-sector Indian workers with tools)
  5. Progress Indicator Bar (60% filled orange bar on mint track)
  6. Sub-progress Label & Percentage (`Initializing UdyogaSethu... 60%`)
  7. Feature Pills Row (`AI Matching` • `Secure` • `Verified`)
  8. Version String at bottom (`Version 1.0.0`)
* **Chips / Tabs / Buttons**:
  * 3 Static Feature Pills: `AI Matching`, `Secure`, `Verified`
* **Icons**: Brand logo icon, illustration visuals.

---

## Screen 2: Onboarding / Landing Page 2
* **Theme**: Light Theme
* **Approximate Hex Colors**: Background `#FFFFFF`, Primary Button `#0D6548`, Subtitle `#64748B`.
* **Visible Texts**:
  * Skip Button: `Skip`
  * Main Headline: `Built for India. For Every Worker.`
  * Sub-headline: `Find jobs, grow skills, earn better and live with dignity.`
  * Action Card 1: `Find Jobs Near You`
  * Action Card 2: `Secure Payments`
  * Action Card 3: `AI Voice Assistant`
  * Primary Button: `Next ->`
* **Element Order (Top to Bottom)**:
  1. Top Bar: Logo (left), `Skip` button (right)
  2. Headline (`Built for India. For Every Worker.`)
  3. Sub-headline sentence
  4. Central Hero Photo (Diverse group of informal workers in uniform holding tools)
  5. 3 Column Feature Cards Grid (`Find Jobs Near You`, `Secure Payments`, `AI Voice Assistant`)
  6. Bottom Pill Action Button (`Next ->`)
* **Chips / Tabs / Buttons**:
  * `Skip` text button
  * 3 Feature Cards
  * `Next ->` primary green button
* **Icons**: Magnifying glass icon, Shield check icon, Microphone icon.

---

## Screen 3: Multilingual Support with Voice
* **Theme**: Light Theme
* **Approximate Hex Colors**: Background `#FFFFFF`, Selected Language `#00875A`, Unselected Border `#CBD5E1`.
* **Visible Texts**:
  * Title: `Choose your language`
  * Subtitle: `We will show everything in your language`
  * Language Grid:
    * `GB English` (Selected check)
    * `IN ಕನ್ನಡ (Kannada)`
    * `IN हिंदी (Hindi)`
    * `IN తెలుగు (Telugu)`
    * `IN தமிழ் (Tamil)`
    * `IN मराठी (Marathi)`
    * `IN বাংলা (Bengali)`
    * `IN ଓଡ଼ିଆ (Odia)`
  * Audio Preview Button: `► Listen to welcome in English`
  * Action Button: `Continue ->`
* **Element Order (Top to Bottom)**:
  1. Top Bar with UdyogaSethu Logo
  2. Title (`Choose your language`) & Subtitle
  3. 2-Column Grid of 8 Language Selection Cards with country/state badges & radio circles
  4. Secondary Pill Button (`► Listen to welcome in English`)
  5. Primary Green Action Button (`Continue ->`)
* **Chips / Tabs / Buttons**:
  * 8 Language selector cards (Radio buttons)
  * `► Listen to welcome in English` button
  * `Continue ->` button
* **Icons**: Country code badges (`GB`, `IN`), Radio check icon (`✓`), Play icon (`►`).

---

## Screen 4: Login Page
* **Theme**: Light Theme
* **Approximate Hex Colors**: Background `#FFFFFF`, Input Border `#E2E8F0`, Button `#0D6548`.
* **Visible Texts**:
  * Top Language Switcher Pills: `GB English`, `IN ಕನ್ನಡ`, `IN తెలుగు`, `IN हिंदी`, `IN தமிழ்`
  * Title: `Mobile Number Login`
  * Subtitle: `Enter 10-digit mobile number for instant SMS login.`
  * Input Label: `MOBILE PHONE NUMBER`
  * Country Code: `IN +91`
  * Input Value/Placeholder: `9123456789`
  * Primary Button: `Get SMS OTP Verification Code`
* **Element Order (Top to Bottom)**:
  1. Top horizontal scrolling Language Switcher Pills
  2. Title (`Mobile Number Login`) & Subtitle
  3. Phone Number Input Container (`IN +91` prefix + 10-digit input)
  4. Full-width Primary Button (`Get SMS OTP Verification Code`)
* **Chips / Tabs / Buttons**:
  * Language selector pills bar
  * `Get SMS OTP Verification Code` button
* **Icons**: Country badge icons.

---

## Screen 5: Select Account Role / Category Page
* **Theme**: Light Theme
* **Approximate Hex Colors**: Background `#FFFFFF`, Card Border Green `#A7F3D0`, Arrow `#64748B`.
* **Visible Texts**:
  * Top Language Bar: `GB English`, `IN ಕನ್ನಡ`, `IN తెలుగు`, `IN हिंदी`, `IN தமிழ்`
  * Title: `Select Account Role`
  * Subtitle: `Choose your account type to customize your dashboard & security.`
  * Role Option 1: `Informal Worker / Daily Wage Seeker` | `Find construction, delivery, plumbing jobs & instant UPI pay`
  * Role Option 2: `Farmer / Agricultural Producer` | `Sell crops directly to buyers without middleman cuts`
  * Role Option 3: `Customer / Home Service Buyer` | `Book local plumbers, maids & order fresh organic produce`
  * Role Option 4: `Employer / Site Supervisor` | `Post daily wage jobs, scan worker QR tickets & manage site`
* **Element Order (Top to Bottom)**:
  1. Top Language selector pills
  2. Title (`Select Account Role`) & Subtitle
  3. 4 Role Option Cards with distinct icons, titles, subtitles, and right chevron arrows (`>`)
* **Chips / Tabs / Buttons**:
  * 4 Selectable Role Cards
* **Icons**: Construction worker icon, Farmer icon, Shopping basket icon, Gear/Supervisor icon, Chevron right (`>`).

---

## Screen 6: Worker Home Page
* **Theme**: Light Theme with Dark Green Top Card
* **Approximate Hex Colors**: Header `#0D6548`, Goal Donut `#00875A`, Background `#F8FAFC`.
* **Visible Texts**:
  * Top Header Bar: Logo, `SOS` pill, Notification Bell, Profile Avatar
  * Greeting: `Good Morning, Chethan Kumar! 👋`
  * Location: `📍 Koramangala, Bengaluru...`
  * Search Input: `Search jobs, services...`
  * Goal Card: `Today's Goal` | `53%` | `₹800 / ₹1500`
  * Wallet Card: `Wallet Balance` | `₹3,450.00` | `View Wallet >`
  * Safety Banner: `📍 Location sharing active for safety monitoring` | `Change >`
  * Section Header: `QUICK ACTIONS`
  * Action Buttons: `Nearby Jobs`, `AI Assistant`, `Wallet`, `Safety Hub`
  * Sponsored Card: `SPONSORED` | `Kirloskar Brothers Ltd` | `Why am I seeing this? X`
  * Sponsored Product: `Kirloskar Hybrid Solar Water Pump` | `Save 30% electricity...` | `Explore Agri Offer`
  * Section Header: `RECOMMENDED FOR YOU`
  * Bottom Nav: `Home`, `Jobs/Marketplace`, `Mic (Center)`, `Chat`, `Profile`
* **Element Order (Top to Bottom)**:
  1. Top App Bar (Logo, SOS pill, Bell, Profile avatar)
  2. Greeting & Location line
  3. Search bar with Mic icon
  4. Dark Green Dashboard Card (Today's Goal donut gauge + Wallet Balance sub-card)
  5. Safety Monitoring Banner (Green tint bar with location dot)
  6. Quick Actions 4-column Grid (`Nearby Jobs`, `AI Assistant`, `Wallet`, `Safety Hub`)
  7. Sponsored Offer Card (`Kirloskar Hybrid Solar Water Pump` + `Explore Agri Offer` button)
  8. Recommended Jobs header snippet
  9. Bottom Navigation Bar with Floating Center Mic Button
* **Chips / Tabs / Buttons**:
  * `SOS` emergency pill button
  * `View Wallet >` link
  * `Change >` location link
  * 4 Quick Action Cards
  * `Explore Agri Offer` button
  * Bottom Nav Bar tabs
* **Icons**: SOS shield, Bell, Location pin, Mic, Wallet, Map pin, Sparkles/AI, Shield, Shopping/Jobs, Chat, Person.

---

## Screen 7: GPS Based Job Tracking / Nearby Jobs Map
* **Theme**: Light Theme with Map Interface
* **Approximate Hex Colors**: Header `#0D6548`, Map Pins `#00875A`, Background `#FFFFFF`.
* **Visible Texts**:
  * Top Header: `NEARBY DAILY WAGE JOBS & WORK SITES` | `12 Live Pins`
  * Filter Chips: `All`, `Construction`, `Plumbing`, `Painting`, `Delivery`, `R...`
  * Map Overlay Pins: `₹650`, `₹600`, `₹850`, `₹880`, `₹910`, `₹800`, `₹950`, `₹920`, `₹750`, `₹680`, `₹700`
  * Bottom Sheet Header: `NEARBY GPS PIN LISTINGS (12)` | `Tap pin or card to inspect`
  * Listing 1: `Electrician` | `Sai Electricals • Koramangala, Bengaluru` | `0.8 km away` | `₹880` | `Apply`
  * Listing 2: `Construction Helper` | `Sharma Builders • Koramangala 4th Block, Bengaluru` | `1.9 km away` | `₹700` | `Apply`
  * Listing 3: `Plumber` | `R.K. Plumbing Services • Koramangala 4th Block, Bengaluru` | `₹910` | `Apply`
* **Element Order (Top to Bottom)**:
  1. Header Title & Live Pins Count Badge
  2. Horizontal Scrolling Category Filter Chips (`All`, `Construction`, `Plumbing`, `Painting`, `Delivery`)
  3. Leaflet/OpenStreetMap View with price pins and zoom controls (+ / -)
  4. Draggable Bottom Sheet with listing header
  5. Vertical List of Job Cards (Thumbnail, Job Title, Company, Distance, Price, `Apply` button)
  6. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * Category Filter Chips
  * Map Price Pin Markers
  * `Apply` buttons on job cards
* **Icons**: Map pins, Zoom in/out, Category icons, Distance pin.

---

## Screen 8: Wallet Balance & Transactions
* **Theme**: Light Theme with Dark Green Header Card
* **Approximate Hex Colors**: Header Card `#0D6548`, Balance Text `#FFFFFF`, Positive Credit `#00875A`, Debit `#DC2626`.
* **Visible Texts**:
  * Header: `WALLET BALANCE` | `Escrow Protected`
  * Balance Amount: `₹15,250`
  * Sub-card 1: `+₹800`
  * Sub-card 2: `Pending Escrow ₹1,200`
  * Action Button 1: `↗` (Withdraw)
  * Action Button 2: `Scan UPI QR`
  * Section Header: `RECENT TRANSACTIONS`
  * Transaction 1: `Daily Wage - Construction Helper` | `Today, 5:30 PM` | `+₹700` | `✓ Completed`
  * Transaction 2: `UPI Transfer to PhonePe (Bank)` | `Yesterday` | `-₹1,200` | `✓ Completed`
  * Transaction 3: `Daily Wage - Plumber Service` | `04 Aug 2026` | `+₹910` | `✓ Completed`
  * Transaction 4: `Daily Wage - Painting Work` | `03 Aug 2026` | `+₹750` | `✓ Completed`
  * Transaction 5: `Farm Produce Direct Sale - Tomatoes` | `02 Aug 2026` | `+₹1,400` | `✓ Completed`
  * Transaction 6: `UPI Auto-Payout - Delivery Shift` | `+₹600`
* **Element Order (Top to Bottom)**:
  1. Top Dark Green Card (Wallet Balance title, Escrow Protected badge, ₹15,250 balance)
  2. Two Inner Metric Cards (`+₹800` released, `Pending Escrow ₹1,200`)
  3. Action Buttons Row (`↗` withdraw pill, `Scan UPI QR` button)
  4. Section Header (`RECENT TRANSACTIONS`)
  5. Vertical List of Transaction Items (Icon, Description, Date/Time, Amount, Completed status badge)
  6. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * `Escrow Protected` badge
  * Withdraw arrow button
  * `Scan UPI QR` button
* **Icons**: Arrow up-right (`↗`), QR code icon, Green credit arrow down-left (`↙`), Red debit arrow up-right (`↗`).

---

## Screen 9: AI Multilingual Voice Assistant Overlay
* **Theme**: Dark Navy Style Overlay
* **Approximate Hex Colors**: Background `#0F172A`, Mic Outer Circle `#00875A`, Mic Icon `#FFFFFF`.
* **Visible Texts**:
  * Title: `AI MULTILINGUAL VOICE ASSISTANT`
  * Language Pill: `🌐 Language: English`
  * Main Status: `Listening to your voice...`
  * Sub-status: `Tap mic and speak in Kannada, Hindi, Telugu, Tamil or English`
  * Prompt Label: `TAP EXAMPLE COMMAND TO DIRECT SEARCH`
  * Chip 1: `"find plumber near me"`
  * Chip 2: `"show today's earnings"`
  * Chip 3: `"farmers selling tomatoes"`
  * Chip 4: `"find construction work"`
  * Bottom Button: `🎙 Listening... (Tap to stop)`
* **Element Order (Top to Bottom)**:
  1. Header Bar: Logo, Title (`AI MULTILINGUAL VOICE ASSISTANT`), Close `X` button
  2. Language Indicator Pill (`🌐 Language: English`)
  3. Large Animated Mic Pulse Circle
  4. Main Status Text (`Listening to your voice...`) & Instruction subtext
  5. Example Command Prompts Section & 4 Tappable Suggestion Chips
  6. Bottom Pill Button (`🎙 Listening... (Tap to stop)`)
  7. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * Language switcher pill
  * 4 Command suggestion chips
  * Bottom stop listening pill button
  * Close `X` button
* **Icons**: Microphone, Close `X`, Globe.

---

## Screen 10: Recommended Jobs List
* **Theme**: Light Theme
* **Approximate Hex Colors**: Background `#F8FAFC`, Apply Button `#00875A`, Card White `#FFFFFF`.
* **Visible Texts**:
  * Section Title: `RECOMMENDED FOR YOU`
  * Job 1: `Electrician` | `Sai Electricals ✓` | `★ 4.9 • 0.8 km away` | `₹880/day` | `Apply Now`
  * Job 2: `Construction Helper` | `Sharma Builders ✓` | `★ 4.6 • 1.9 km away` | `₹700/day` | `Apply Now`
  * Job 3: `Plumber` | `R.K. Plumbing Services ✓` | `★ 4.9 • 1.0 km away` | `₹910/day` | `Apply Now`
  * Job 4: `Painter` | `Colours World ✓` | `★ 4.4 • 3.5 km away` | `₹750/day` | `Apply Now`
  * Job 5: `Delivery Assistant` | `FastDrop Logistics ✓` | `★ 4.5 • 2.2 km away` | `₹600/day` | `Apply Now`
  * Job 6: `Carpenter` | `WoodCraft Studios ✓` | `★ 4.8 • 2.8 km away` | `₹950/day` | `Apply Now`
  * Job 7: `Mason & Brick Layer` | `Karnataka Infra Co. ✓` | `★ 4.7 • 4.1 km away` | `₹850/day` | `Apply Now`
* **Element Order (Top to Bottom)**:
  1. Section Header (`RECOMMENDED FOR YOU`)
  2. Vertical List of 7 Job Cards (Photo thumbnail, Title, Employer Name with green check, Rating & Distance row, Pay per day badge, `Apply Now` green button)
  3. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * `Apply Now` pill buttons on each job card
* **Icons**: Employer photo/avatar, Verified checkmark (`✓`), Star rating (`★`), Location pin.

---

## Screen 11: Safety Onboarding & Verification Badge Screen
* **Theme**: Light Theme with Dark Green Top Card
* **Approximate Hex Colors**: Header `#0D6548`, Badge Green `#00875A`, Status Card `#FFFFFF`.
* **Visible Texts**:
  * Header Card: `MANDATORY WORKER PROGRAM` | `UdyogaSethu Safety Onboarding`
  * Subtext: `Complete registration, KYC & 1-day training to get verified.`
  * Status Line: `Onboarding Status:` | `APPROVED`
  * Lifecycle Test Section: `TEST ONBOARDING STATUS LIFECYCLE:`
  * Lifecycle Pills: `Not Booked`, `Slot Booked`, `Attended`, `Document Review`
  * Badge Card: `"UDYOGASETHU VERIFIED" BADGE` | `VERIFIED ✓`
  * Badge Subtext: `Badge Active on Worker Profile & Search`
  * Checklist Item 1: `✓ 1. Aadhaar eKYC`
  * Checklist Item 2: `✓ 2. Face Liveness Setup`
  * Checklist Item 3: `✓ 3. 1-Day Training`
  * Checklist Item 4: `✓ 4. Document Approval`
  * Training Section: `MANDATORY 1-DAY TRAINING MODULES`
  * Module 1: `🪖 1. Site Safety & PPE` | `Helmets, gloves, harness & electrical safety.`
  * Module 2: `🤝 2. Conduct Rules` | `Punctuality, customer interaction & site ethics.`
  * Module 3: `🎫 3. QR Ticket Pass` | `Scanning work passes at site entry & exit.`
  * Module 4: `🤳 4. Selfie/GPS Check` | `Biometric face match & geo-fenced check-in.`
* **Element Order (Top to Bottom)**:
  1. Dark Green Program Header Card with Shield Icon & `APPROVED` pill
  2. Test Lifecycle Pills bar (`Not Booked`, `Slot Booked`, `Attended`, `Document Review`)
  3. Verified Assurance Badge Card with 4-item Checkmark Grid
  4. Mandatory 1-Day Training Modules 2x2 Grid Cards
  5. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * `APPROVED` status badge
  * Lifecycle state switcher pills
  * 4 Checklist status pills
* **Icons**: Shield, Checkmark (`✓`), Helmet, Handshake, QR ticket, Selfie camera.

---

## Screen 12: Worker Profile Page
* **Theme**: Light Theme with Dark Green Profile Header
* **Approximate Hex Colors**: Header `#0D6548`, Background `#F8FAFC`, Skill Pills `#F1F5F9`.
* **Visible Texts**:
  * Name: `Chethan Kumar` | Edit Pencil Icon
  * Badge: `UDYOGASETHU VERIFIED ✓`
  * Category: `Category: Informal / Skilled Worker`
  * Phone: `+91 91234 56789`
  * Metric 1: `127` | `Verified Jobs`
  * Metric 2: `4.9★` | `Rating (125)`
  * Metric 3: `₹28,450` | `Total Earnings`
  * Profile Tabs: `Overview`, `Work Showcase`, `Safety Status`
  * Section 1: `ROLE CREDENTIALS & CATEGORY BADGES` | `Change Category`
  * Credential Item 1: `Driving Licence Verification` | `Mandatory for Driver, Delivery & Logistics roles` | `Licence Verified ✓`
  * Credential Item 2: `Student Part-Time Verification` | `BMS College of Engineering (BE CS)` | `Not Student`
  * Section 2: `LANGUAGE_ACCESSIBILITY` | `EN Mode Active`
  * Language Grid: `GB English`, `IN ಕನ್ನಡ`, `IN తెలుగు`, `IN हिंदी`, `IN தமிழ்`
  * Section 3: `MY SKILLS` | `+ Add Skill`
* **Element Order (Top to Bottom)**:
  1. Dark Green Profile Header (Avatar photo, Name, Verified badge, Category, Phone, Edit icon)
  2. 3 Metrics Columns (`127 Verified Jobs`, `4.9★ Rating`, `₹28,450 Total Earnings`)
  3. Profile View Tabs (`Overview`, `Work Showcase`, `Safety Status`)
  4. Role Credentials & Badges Card (`Driving Licence Verification` & `Student Verification`)
  5. Language Accessibility Selector Grid
  6. My Skills Tag Section
  7. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * `Change Category` button
  * Profile sub-tabs (`Overview`, `Work Showcase`, `Safety Status`)
  * `Licence Verified ✓` badge
  * `Not Student` badge
  * `+ Add Skill` button
* **Icons**: Profile picture, Verified check, Edit pencil, Driving truck icon, Graduation cap icon, Globe.

---

## Screen 13: Protected Inbox / Chat Section
* **Theme**: Light Theme
* **Approximate Hex Colors**: Header `#0D6548`, Search Background `#F1F5F9`, Privacy Banner `#ECFDF5`.
* **Visible Texts**:
  * Header: `UdyogaSethu Protected Inbox` | `3 Chats`
  * Subtitle: `Communicating via Secure Escrow Network`
  * Search Placeholder: `🔍 Search person, crop, job, or Booking ID...`
  * Status Filter Chips: `All Chats (11)`, `Active (8)`, `Completed (3)`
  * Role Filter Chips: `All Roles`, `Farmer Chats`, `Customer Chats`, `Worker Chats`
  * Safety Banner: `🔒 UdyogaSethu Safety: Phone & payment handles are masked for your privacy.`
  * Chat 1: `Sharma Builders` | `EMPLOYER` | `9:33 AM` | `Commercial Electrical Repair • BOOK-7842` | `Active`
  * Chat 2: `Karnataka Infra...` | `CONSTRUCTION SITE MANAGER` | `8:15 AM` | `Masonry Wall & Concrete Plastering • BOOK-8812` | `Active`
  * Chat 3: `Ramesh Plumbing Services` | `EMPLOYER` | `24 Aug` | `Pipe Fitting & Water Leakage Repair • BOOK-6210` | `Read-Only`
* **Element Order (Top to Bottom)**:
  1. Dark Green Inbox Header with title, subtitle, and total chats count badge
  2. Search Bar Input
  3. Status Filter Chips row (`All Chats`, `Active`, `Completed`)
  4. Role Filter Chips row (`All Roles`, `Farmer Chats`, `Customer Chats`, `Worker Chats`)
  5. Privacy Shield Notice Banner
  6. Vertical List of Chat Conversation Cards (Avatar, Contact Name, Role tag, Timestamp, Job Details & Booking ID, Status pill (`Active` / `Read-Only`))
  7. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * Status filter chips
  * Role filter chips
  * Chat status pills (`Active`, `Read-Only`)
* **Icons**: Back arrow, Search glass, Lock icon, Avatar images.

---

## Screen 14: Profile Page Continuation
* **Theme**: Light Theme
* **Approximate Hex Colors**: Background `#F8FAFC`, Status Verified `#00875A`.
* **Visible Texts**:
  * Section Header: `MY SKILLS` | `+ Add Skill`
  * Skill Pills: `✓ Leader`, `✓ Electrician`, `✓ Plumber`, `✓ Driver`
  * Section Header: `VERIFICATION_STATUS` | `UdyogaSethu Verified ✓`
  * Item 1: `Aadhaar eKYC Status` | `Masked Aadhaar: XXXX-XXXX-9012` | `VERIFIED ✓`
  * Item 2: `Face Verified Liveness` | `✓`
  * Item 3: `1-Day Safety Training Program` | `APPROVED ✓`
* **Element Order (Top to Bottom)**:
  1. Top continuation: Language accessibility grid
  2. My Skills Section with active skill pills (`Leader`, `Electrician`, `Plumber`, `Driver`) and `+ Add Skill` button
  3. Verification Status Card with Aadhaar eKYC masked status, Face liveness check, and Safety training approval status
  4. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * Skill tag pills with checkmarks
  * `VERIFIED ✓` and `APPROVED ✓` status pills
* **Icons**: Aadhaar card icon, Camera face icon, Training badge icon.

---

## Screen 15: Driving Licence Verification Screen
* **Theme**: Dark Navy Style
* **Approximate Hex Colors**: Background `#0B132B`, Input Card `#1E293B`, Button `#00875A`.
* **Visible Texts**:
  * Header: `🟢 DRIVING LICENCE VERIFICATION`
  * Role Check Box: `MANDATORY ROLE CHECK` | `Required for Driving & Delivery Roles` | `Exempt for non-driving roles (cleaner, plumber, electrician, etc.).`
  * Field 1: `LICENCE NUMBER` | `KA-01-2022-0098412`
  * Field 2: `LICENCE CLASS` | `LMV / Transport (Car, Goods Auto) ∨`
  * Field 3: `EXPIRY DATE` | `31-12-2028 📅`
  * Field 4: `UPLOAD LICENCE PHOTO` | `DL_Front_Back_Scan.jpg` | `ATTACHED ✓`
  * Primary Button: `Submit Driving Licence for Verification`
* **Element Order (Top to Bottom)**:
  1. Top Header with title (`DRIVING LICENCE VERIFICATION`)
  2. Mandatory Role Check Notice Box
  3. Licence Number Text Input Container
  4. Licence Class Dropdown Selector
  5. Expiry Date Picker Input
  6. Document Upload Box (Thumbnail, Filename, `ATTACHED ✓` badge)
  7. Primary Green Submit Button
  8. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * `ATTACHED ✓` status badge
  * `Submit Driving Licence for Verification` button
* **Icons**: Driving license icon, Calendar icon, Dropdown chevron, Attachment checkmark.

---

## Screen 16: Category Change / Preferences Screen
* **Theme**: Dark Navy Style
* **Approximate Hex Colors**: Background `#0B132B`, Card Border `#00875A`, Button `#00875A`.
* **Visible Texts**:
  * Header: `🟢 WORKER CATEGORY & PREFERENCES`
  * Subtitle: `SELECT WORKER CATEGORY` | `Tailored Matching & Verification`
  * Category 1: `Informal / Skilled Worker`
  * Category 2: `Student Part-Time Worker` (Selected outline)
  * Category 3: `Homemaker / Flexible Worker`
  * Category 4: `Farmer / Producer`
  * Card Header: `🎓 STUDENT ACADEMIC VERIFICATION`
  * Field 1: `COLLEGE / UNIVERSITY NAME` | `BMS College of Engineering, Bengaluru`
  * Field 2: `COURSE / DEGREE` | `B.E. Computer Science`
  * Field 3: `USN / REG NO.` | `1BM23CS108`
  * Privacy Note: `🔒 All student documents & USN records remain strictly private.`
  * Primary Button: `Save Category & Preferences`
* **Element Order (Top to Bottom)**:
  1. Top Header (`WORKER CATEGORY & PREFERENCES`)
  2. 2x2 Grid of Worker Category Cards with icons
  3. Student Academic Verification Form Card (College name, course degree, USN input)
  4. Privacy Disclaimer Box
  5. Primary Green Action Button (`Save Category & Preferences`)
  6. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * 4 Category Cards
  * `Save Category & Preferences` button
* **Icons**: Hardhat icon, Graduation cap icon, House icon, Sprout icon, Lock icon.

---

## Screen 17: Unverified Worker Booking Notice
* **Theme**: Dark Navy Style
* **Approximate Hex Colors**: Background `#0B132B`, Warning Orange `#F59E0B`, Button Teal `#00875A`.
* **Visible Texts**:
  * Header: `UNVERIFIED WORKER NOTICE`
  * Warning Badge: `⚠️ NOT UDYOGASETHU VERIFIED`
  * Title: `Booking Sunil Kumar`
  * Subtitle: `"This worker has not completed UdyogaSethu's training and verification process. UdyogaSethu has not granted its Verified Assurance badge for this profile."`
  * Option 1 Card: `Add ₹40 Job Protection Cover` | `Covers property damage & claims` | `+₹40`
  * Option 2 Card: `Book Without Protection` | `No insurance claim support` | `₹0`
  * Primary Button: `Confirm & Proceed to Booking Pass Ticket`
* **Element Order (Top to Bottom)**:
  1. Header Bar (`UNVERIFIED WORKER NOTICE`)
  2. Large Amber Alert Warning Icon & Badge (`⚠️ NOT UDYOGASETHU VERIFIED`)
  3. Worker Booking Title & Cautionary Quote Box
  4. Option 1 Card (`Add ₹40 Job Protection Cover`) with green price tag (`+₹40`)
  5. Option 2 Card (`Book Without Protection`) with zero price tag (`₹0`)
  6. Full-Width Primary Green Button (`Confirm & Proceed to Booking Pass Ticket`)
  7. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * `NOT UDYOGASETHU VERIFIED` warning badge
  * 2 Selection Option Cards
  * `Confirm & Proceed to Booking Pass Ticket` button
* **Icons**: Warning triangle, Shield icon.

---

## Screen 18: Secured Call Screen (Masked Proxy)
* **Theme**: Dark Navy Style
* **Approximate Hex Colors**: Background `#0B132B`, Alert Box `#7C2D12`, Call Red `#DC2626`.
* **Visible Texts**:
  * Banner: `PROTECTED MASKED VOICE PROXY` | `SOS` | `X`
  * Warning Box: `🔒 Privacy Guard: Phone numbers are masked. Do not share personal contact details or off-platform payment info outside UdyogaSethu.`
  * Avatar Name: `Sharma Builders`
  * Booking ID: `ID: BOOK-7842`
  * Title: `Sharma Builders`
  * Subtitle: `Employer • Commercial Electrical Repair`
  * Call Duration: `Call Active • 00:11`
  * Control 1: `🎙 Mute`
  * Control 2: `🔊 Speaker ON` (Green)
  * End Call Button: `End Call` (Red)
* **Element Order (Top to Bottom)**:
  1. Top Banner with SOS pill & Close `X`
  2. Privacy Guard Alert Banner (Orange outline box)
  3. Central Contact Avatar Circle (`Sharma Builders`)
  4. Booking ID Tag (`ID: BOOK-7842`)
  5. Contact Name, Role, Job Title, and Call Duration counter (`Call Active • 00:11`)
  6. Audio Controls Row (`Mute` pill, `Speaker ON` green pill)
  7. Large Red `End Call` Pill Button
  8. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * `SOS` button
  * `Mute` & `Speaker ON` pills
  * `End Call` button
* **Icons**: SOS shield, Phone icon, Mute mic, Speaker horn.

---

## Screen 19: High-Priority Safety SOS Screen
* **Theme**: Dark Navy Style
* **Approximate Hex Colors**: Background `#0B132B`, Alert Modal `#1E293B` with Red Border `#DC2626`, Red Button `#DC2626`.
* **Visible Texts**:
  * Header: `🔴 HIGH-PRIORITY SAFETY SOS`
  * Modal Title: `Trigger Emergency SOS?`
  * Modal Subtitle: `This will log a high-priority safety incident for booking BOOK-7842 and initiate emergency contact response.`
  * Demo Disclaimer: `⚠️ Demo Simulation Note: Safety team & emergency contacts will be notified. This demo does not claim direct police dispatch integration.`
  * Primary Button: `Yes, Trigger Emergency Escalation` (Red)
  * Cancel Button: `Cancel` (Grey)
* **Element Order (Top to Bottom)**:
  1. Header Bar (`HIGH-PRIORITY SAFETY SOS`)
  2. Central Dark Card with Red Border & Large `SOS` Icon Circle
  3. Title (`Trigger Emergency SOS?`) and Explanation Subtext
  4. Yellow Demo Simulation Disclaimer Box
  5. Primary Red Button (`Yes, Trigger Emergency Escalation`)
  6. Secondary Grey Button (`Cancel`)
  7. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * `SOS` icon badge
  * `Yes, Trigger Emergency Escalation` red button
  * `Cancel` button
* **Icons**: Emergency SOS badge icon.

---

## Screen 20: UdyogaSethu Job Protection Claim Screen
* **Theme**: Dark Navy Style
* **Approximate Hex Colors**: Background `#0B132B`, Card `#1E293B`, Button `#00875A`.
* **Visible Texts**:
  * Header: `🟢 UDYOGASETHU JOB PROTECTION CLAIM`
  * Booking Banner: `BOOKING ID: BOOK-7842` | `Commercial Electrical Repair`
  * Demo Note: `⚠️ Notice: Job Protection cover is simulated in this demonstration. Real commercial deployment requires a licensed IRDAI insurance partner.`
  * Checklist Section: `CLAIM ELIGIBILITY CHECK:`
  * Checklist Item 1: `✓ QR Attendance`
  * Checklist Item 2: `✓ Selfie/GPS Check`
  * Checklist Item 3: `✓ Job Timer Log`
  * Checklist Item 4: `✓ Evidence Attached`
  * Field 1: `CLAIM TYPE` | `Property Damage Cover ∨`
  * Field 2: `CLAIM AMOUNT (₹)` | `1500`
  * Field 3: `INCIDENT DETAILS` | `Accidental damage to circuit breaker panel during wiring installation.`
  * Primary Button: `Submit Protection Claim`
* **Element Order (Top to Bottom)**:
  1. Header Bar (`UDYOGASETHU JOB PROTECTION CLAIM`)
  2. Booking ID & Job Title Container Card
  3. Amber Insurance Demo Disclaimer Box
  4. Claim Eligibility Checklist 2x2 Grid (4 Green checkmarks)
  5. Claim Type Dropdown Input
  6. Claim Amount Numeric Input
  7. Incident Details Multi-line Text Area
  8. Primary Green Action Button (`Submit Protection Claim`)
  9. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * 4 Checklist status chips
  * `Submit Protection Claim` button
* **Icons**: Shield check, Dropdown arrow.

---

## Screen 21: Smart No-Show Recovery Screen
* **Theme**: Dark Navy Style
* **Approximate Hex Colors**: Background `#0B132B`, Alert Red `#DC2626`, Primary Button `#00875A`.
* **Visible Texts**:
  * Header: `SMART NO-SHOW RECOVERY ENGINE` | `X`
  * Alert Banner: `⚠️ ARRIVAL GRACE PERIOD EXPIRED`
  * Title: `Worker Has Not Arrived`
  * Subtitle: `Chethan Kumar is 15 minutes past the scheduled arrival time for Commercial Electrical Repair.`
  * Action 1: `Wait 10 Minutes` | `+10m Grace`
  * Action 2: `📞 Call Worker Directly` | `Dialing` (Green)
  * Action 3: `⚡ Find Smart Replacement Worker` (Bright Green)
* **Element Order (Top to Bottom)**:
  1. Header Bar with title and Close `X`
  2. Dark Card with Red Alert Header & Warning Icon
  3. Title (`Worker Has Not Arrived`) & Explanation text
  4. Secondary Action Button 1 (`Wait 10 Minutes +10m Grace`)
  5. Secondary Action Button 2 (`Call Worker Directly Dialing`)
  6. Primary Action Button (`⚡ Find Smart Replacement Worker`)
  7. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * `+10m Grace` pill
  * `Dialing` status pill
  * 3 Action buttons
* **Icons**: Warning icon, Phone call icon, Lightning bolt icon.

---

## Screen 22: Farmer Home Page
* **Theme**: Light Theme with Dark Green Top Card
* **Approximate Hex Colors**: Header `#0D6548`, Background `#F8FAFC`, Live Badge `#00875A`.
* **Visible Texts**:
  * Header: `🟢 FARMER WORKSPACE` | `Mandya Agri Cluster`
  * Farm Title: `Greenfield Organic Farm`
  * Tagline: `Empowered by UdyogaSethu Direct Agri-Network` | Profile Avatar
  * Metric 1: `420 kg` | `PRODUCE SOLD` | `This Month`
  * Metric 2: `₹48,500` | `DIRECT EARNINGS` | `Zero Middlemen`
  * Metric 3: `5 Booked` | `ACTIVE LABOR` | `Harvest Shift`
  * Section Header: `LIVE MANDI PRICES & DEMAND (APMC KARNATAKA)` | `Live Feed`
  * Tabs: `All Crops`, `Vegetables`, `Grains & Pulses`
  * Price Card 1: `Organic Tomatoes` | `+12%` | `₹34/kg` | `High Demand` | `K.R. Market • 5 mins ago`
  * Price Card 2: `Paddy (Sona Masoori)` | `+5%` | `₹2,450/qtl` | `Stable` | `Mandya Mandi • 12 mins ago`
  * Price Card 3: `Red Onions (Nasik)` | `-3%` | `₹38/kg` | `Moderate` | `Yashwantpur • 2 mins ago`
  * Price Card 4: `Sugarcane (Co 86032)` | `+8%` | `₹3,100/ton` | `FRP Guaranteed` | `Sugar Mill Co-op • 20 mins ago`
  * Price Card 5: `Robusta Banana` | `+15%` | `₹22/kg` | `Mysuru APMC Yard`
  * Price Card 6: `Cardamom (Green)` | `+4%` | `Kodagu Co-op`
* **Element Order (Top to Bottom)**:
  1. Dark Green Header Card (Workspace title, Farm Name, Subtitle, Profile Avatar)
  2. 3 Metrics Columns (`420 kg Produce Sold`, `₹48,500 Direct Earnings`, `5 Booked Active Labor`)
  3. Live Mandi Prices Header with Live Feed Pulse Badge
  4. Crop Category Filter Tabs (`All Crops`, `Vegetables`, `Grains & Pulses`)
  5. 2-Column Grid of Live Mandi Price Cards (Crop Name, Price trend badge %, Unit price, Demand status pill, APMC location & update time)
  6. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * `Live Feed` status badge
  * Crop category filter tabs
  * Price trend badges (`+12%`, `+5%`, `-3%`, `+8%`)
  * Demand status pills (`High Demand`, `Stable`, `Moderate`, `FRP Guaranteed`)
* **Icons**: Sprout icon, Farmer avatar, Live signal pulse, Arrow up/down trends.

---

## Screen 23: Farmer GPS Based Search / Machinery & Services
* **Theme**: Light Theme with Map Interface
* **Approximate Hex Colors**: Header `#0D6548`, Map Pins `#00875A`, Background `#FFFFFF`.
* **Visible Texts**:
  * Header: `FARMERS REQUIRED PRODUCTS, SEEDS, MACHINERY & SERVICES NEAR ME` | `7 Live Pins`
  * Filter Chips: `All`, `Tractors & Implements`, `Seeds & Bio-Fertilizers`, `Cold Sto...`
  * Map Overlay Pins: `₹200/sample`, `₹850/hr`, `₹15/crate/day`, `₹450/acre`, `₹450/bag`, `Direct Sale`
  * Listing Header: `NEARBY GPS PIN LISTINGS (7)` | `Tap pin or card to inspect`
  * Listing 1: `Mahindra 575 DI Tractor Rental` | `Kisan Machinery Hub • Devanahalli Road` | `1.2 km away` | `₹850/hr` | `Book Item`
  * Listing 2: `Bio-NPK & Vermicompost Depot` | `GreenSoil Organic Depot • Yelahanka Mandi Gate` | `2.4 km away` | `₹450/bag` | `Book Item`
  * Listing 3: `Solar Cold Storage Facility`
* **Element Order (Top to Bottom)**:
  1. Header Title & Live Pins Count Badge
  2. Category Filter Chips (`All`, `Tractors & Implements`, `Seeds & Bio-Fertilizers`, `Cold Storage`)
  3. Interactive Map with pins and zoom controls (+ / -)
  4. Bottom Sheet with pin listings header
  5. Vertical List of Equipment/Service Cards (Image, Title, Supplier, Distance, Rate, `Book Item` green button)
  6. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * Category filter chips
  * Map price pins
  * `Book Item` buttons
* **Icons**: Tractor icon, Bio-fertilizer bag icon, Map pins, Zoom controls.

---

## Screen 24: Farmer Chat Section
* **Theme**: Light Theme
* **Approximate Hex Colors**: Header `#0D6548`, Background `#F8FAFC`, Active Pill `#00875A`.
* **Visible Texts**:
  * Header: `UdyogaSethu Protected Inbox` | `4 Chats`
  * Subtitle: `Communicating via Secure Escrow Network`
  * Search Bar: `🔍 Search person, crop, job, or Booking ID...`
  * Status Filter Chips: `All Chats (11)`, `Active (8)`, `Completed (3)`
  * Role Filter Chips: `All Roles`, `Farmer Chats`, `Customer Chats`, `Worker Chats`
  * Safety Banner: `🔒 UdyogaSethu Safety: Phone & payment handles are masked for your privacy.`
  * Chat 1: `Kisan Tractor & Equipme...` | `AGRI MACHINERY VENDOR` | `Mahindra 575 Tractor + Rotavator Rental • BOOK-FARM-901` | `Active`
  * Chat 2: `KR Market Direct Mandi...` | `BULK PRODUCE BUYER` | `Organic Tomato Bulk Sale (80 Crates) • BOOK-FARM-802` | `Active`
  * Chat 3: `Ramesh Harvest Crew Su...` | `AGRI LABOR SUPERVISOR` | `5 Harvest Workers Shift Booking • BOOK-FARM-604` | `Active`
  * Chat 4: `Bio-Organic Seed & Fertiliz...` | `AGRI INPUT SUPPLIER` | `Vermi-Compost & Bio-NPK Delivery • BOOK-FARM-703` | `Read-Only`
* **Element Order (Top to Bottom)**:
  1. Inbox Header Title & 4 Chats badge
  2. Search Input Bar
  3. Status Filter Chips row
  4. Role Filter Chips row
  5. Privacy Shield Notice Banner
  6. Vertical List of Farmer Conversations (Vendor Avatar, Name, Category Badge, Order Details & Booking ID, Status pill (`Active` / `Read-Only`))
  7. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * Filter chips
  * Status pills (`Active`, `Read-Only`)
* **Icons**: Tractor icon, Basket icon, Worker icon, Seed icon.

---

## Screen 25: Farmer Profile Page
* **Theme**: Light Theme with Dark Green Top Header
* **Approximate Hex Colors**: Header `#0D6548`, Background `#F8FAFC`, Badge `#00875A`.
* **Visible Texts**:
  * Name: `Farmer Chethan Gowda`
  * Badge: `VERIFIED FARMER ✓`
  * Subtitle: `Greenfield Organic Farm • Mandya Cluster`
  * Phone: `+91 98450 77889`
  * Metric 1: `4.2 Acres` | `Organic Land`
  * Metric 2: `420 kg` | `Sold This Month`
  * Metric 3: `₹48,500` | `Direct Sales`
  * Section Header: `🌾 FARM INFRASTRUCTURE & CROP BADGES`
  * Info Card 1: `SOIL CLASSIFICATION` | `Red Loam Soil (pH 6.8)`
  * Info Card 2: `PRIMARY CROPS` | `Tomatoes, Paddy, Banana`
  * Info Card 3: `APMC REGISTRATION` | `Mandya APMC #4812`
  * Info Card 4: `KISAN CREDIT CARD` | `KCC Approved ✓`
  * Certificate Card: `Zero-Pesticide Organic Certificate` | `Verified by Karnataka Organic Farmers Board` | `VALIDATED ✓`
  * Language Selector: `LANGUAGE MODE` | `EN` | `English`, `ಕನ್ನಡ`, `తెలుగు`, `हिंदी`, `தமிழ்`
* **Element Order (Top to Bottom)**:
  1. Dark Green Profile Header (Avatar photo, Name, Verified Farmer badge, Farm location, Phone)
  2. 3 Metrics Columns (`4.2 Acres Organic Land`, `420 kg Sold This Month`, `₹48,500 Direct Sales`)
  3. Farm Infrastructure & Crop Badges 2x2 Grid
  4. Zero-Pesticide Organic Certificate Validation Card (`VALIDATED ✓`)
  5. Language Mode Selector Grid
  6. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * `VERIFIED FARMER ✓` badge
  * `KCC Approved ✓` badge
  * `VALIDATED ✓` certificate badge
  * Language buttons
* **Icons**: Sprout icon, Shield check, Organic certificate leaf, Language globe.

---

## Screen 26: Farmer Essential Suite & Advisory
* **Theme**: Light Theme
* **Approximate Hex Colors**: Background `#F8FAFC`, Weather Card `#E65100` / `#F59E0B`, Button `#00875A`.
* **Visible Texts**:
  * Section Header: `FARMER ESSENTIAL SUITE`
  * Action 1: `Rent Tractor`
  * Action 2: `Hire Workers`
  * Action 3: `Soil AI Test`
  * Action 4: `Sell Produce`
  * Action 5: `Pest AI Doc`
  * Action 6: `Govt Schemes`
  * Action 7: `Agri Drone`
  * Action 8: `Irrigation AI`
  * Radar Card Header: `WEATHER ADVISORY RADAR` | `Mandya District`
  * Advisory Text: `Moderate Rain Expected Tomorrow Afternoon - Protect ready tomato crops by harvesting before 12 PM. 5 Local harvest helpers are available nearby for booking.`
  * Section Header: `NEARBY EQUIPMENT & DRONE RENTALS` | `Escrow Guaranteed`
  * Item 1: `Mahindra 575 DI Tractor + Rotavator` | `4.9★` | `₹850/hr` | `Kisan Machinery Hub • 2.4 km away` | `50 HP • Fuel Included` | `Book Now`
  * Item 2: `Multi-Crop Harvester & Thresher` | `4.8★` | `₹1,400/hr` | `AgriTech Rentals Mandya • 4.1 km away` | `High Yield Grain Cutter` | `Book Now`
  * Item 3: `Agricultural Drone Spraying Kit` | `5.0★` | `₹450/acre` | `DroneKisan Karnataka • 1.8 km away` | `10L Tank • Precision GPS` | `Book Now`
* **Element Order (Top to Bottom)**:
  1. Farmer Essential Suite 4x2 Action Icon Grid (`Rent Tractor`, `Hire Workers`, `Soil AI Test`, `Sell Produce`, `Pest AI Doc`, `Govt Schemes`, `Agri Drone`, `Irrigation AI`)
  2. Weather Advisory Radar Amber Banner Card (Cloud/rain icon, district title, warning text)
  3. Nearby Equipment & Drone Rentals Header with Escrow Guaranteed badge
  4. Vertical List of Rental Equipment Cards (Image thumbnail, Title, Rating, Price badge, Supplier info, Specs subtext, `Book Now` green button)
  5. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * 8 Action grid icons
  * `Escrow Guaranteed` badge
  * `Book Now` buttons
* **Icons**: Tractor, Workers, Soil lab, Produce basket, Pest doc, Govt badge, Drone, Water drops, Cloud rain.

---

## Screen 27: Job Provider Home Page
* **Theme**: Light Theme with Dark Green Top Card
* **Approximate Hex Colors**: Header `#0D6548`, Background `#F8FAFC`, Button `#00875A`.
* **Visible Texts**:
  * Header: `🟢 CUSTOMER HUB` | `Verified Account`
  * Greeting: `Hello, Chethan! 👋`
  * Tagline: `Farm-Fresh Goods & Verified On-Demand Workers` | Wallet Icon
  * Category Toggle Tabs: `Workers & Services`, `🌾 Farm Produce`, `Subscriptions`
  * Quick Actions: `Scan Farm QR`, `No-Show Help`, `Milk / Basket`, `Farmer Chat`
  * Card Header: `CONFIRMED BOOKING • BOOK-7842` | `Scheduled Today` | `09:30 AM Shift`
  * Job Title: `Commercial Electrical Repair`
  * Worker: `Worker: Chethan Kumar (Aadhaar Verified ✓)`
  * Location & Price: `📍 Koramangala 4th Block` | `₹880/day Escrow Held`
  * Alert Line: `⚠️ Worker Has Not Arrived` | `Protected Chat`
  * Section Header: `VERIFIED ON-DEMAND LOCAL WORKERS` | `100% Aadhaar Verified`
  * Worker 1: `Electrician` | `Verified ✓` | `Sai Electricals • 0.8 km away` | `★ 4.9 ₹880/day` | `Book Worker`
  * Worker 2: `Construction Helper` | `Verified ✓` | `Sharma Builders • 1.9 km away` | `★ 4.6 ₹700/day` | `Book Worker`
* **Element Order (Top to Bottom)**:
  1. Dark Green Header Card (Customer Hub title, Greeting, Tagline, Wallet Icon)
  2. 3 Main Category Toggle Tabs (`Workers & Services`, `Farm Produce`, `Subscriptions`)
  3. 4 Action Icon Buttons (`Scan Farm QR`, `No-Show Help`, `Milk / Basket`, `Farmer Chat`)
  4. Confirmed Active Booking Status Card (Booking ID, Schedule, Job title, Worker name with verification check, Address, Escrow price, No-show alert line, `Protected Chat` button)
  5. Verified On-Demand Local Workers Section with 100% Aadhaar Verified badge
  6. Vertical List of Available Worker Cards (Avatar, Role, Verified badge, Distance, Rating, Price, `Book Worker` button)
  7. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * 3 Main category toggle tabs
  * `Protected Chat` button
  * `100% Aadhaar Verified` badge
  * `Book Worker` buttons
* **Icons**: QR scanner, Lightning/help, Milk bottle, Chat, Electrician avatar, Hardhat avatar.

---

## Screen 28: Quality Assurance / Traceability Modal
* **Theme**: Light Theme Modal Overlay
* **Approximate Hex Colors**: Overlay Background `rgba(0,0,0,0.6)`, Card `#FFFFFF`, Icon Teal `#00875A`.
* **Visible Texts**:
  * Modal Title: `Farm Quality Traceability Verified` | Magnifying Glass Icon
  * Field 1: `Crop Item:` | `Red Tomatoes`
  * Field 2: `Farmer Origin:` | `Ramesh Organic Farm`
  * Field 3: `Harvest Time:` | `Yesterday, 5:30 AM`
  * Field 4: `Organic Certification:` | `Pesticide-Free ✓`
  * Primary Button: `Close Traceability Details`
* **Element Order (Top to Bottom)**:
  1. Darkened Dimmed Screen Backdrop
  2. Central Rounded White Modal Card
  3. Magnifying Glass Inspection Icon Circle
  4. Title (`Farm Quality Traceability Verified`)
  5. 4 Data Attribute Rows (Crop item, Farmer origin, Harvest timestamp, Organic certification check)
  6. Full-Width Green Button (`Close Traceability Details`)
* **Chips / Tabs / Buttons**:
  * `Pesticide-Free ✓` badge
  * `Close Traceability Details` button
* **Icons**: Magnifying glass, Leaf checkmark.

---

## Screen 29: Job Provider GPS Produce Search
* **Theme**: Light Theme with Map Interface
* **Approximate Hex Colors**: Header `#0D6548`, Map Pins `#00875A`, Background `#FFFFFF`.
* **Visible Texts**:
  * Header: `CUSTOMER REQUIRED FARM PRODUCE, ORGANIC SELLERS & OUTLETS NEAR ME` | `5 Live Pins`
  * Filter Chips: `All`, `Organic Veggies`, `Fresh Milk & Dairy`, `Fruit Orchards`
  * Map Overlay Pins: `₹120/kg`, `₹34/kg`, `₹450/500g`, `Walk-in Store`
  * Listing Header: `NEARBY GPS PIN LISTINGS (5)` | `Tap pin or card to inspect`
  * Listing 1: `Ravi Organic Vegetable Farm` | `Direct Farmer Ravi • Devanahalli Organic Cluster` | `1.5 km away` | `₹34/kg` | `Order Now`
  * Listing 2: `Pure A2 Gir Cow Milk Dairy` | `Pure A2 Dairy Farm • Koramangala 4th Block` | `0.5 km away` | `₹60/Liter` | `Order Now`
  * Listing 3: `Alphonso Mango & Guava Orchard` | `₹120/kg`
* **Element Order (Top to Bottom)**:
  1. Header Title & Live Pins Count Badge
  2. Produce Category Filter Chips (`All`, `Organic Veggies`, `Fresh Milk & Dairy`, `Fruit Orchards`)
  3. Interactive Map with price pins and zoom controls
  4. Draggable Bottom Sheet with pin listings header
  5. Vertical List of Farm Produce Listings (Photo thumbnail, Farm title, Farmer info, Distance, Price badge, `Order Now` green button)
  6. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * Category filter chips
  * Map price pins
  * `Order Now` buttons
* **Icons**: Vegetable basket, Milk bottle, Mango fruit, Map pins.

---

## Screen 30: Job Provider Subscriptions Screen
* **Theme**: Light Theme
* **Approximate Hex Colors**: Background `#F8FAFC`, Active Badge `#00875A`, Card White `#FFFFFF`.
* **Visible Texts**:
  * Top Card: `CONFIRMED BOOKING • BOOK-7842` | `Commercial Electrical Repair` (Summary Card)
  * Section Header: `DAILY FARM SUBSCRIPTIONS` | `+ New Subscription`
  * Subtitle: `Fresh morning milk & organic veggie boxes`
  * Item 1: `A2 Farm Milk Daily Subscription` | `Pure A2 Gir Cow Farm` | `Daily 2 Liters • 7:00 AM Doorstep` | `₹120/day` | `Active`
  * Item 2: `Weekly Organic Farm Vegetable Box` | `Ravi Organic Farm, Devanahalli` | `Every Saturday • 5 kg Assorted Box` | `₹350/week` | `Active`
  * Item 3: `Fresh Tender Coconut Morning Delivery` | `Mandya Palms Co-op` | `Every Alternate Day • 2 Nuts` | `₹80/delivery` | `Active`
* **Element Order (Top to Bottom)**:
  1. Top confirmed active booking summary card
  2. Daily Farm Subscriptions Section Header with `+ New Subscription` button
  3. Vertical List of Active Subscription Cards (Item icon/thumbnail, Title, Dairy/Farm producer, Schedule timing, Price rate, `Active` green badge)
  4. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * `+ New Subscription` button
  * `Active` status badges
* **Icons**: Milk glass, Veggie box, Tender coconut, Plus icon.

---

## Screen 31: Job Provider Chat Section
* **Theme**: Light Theme
* **Approximate Hex Colors**: Header `#0D6548`, Background `#F8FAFC`, Search `#F1F5F9`.
* **Visible Texts**:
  * Header: `UdyogaSethu Protected Inbox` | `4 Chats`
  * Subtitle: `Communicating via Secure Escrow Network`
  * Search Bar: `🔍 Search person, crop, job, or Booking ID...`
  * Status Filters: `All Chats (11)`, `Active (8)`, `Completed (3)`
  * Role Filters: `All Roles`, `Farmer Chats`, `Customer Chats`, `Worker Chats`
  * Safety Banner: `🔒 UdyogaSethu Safety: Phone & payment handles are masked for your privacy.`
  * Chat 1: `Ravi Organic Farm Ou...` | `VERIFIED FARMER SELLER` | `Weekly Organic Farm Vegetable Basket • BOOK-CUST-301` | `Active`
  * Chat 2: `Pure A2 Gir Cow Dairy` | `DIRECT FARMER DAIRY` | `Daily A2 Farm Milk Subscription (2 Liters) • BOOK-CUST-282` | `Active`
  * Chat 3: `Kaveri Fruit Orchar...` | `DIRECT ORCHARD FARMER` | `Alphonso Mango 5 kg Farm Box Order • BOOK-CUST-403` | `Active`
  * Chat 4: `Anita Verma` | `CUSTOMER` | `House Wall Painting & Touchup • BOOK-5184` | `Read-Only`
* **Element Order (Top to Bottom)**:
  1. Protected Inbox Header & 4 Chats badge
  2. Search Bar Input
  3. Status Filter Chips
  4. Role Filter Chips
  5. Privacy Shield Notice Banner
  6. Vertical List of Customer Conversations (Farm/Worker Avatar, Name, Category Badge, Order Details & Booking ID, Status pill (`Active` / `Read-Only`))
  7. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * Filter chips
  * Status pills (`Active`, `Read-Only`)
* **Icons**: Farm basket, Milk bottle, Mango, Paintbrush.

---

## Screen 32: Job Provider Profile Page
* **Theme**: Light Theme with Dark Green Top Header
* **Approximate Hex Colors**: Header `#0D6548`, Background `#F8FAFC`, Active Pill `#00875A`.
* **Visible Texts**:
  * Name: `Chethan Kumar` | `VERIFIED CUSTOMER ✓` | Edit Icon
  * Location: `Koramangala 4th Block, Bengaluru`
  * Phone: `+91 91234 56789`
  * Metric 1: `18` | `Farm Orders`
  * Metric 2: `2 Active` | `Subscriptions`
  * Metric 3: `₹1,250` | `Wallet Balance`
  * Section 1: `📍 DEFAULT DOORSTEP DELIVERY ADDRESS` | `Edit Address`
  * Address Box: `Chethan Kumar (Home)` | `Flat 302, Green Acres Apartments, Koramangala 4th Block, Bengaluru - 560034` | `Landmark: Opposite BDA Complex`
  * Section 2: `📦 ACTIVE DAILY SUBSCRIPTIONS`
  * Sub Item 1: `A2 Farm Milk Daily` | `2 Liters • Daily 7:00 AM` | `Active`
  * Sub Item 2: `Weekly Organic Veggie Box` | `5 kg Box • Saturday Delivery` | `Active`
  * Section 3: `LANGUAGE` | `EN`
  * Language Grid: `English`, `ಕನ್ನಡ`, `తెలుగు`, `हिंदी`, `தமிழ்`
* **Element Order (Top to Bottom)**:
  1. Dark Green Profile Header (Avatar, Name, Verified Customer badge, Location address, Phone number)
  2. 3 Metrics Columns (`18 Farm Orders`, `2 Active Subscriptions`, `₹1,250 Wallet Balance`)
  3. Default Doorstep Delivery Address Card with `Edit Address` button
  4. Active Daily Subscriptions Summary Card
  5. Language Selector Buttons Row
  6. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * `VERIFIED CUSTOMER ✓` badge
  * `Edit Address` button
  * `Active` subscription pills
  * Language buttons
* **Icons**: Profile avatar, Location pin, Wallet icon, Edit pencil, Milk glass, Veggie box.

---

# SECTION 2: PROTOTYPE SLIDE SCREENS

## Screen 33: Prototype User Interface / Home Page
* **Theme**: Dark Green Header Theme Variant
* **Approximate Hex Colors**: Header `#0D6548`, Quick Action Cards `#F8FAFC`, Hot Job Tag `#E65100`.
* **Visible Texts**:
  * Greeting: `Hello,` | `Chethan Kumar! 👋`
  * Location: `📍 Hegde Nagar, Bengaluru`
  * Search Bar: `🔍 Search for jobs, skills or services...` | Filter Icon
  * Section Header: `Quick Actions`
  * Action 1: `Nearby Jobs` | `12` | `Live jobs near you`
  * Action 2: `Daily Wage` | `₹800` | `Average wage`
  * Action 3: `Agri Orders` | `5` | `Active orders`
  * Section Header: `Featured Jobs` | `See All >`
  * Job Card 1: `🔥 Hot Job` | `Construction Helper` | `Sharma Builders ✓` | `₹600/day` | `📍 2km` | `★ 4.8 (127)` | `✓ Verified` | `Apply Now >`
  * Job Card 2: `🔥 Hot Job` | `Delivery Agent` | `Swiggy Partner ✓` | `₹700/day` | `📍 1.3km` | `★ 4.6 (89)` | `✓ Verified` | `Apply Now >`
  * SafePay Banner: `🔒 SafePay Protection` | `All payments are secured for your safety`
  * Bottom Nav: `Home`, `Jobs`, `Chat`, `Profile`
* **Element Order (Top to Bottom)**:
  1. Header with greeting, location, language toggle, notification bell, and user avatar
  2. Search bar with filter icon
  3. Quick Actions 3-column Card Row (`Nearby Jobs`, `Daily Wage`, `Agri Orders`)
  4. Featured Jobs Section Header (`See All >`)
  5. Horizontal Scrolling Featured Job Cards with `Hot Job` badge, title, employer, pay, rating, verified check, and `Apply Now >` button
  6. SafePay Protection Green Shield Banner
  7. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * `Hot Job` badge
  * `Apply Now >` button
  * `See All >` link
* **Icons**: Bell, Avatar, Map pin, Search glass, Filter sliders, Hardhat, Delivery bike, Shield lock.

---

## Screen 34: Prototype Job Posting & Payment Protection Detail
* **Theme**: Light Theme with Hero Image Header
* **Approximate Hex Colors**: Header Image Overlay `#0F172A`, Card White `#FFFFFF`, Apply Button `#00875A`.
* **Visible Texts**:
  * Header Overlay: Back Arrow (`←`), Share Icon (`<`)
  * Job Title: `Construction Helper`
  * Employer: `Sharma Builders ✓`
  * Specs Bar: `💼 ₹600/day` • `📍 2.0 km away` • `🚶 12 min walk`
  * Rating Line: `★ 4.8 (127 reviews)`
  * Badge: `✓ Verified Employee` | `Background verified`
  * Section Header: `Job Details`
  * Detail 1: `Duration` | `8 hours`
  * Detail 2: `Start Time` | `6:00 AM`
  * Detail 3: `Materials` | `Provided`
  * Detail 4: `Payment` | `Daily Cash / Escrow`
  * Detail 5: `Slots Open` | `5`
  * Section Header: `Description`
  * Description Text: `We are looking for a reliable construction helper to assist in daily site work. No prior experience required.`
  * Site Photos: Photo Preview Box
  * Bottom Actions: `💬 Chat` button | `✈️ Apply Now (Quick & Easy ✨)` button
* **Element Order (Top to Bottom)**:
  1. Top Hero Image Header with back arrow and share button
  2. Construction wrench icon overlay badge
  3. Job Title & Verified Employer Name
  4. Horizontal Specs Bar (Pay, Distance, Walking time)
  5. Rating Stars & Verified Employee Badge
  6. Job Details Table (Duration, Start time, Materials, Payment method, Slots open)
  7. Job Description Text Block & Site Image Thumbnail
  8. Bottom Action Bar (`Chat` secondary button + `Apply Now` green primary button)
* **Chips / Tabs / Buttons**:
  * `Verified Employee` badge
  * `Chat` button
  * `Apply Now (Quick & Easy ✨)` button
* **Icons**: Back arrow, Share, Wrench, Briefcase, Pin, Pedestrian, Star, Shield, Clock, Calendar, Tools, Wallet, People, Chat bubble, Send plane.

---

## Screen 35: Prototype Multilingual Support Screen
* **Theme**: Green Gradient Background Variant
* **Approximate Hex Colors**: Gradient Header `#0D6548` to `#00875A`, Card Background `#FFFFFF`.
* **Visible Texts**:
  * Headline: `Choose Your Language 👋`
  * Subtitle: `Pick your language to get the best experience in UdyogaSetu.`
  * Grid Card 1: `🇬🇧 English` | `English` (Selected Green Card with Check)
  * Grid Card 2: `🍃 ಕನ್ನಡ` | `Kannada`
  * Grid Card 3: `🇮🇳 हिंदी` | `Hindi`
  * Grid Card 4: `🏛️ తెలుగు` | `Telugu`
  * Grid Card 5: `🪷 मराठी` | `Marathi`
  * Grid Card 6: `🛕 தமிழ்` | `Tamil`
  * Grid Card 7: `🌉 বাংলা` | `Bengali`
  * Grid Card 8: `🛕 ଓଡ଼ିଆ` | `Odia`
  * Action Button: `Continue ->` (Orange/Green Gradient)
* **Element Order (Top to Bottom)**:
  1. Top Header with greeting headline & instruction subtitle
  2. 2-Column Grid of 8 Language Selection Cards with cultural/flag icons & radio select circles
  3. Bottom Full-Width Action Button (`Continue ->`)
* **Chips / Tabs / Buttons**:
  * 8 Language selector cards
  * `Continue ->` button
* **Icons**: Flag icons, Cultural landmarks, Radio selection circle with checkmark.

---

## Screen 36: Prototype Verification & Profile
* **Theme**: Light Theme with Dark Green Top Header
* **Approximate Hex Colors**: Header `#0D6548`, Card `#FFFFFF`, Check Green `#00875A`, Cross Red `#EF4444`.
* **Visible Texts**:
  * Profile Photo Circle: `CK` | Edit Pencil Icon
  * Name: `Chethan Kumar ✓`
  * User ID: `User ID: UDY20250078`
  * Phone: `📞 +91 81234 56789`
  * Metric 1: `27` | `Jobs Done`
  * Metric 2: `4.9` | `Rating ★★★★★`
  * Metric 3: `₹15K` | `Total Earning`
  * Section Header: `My Skills` | `Manage >`
  * Skill Pills: `🚜 Loader`, `🎨 Painter`, `🚚 Delivery`, `🛡️ Security`, `+ Add Skill`
  * Section Header: `Verification` | `View All >`
  * Item 1: `🪪 Aadhaar` | `✓`
  * Item 2: `👤 Profile` | `✓`
  * Item 3: `📞 Phone` | `✓`
  * Item 4: `🏦 Bank Account` | `✖`
  * Section Header: `Language` | `Change >`
  * Current Language: `🇬🇧 English` | `Default`
* **Element Order (Top to Bottom)**:
  1. Dark Green Profile Header (Avatar initial `CK`, Name, Verified check, User ID, Phone, Edit icon)
  2. 3 Metrics Columns (`27 Jobs Done`, `4.9 Rating`, `₹15K Total Earning`)
  3. My Skills Section with active skill pills and `+ Add Skill` button
  4. Verification Status List (Aadhaar, Profile, Phone verified green checks; Bank account red cross)
  5. Language Preference Selector Bar (`English Default`)
  6. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * Skill pills with icons
  * Verification status check/cross icons
  * `Manage >`, `View All >`, `Change >` link buttons
* **Icons**: Edit pencil, Star, Briefcase, Wallet, Aadhaar, Profile, Phone, Bank, Flag.

---

## Screen 37: Prototype Job History and Ratings
* **Theme**: Light Theme
* **Approximate Hex Colors**: Background `#F8FAFC`, Header `#FFFFFF`, Star Yellow `#F59E0B`.
* **Visible Texts**:
  * Header Section: `Language` | `🇬🇧 English` | `Change`
  * Section Header: `Job History`
  * History Item 1: `Construction Helper` | `JP Nagar, Bengaluru • 2d ago` | `₹600` | `★★★★★`
  * History Item 2: `Delivery Agent` | `Koramangala, Bengaluru • 5d ago` | `₹700` | `★★★★☆`
  * History Item 3: `Home Repair` | `HSR Layout, Bengaluru • 1w ago` | `₹800` | `★★★★★`
  * History Item 4: `House Cleaner` | `Indiranagar, Bengaluru • 1w ago` | `₹500` | `★★★★★`
  * Section Header: `Settings`
  * Setting 1: `📅 My Bookings >`
  * Setting 2: `🔒 Privacy >`
  * Setting 3: `🎧 Help & Support >`
* **Element Order (Top to Bottom)**:
  1. Top Language preference header card with `Change` button
  2. Job History Section Title
  3. Vertical List of Past Job Cards (Job Icon, Job Title, Location & Time ago, Earned wage, Rating stars)
  4. Settings Section Title
  5. List of Setting Navigation Rows (`My Bookings`, `Privacy`, `Help & Support`)
  6. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * `Change` language button
  * Setting navigation rows with right arrows (`>`)
* **Icons**: Hardhat, Delivery bike, Wrench, Broom, Calendar, Lock, Headset, Star ratings.

---

## Screen 38: Prototype Chat Section & Voice Assistance
* **Theme**: Light Theme Chat Interface with Green Banner
* **Approximate Hex Colors**: Top Bar `#1E293B`, Safety Banner `#ECFDF5`, Worker Bubble `#0D6548`, Employer Bubble `#F1F5F9`.
* **Visible Texts**:
  * Header: `← SK Sharma Builders ✓ • Online` | Call Icon | 3-dots Menu
  * Safety Banner: `✓ Safety First, Always` | `View Tips`
  * Message 1 (Employer, 10:30 AM): `"Hi Chethan! We need a loader for our site work at Jayanagar. Are you available?"`
  * Message 2 (Worker, 10:32 AM ✓✓): `"Yes, I'm available for work."`
  * Message 3 (Worker, 10:32 AM ✓✓): `"What will be the work details?"`
  * Message 4 (Employer, 10:35 AM): `"Work involves sand and material loading for 8 hours."`
  * Message 5 (Employer, 10:35 AM): `"₹600 per day. Payment after work. Are you okay with this?"`
  * Message 6 (Worker, 10:36 AM ✓✓): `"Yes sir, I'm okay with ₹600/day."`
  * Quick Suggestion Pills: `👋 Hello`, `👍 Thanks`, `📍 Location`, `📋 Work Info`, `💳 Payment`
  * Input Bar: `😊 Type a message...` | Paperclip Attach Icon | Send Button (Green Circle)
* **Element Order (Top to Bottom)**:
  1. Chat App Bar (Back arrow, Contact initials `SK`, Name with green check & online dot, Phone call icon, 3-dots menu)
  2. Green Safety First Banner (`View Tips` button)
  3. Message Stream (Alternating left/right speech bubbles with timestamps and read receipts `✓✓`)
  4. Horizontal Scrolling Quick Suggestion Chips Row (`Hello`, `Thanks`, `Location`, `Work Info`, `Payment`)
  5. Input Container (Emoji button, text field, paperclip attachment, green send button)
  6. Bottom Navigation Bar
* **Chips / Tabs / Buttons**:
  * `View Tips` button
  * 5 Quick reply suggestion pills
  * Send button
* **Icons**: Back arrow, Phone call, 3 dots, Shield check, Checkmarks (`✓✓`), Emoji, Paperclip attachment, Send plane.
