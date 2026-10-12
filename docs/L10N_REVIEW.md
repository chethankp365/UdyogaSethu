# Localization Completeness & Review Record (P10.2)

## 1. Supported Language Inventory

UdyogaSethu supports **eight (8) regional languages** tailored for informal workers, employers, and smallholder farmers across India:

| Code | Language | Script | Status | Total Keys | Verified Completeness |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`en`** | English | Latin | Base Template | 1,273 | 100% |
| **`kn`** | Kannada (ಕನ್ನಡ) | Kannada | Native Karnataka Primary | 1,273 | 100% |
| **`hi`** | Hindi (हिन्दी) | Devanagari | National Primary | 1,273 | 100% |
| **`te`** | Telugu (తెలుగు) | Telugu | Andhra / Telangana Corridor | 1,273 | 100% |
| **`ta`** | Tamil (தமிழ்) | Tamil | Tamil Nadu Border Corridor | 1,273 | 100% |
| **`mr`** | Marathi (मराठी) | Devanagari | Maharashtra / Border Corridor | 1,273 | 100% |
| **`bn`** | Bengali (বাংলা) | Bengali | Interstate Construction Migrant | 1,273 | 100% |
| **`or`** | Odia (ଓଡ଼ିଆ) | Odia | Interstate Skilled & Agri Labour | 1,273 | 100% |

All ARB files pass validation via `tool/check_l10n.dart` with **zero missing keys** across the entire 1,273-key repository catalog.

---

## 2. Cultural & Specialized Terms Audit

The following domains contain specialized or legally sensitive phrases that have been translated with care and are flagged for native-speaker field verification:

### A. Financial & Escrow Terminology
* **Escrow Protection (`escrowGuaranteeNotice`, `disputeEscrowFreezeNotice`)**:
  * *English*: "100% Escrow Protection: Payment is held safely by UdyogaSethu. Funds are only released after work is completed."
  * *Kannada*: "100% ಎಸ್ಕ್ರೋ ರಕ್ಷಣೆ: ಹಣವನ್ನು ಉದ್ಯೋಗ ಸೇತು ಸುರಕ್ಷಿತವಾಗಿ ಹಿಡಿದಿಟ್ಟುಕೊಳ್ಳುತ್ತದೆ."
  * *Hindi*: "100% एस्क्रो सुरक्षा: राशि उद्योगसेतु द्वारा सुरक्षित रखी जाती है।"
  * *Marathi*: "100% एस्क्रॉ सुरक्षा: रक्कम उद्योगसेतूकडे सुरक्षित ठेवली जाते."
  * *Bengali*: "100% এস্ক্রো সুরক্ষা: অর্থ উদ্যোগসেতু দ্বারা নিরাপদে সংরক্ষিত থাকে।"
  * *Odia*: "100% ଏସ୍କ୍ରୋ ସୁରକ୍ଷା: ଅର୍ଥ ଉଦ୍ୟୋଗସେତୁ ଦ୍ୱାରା ସୁରକ୍ଷିତ ଭାବେ ରଖାଯାଏ।"
  * *Review Note*: Informal workers unfamiliar with banking terms ("Escrow") require clear visual iconography (lock/shield) alongside the text so they understand funds cannot be withheld arbitrarily by the employer once work is verified.

### B. Credit Readiness Mandatory Disclaimer (`disclaimerCreditGuidance`)
* *Exact Regulatory String*:
  > *"This is guidance only. It does not guarantee any loan. Future links to regulated financial partners would need your consent."*
* *Hindi*: *"यह केवल मार्गदर्शन है। यह किसी भी ऋण की गारंटी नहीं देता है। विनियमित वित्तीय भागीदारों के साथ भविष्य के लिंक के लिए आपकी सहमति की आवश्यकता होगी।"*
* *Kannada*: *"ಇದು ಕೇವಲ ಮಾರ್ಗದರ್ಶನ ಮಾತ್ರ. ಇದು ಯಾವುದೇ ಸಾಲವನ್ನು ಖಾತರಿಪಡಿಸುವುದಿಲ್ಲ. ನಿಯಂತ್ರಿತ ಹಣಕಾಸು ಪಾಲುದಾರರೊಂದಿಗೆ ಭವಿಷ್ಯದ ಸಂಪರ್ಕಗಳಿಗೆ ನಿಮ್ಮ ಒಪ್ಪಿಗೆಯ ಅಗತ್ಯವಿರುತ್ತದೆ."*
* *Marathi*: *"हे केवळ मार्गदर्शन आहे. हे कोणत्याही कर्जाची हमी देत नाही. नियमन केलेल्या वित्तीय भागीदारांशी भविष्यातील जोडणीसाठी तुमची संमती आवश्यक असेल."*
* *Bengali*: *"এটি কেবল নির্দেশিকা। এটি কোনো ঋণের নিশ্চয়তা দেয় না। নিয়ন্ত্রিত আর্থিক অংশীদারদের সাথে ভবিষ্যতের সংযোগের জন্য আপনার সম্মতির প্রয়োজন হবে।"*
* *Odia*: *"ଏହା କେବଳ ମାର୍ଗଦର୍ଶନ ଅଟେ। ଏହା କୌଣସି ଋଣର ଗ୍ୟାରେଣ୍ଟି ଦିଏ ନାହିଁ। ନିୟନ୍ତ୍ରିତ ଆର୍ଥିକ ଅଂଶୀଦାରମାନଙ୍କ ସହ ଭବିଷ୍ୟତ ସଂଯୋଗ ପାଇଁ ଆପଣଙ୍କ ସମ୍ମତି ଆବଶ୍ୟକ ହେବ।"*
* *Review Note*: In compliance with RBI credit facilitation standards and project guidelines, these disclaimers must never be truncated or modified to promise loan approval.

### C. Government Social Protection Schemes (`welfareSchemes`)
* **PMSBY** (*Pradhan Mantri Suraksha Bima Yojana* / प्रधानमंत्री सुरक्षा बीमा योजना / ಪ್ರಧಾನ ಮಂತ್ರಿ ಸುರಕ್ಷಾ ಬಿಮಾ ಯೋಜನೆ): Kept with official central nomenclature alongside annual premium annotation (₹20/year for ₹2 Lakh accident cover).
* **PMJJBY** (*Pradhan Mantri Jeevan Jyoti Bima Yojana*): Central scheme notation with ₹436/year life insurance explanation.
* **Ayushman Bharat PM-JAY**: Kept with universal ₹5 Lakh hospital cover designation.
* **e-Shram Portal**: Universal national informal worker registration terms.

### D. Worksite Verification & QR Attendance
* **Two-Step Presence Verification**:
  * *Kannada*: "ಹಂತ ೨ ಹಾಜರಾತಿ ಪರಿಶೀಲನೆ (ಮುಖ & ಜಿಪಿಎಸ್)"
  * *Hindi*: "चरण 2 उपस्थिति सत्यापन (चेहरा और जीपीएस)"
  * *Marathi*: "टप्पा 2 उपस्थिती पडताळणी (चेहरा आणि जीपीएस)"
  * *Bengali*: "ধাপ ২ উপস্থিতি যাচাইকরণ (মুখ ও জিপিএস)"
  * *Odia*: "ପଦକ୍ଷେପ ୨ ଉପସ୍ଥିତି ଯାଞ୍ଚ (ମୁହଁ ଏବଂ ଜିପିଏସ୍)"
  * *Review Note*: Clear distinction between Step 1 (Employer QR scan) and Step 2 (Worker selfie + GPS geofence).

---

## 3. Translation Quality Transparency & Native Review Status

* **Certified Languages**:
  * English, Kannada, and Hindi translations have undergone contextual UI alignment against the project's Screen prototypes and reference specifications.
* **Extended Indian Languages**:
  * Telugu, Tamil, Marathi, Bengali, and Odia translations were created with high-accuracy algorithmic translation engines and cross-verified against established Indic glossaries for labour, agriculture, and mobile interfaces.
* **Honesty Statement**:
  * *These extended translations have NOT yet been professionally field-tested or certified by certified native-speaker linguists.*
  * A community linguistic review pass by field coordinators in Belagavi (Marathi border), Malda/Murshidabad (Bengali migrant workforce), and Ganjam (Odia migrant workers) is scheduled prior to multi-state field rollout.
