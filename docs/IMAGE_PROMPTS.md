# UdyogaSethu - Image Asset Generation Prompts & Catalog

> **Status Notice (G1 / G5)**:
> Automated in-agent bulk WebP generation with specific size (<50 KB / <70 KB) and resolution constraints (800x450 / 600x600) directly into repository folders is not supported by native tools. Per **G1/G5 rules**, web downloading is strictly prohibited. All UI loaders are equipped with gradient and first-letter fallbacks. When assets are dropped into the asset directories, the UI picks them up immediately.
> Run `dart run tool/check_images.dart` at any time to verify filesystem status.

---

## 🎨 Global Art Direction & Style Guide (G4)

- **Style**: Warm, bright, clean digital illustration with soft photographic lighting.
- **Context**: Authentic Indian rural and semi-urban work settings, natural daylight, vibrant earth tones.
- **Rules**:
  - **NO text, letters, or typography** anywhere in the image.
  - **NO brand logos or trademarks**.
  - **NO recognizable real people or celebrities** (use generic, respectful, stylized worker silhouettes or hands/tools).
  - **Palette**: Natural greens, terracotta oranges, warm ambers, clean sky blues.
  - One consistent visual tone across all jobs and crops.

---

## 🛠️ Part 1: Job Category & Sub-Type Images (G2)
- **Target Resolution**: 800 × 450 px (16:9 widescreen)
- **Target File Size**: < 70 KB (WebP format)
- **Target Directory**: `assets/images/jobs/`

### 1. Electrician (`electrician`)
- **`assets/images/jobs/electrician-1.webp`** (Sub-type: Domestic Wiring)
  - **Prompt**: Clean warm illustration of an Indian electrician's hands in safety gloves testing an open residential switchboard using an insulated multimeter and screwdriver. Bright daylight, neat colorful copper wiring, Indian home interior setting, soft ambient lighting. No faces, no text.
- **`assets/images/jobs/electrician-2.webp`** (Sub-type: Ceiling Fan & Appliance Repair)
  - **Prompt**: Warm clean illustration of a modern white Indian ceiling fan being serviced on a wooden workbench with wire strippers, voltage tester, and electrical tape neatly arranged. Warm morning light, clean background. No text, no logos.

### 2. Plumbing (`plumbing`)
- **`assets/images/jobs/plumbing-1.webp`** (Sub-type: Pipeline & PVC Fitting)
  - **Prompt**: Warm bright illustration of brass pipe fittings, PVC plumbing pipes, and an adjustable wrench on a tiled bathroom floor in an Indian household. Clean water droplets, crisp tools, professional aesthetic. No text.
- **`assets/images/jobs/plumbing-2.webp`** (Sub-type: Tap & Faucet Installation)
  - **Prompt**: Stylized soft photograph illustration of a chrome quarter-turn bathroom faucet being tightened onto a granite washbasin counter using Teflon tape and pliers. Warm morning light, clean reflection, no text.

### 3. Carpenter (`carpenter`)
- **`assets/images/jobs/carpenter-1.webp`** (Sub-type: Furniture Crafting)
  - **Prompt**: Warm illustration of seasoned teakwood timber and wood planer with fine curly wood shavings on an Indian carpentry workbench, wood chisel and steel measuring tape beside it. Golden sunlight, authentic workshop ambiance. No text.
- **`assets/images/jobs/carpenter-2.webp`** (Sub-type: Door & Frame Fitting)
  - **Prompt**: Warm illustration of a solid wooden panel door frame with brass hinges being checked with a spirit level tool. Soft indoor natural light, smooth sanded wood texture, clean Indian home doorway. No text.

### 4. Painting (`painting`)
- **`assets/images/jobs/painting-1.webp`** (Sub-type: Interior Wall Painting)
  - **Prompt**: Warm bright illustration of a paint roller applying a fresh coat of warm pastel sage green paint to a smooth interior plaster wall, paint tray with roller beside masking tape. Bright airy room, no text, no brand logos.
- **`assets/images/jobs/painting-2.webp`** (Sub-type: Exterior Facade & Texture)
  - **Prompt**: Clean illustration of an exterior Indian house wall with terracotta textured paint, sturdy bamboo ladder, paint bucket, and wide flat brush resting neatly. Warm sunlit courtyard setting. No text.

### 5. Cleaning & Housekeeping (`cleaner`)
- **`assets/images/jobs/cleaner-1.webp`** (Sub-type: Home Living Area)
  - **Prompt**: Bright welcoming illustration of an immaculate Indian living room with gleaming vitrified tiles, microfiber mop, natural spray bottle, and clean dusting cloth arranged in an organized caddy. Sunbeams streaming through window, dust-free sparkle. No text.
- **`assets/images/jobs/cleaner-2.webp`** (Sub-type: Bathroom Deep Cleaning)
  - **Prompt**: Clean bright illustration of sparkling clean bathroom ceramic tiles, squeeze wiper, scrubbing brush, and natural cleaning essentials in a tidy bucket. Crisp fresh hygiene aesthetic. No text.

### 6. Construction (`construction`)
- **`assets/images/jobs/construction-1.webp`** (Sub-type: Structural Concrete & Site)
  - **Prompt**: Warm illustration of a clean construction site with freshly cured concrete column, yellow safety helmet resting on steel reinforcement rebar, measuring tape, and blueprint rolled up. Morning golden hour sun. No text.
- **`assets/images/jobs/construction-2.webp`** (Sub-type: Scaffolding & Framework)
  - **Prompt**: Clean architectural illustration of an Indian residential building framework with safety netting, scaffolding poles, and clean cement work against a clear blue sky. Professional build site. No text.

### 7. Masonry (`mason`)
- **`assets/images/jobs/mason-1.webp`** (Sub-type: Bricklaying)
  - **Prompt**: Warm illustration of neat red clay bricks being laid in straight course with fresh cement mortar, steel trowel and plumb bob plumb line resting nearby. Crisp construction craft, sunny outdoor setting. No text.
- **`assets/images/jobs/mason-2.webp`** (Sub-type: Floor Tiling & Granite)
  - **Prompt**: Clean illustration of polished ceramic floor tiles being aligned with tile spacers and rubber mallet on a thin-set mortar bed. Sharp geometric perfection, soft interior light. No text.

### 8. Loading & Shifting (`loader`)
- **`assets/images/jobs/loader-1.webp`** (Sub-type: Warehouse Logistics)
  - **Prompt**: Warm illustration of neatly stacked corrugated cardboard moving boxes on a wooden pallet inside a clean Indian warehouse, hand trolley cart and packing tape dispenser resting beside. Warm ambient warehouse light. No text.
- **`assets/images/jobs/loader-2.webp`** (Sub-type: House Shifting & Packing)
  - **Prompt**: Clean illustration of bubble-wrapped furniture, packed cartons with fragile labels, and heavy-duty moving dolly cart inside the back of a covered mini tempo truck. Organized relocation scene. No text.

### 9. Driver (`driver`)
- **`assets/images/jobs/driver-1.webp`** (Sub-type: Commercial Cab & Chauffeur)
  - **Prompt**: Warm illustration from driver perspective of a clean car dashboard with polished steering wheel, GPS smartphone mount, and open paved Karnataka highway stretching ahead in daylight. Clear windshield view, no text.
- **`assets/images/jobs/driver-2.webp`** (Sub-type: Cargo Goods Tempo)
  - **Prompt**: Clean illustration of a commercial small transport vehicle parked neatly at a logistics loading bay with rear doors open, secured goods inside, sunny morning backdrop. No text.

### 10. Agricultural Labour (`agri_labour`)
- **`assets/images/jobs/agri_labour-1.webp`** (Sub-type: Harvest & Threshing)
  - **Prompt**: Warm sunlit illustration of lush golden paddy field in rural Karnataka with traditional curved sickle resting on bundled harvested sheaves. Morning mist, green palm trees on horizon, rustic agrarian beauty. No text.
- **`assets/images/jobs/agri_labour-2.webp`** (Sub-type: Plantation & Weeding)
  - **Prompt**: Vibrant clean illustration of green vegetable farm rows with drip irrigation pipes and weeding hoe resting against rich red loam soil. Healthy tomato plants with morning dew. No text.

### 11. Domestic Help & Cooking (`domestic_help`)
- **`assets/images/jobs/domestic_help-1.webp`** (Sub-type: Traditional Kitchen Cooking)
  - **Prompt**: Warm inviting illustration of a clean Indian kitchen counter with stainless steel spice box (masala dabba), brass tadka pan, fresh curry leaves, and rolled chapatis on rolling board. Steaming warmth, homey cooking vibe. No text.
- **`assets/images/jobs/domestic_help-2.webp`** (Sub-type: Housekeeping & Organization)
  - **Prompt**: Clean bright illustration of freshly folded cotton laundry stacked neatly beside an iron and wicker basket in a tidy airy Indian home. Morning sunlight, cozy domestic order. No text.

### 12. Logistics & Delivery (`delivery`)
- **`assets/images/jobs/delivery-1.webp`** (Sub-type: Two-Wheeler Parcel Courier)
  - **Prompt**: Warm illustration of a courier parcel bag mounted on the pillion of a motorcycle with sealed delivery packages, helmet hanging from handle, quiet tree-lined Indian street. Sunny afternoon. No text.
- **`assets/images/jobs/delivery-2.webp`** (Sub-type: Van Delivery)
  - **Prompt**: Clean illustration of a white courier delivery van with side cargo sliding door open showing sorted organized parcel boxes. Clean suburban Indian avenue, morning light. No text.

### 13. Food & Quick Delivery (`delivery-gig-work`)
- **`assets/images/jobs/delivery-gig-work-1.webp`** (Sub-type: Insulated Thermal Bag)
  - **Prompt**: Bright vibrant illustration of a modern insulated food delivery backpack resting on an electric scooter seat, fresh brown paper grocery bags beside. Urban Bengaluru street background, modern gig economy aesthetic. No text.
- **`assets/images/jobs/delivery-gig-work-2.webp`** (Sub-type: Quick Grocery Package)
  - **Prompt**: Clean stylized illustration of packaged grocery box containing fresh milk, fruits, and bread ready for instant delivery on a pickup counter. Clean, fast, modern feel. No text.

### 14. Retail & Food Service (`retail-food-service`)
- **`assets/images/jobs/retail-food-service-1.webp`** (Sub-type: Retail Counter & Billing)
  - **Prompt**: Clean bright illustration of a modern supermarket retail checkout counter with barcode scanner, POS card terminal, and neat grocery items arranged on conveyor. Friendly organized shop setting. No text.
- **`assets/images/jobs/retail-food-service-2.webp`** (Sub-type: Cafe Barista Counter)
  - **Prompt**: Warm illustration of an Indian specialty coffee counter with shiny espresso machine portafilter, glass display with baked pastries, and fresh coffee beans in glass jar. Warm coffee shop glow. No text.

### 15. Content Writing & Translation (`content-writing`)
- **`assets/images/jobs/content-writing-1.webp`** (Sub-type: Creative Typing & Articles)
  - **Prompt**: Warm aesthetic illustration of a sleek laptop open to an article draft, fountain pen resting on a ruled notebook, ceramic cup of chai, and glasses on a wooden desk. Natural daylight from window. No text.
- **`assets/images/jobs/content-writing-2.webp`** (Sub-type: Multilingual Translation & Proofreading)
  - **Prompt**: Clean illustration of bilingual reference dictionaries, highlighter pens, sticky notes, and tablet display on a study desk. Academic focus, warm library lighting. No text.

### 16. Design & Digital Work (`design-data-work`)
- **`assets/images/jobs/design-data-work-1.webp`** (Sub-type: Graphic Design & Creative)
  - **Prompt**: Vibrant clean illustration of a designer workspace with graphics drawing tablet and stylus, color swatch fan deck, wireless mouse, and modern monitor showing colorful vector shapes. Creative studio vibe. No text.
- **`assets/images/jobs/design-data-work-2.webp`** (Sub-type: Data Entry & Spreadsheets)
  - **Prompt**: Clean minimalist illustration of an ergonomic office desk with numeric keypad, spreadsheet dashboard on monitor, wireless keyboard, and potted succulent plant. Productive digital workplace. No text.

### 17. Tutoring & Academics (`tutoring-academics`)
- **`assets/images/jobs/tutoring-academics-1.webp`** (Sub-type: Home Tuition Study)
  - **Prompt**: Warm inviting illustration of a clean study table with open mathematics textbook, geometry box with compass, neatly sharpened pencils, and globe in soft desk lamp glow. Encouraging academic atmosphere. No text.
- **`assets/images/jobs/tutoring-academics-2.webp`** (Sub-type: Online Tutoring & STEM)
  - **Prompt**: Modern clean illustration of a digital whiteboard tablet, headset with microphone, chemistry molecule model, and notebooks on an e-learning desk. Bright educational setting. No text.

### 18. Campus & Brand Promotion (`campus-brand-promotion`)
- **`assets/images/jobs/campus-brand-promotion-1.webp`** (Sub-type: Event Kiosk)
  - **Prompt**: Bright vibrant illustration of a college festival outdoor promotion kiosk with promotional standee banners, roll-up booth counter, flyers, and festive campus trees in sunny afternoon. Energetic youth atmosphere. No text.
- **`assets/images/jobs/campus-brand-promotion-2.webp`** (Sub-type: Brand Ambassador Kit)
  - **Prompt**: Clean illustration of a promotional merchandise kit including customized canvas tote bag, lanyard ID badge, branded notebook, and megaphone resting on a table. Vibrant promotional marketing setup. No text.

### 19. Gardening & Landscaping (`gardener`)
- **`assets/images/jobs/gardener-1.webp`** (Sub-type: Lawn & Pruning)
  - **Prompt**: Warm lush illustration of pruning shears, gardening trowel, and terracotta plant pots on a freshly manicured green lawn in an Indian home garden. Blooming bougainvillea and morning sun. No text.
- **`assets/images/jobs/gardener-2.webp`** (Sub-type: Nursery & Planting)
  - **Prompt**: Rich green illustration of healthy young saplings in black nursery bags, brass watering can with gentle spray, and rich organic compost soil. Vibrant nursery ambiance. No text.

### 20. General Work (`general`)
- **`assets/images/jobs/general-1.webp`**
  - **Prompt**: Clean warm illustration of an all-purpose utility toolkit with durable cloth bag, measuring tape, cotton work gloves, flashlight, and multipurpose hand tools. Professional daily assistance. No text.
- **`assets/images/jobs/general-2.webp`**
  - **Prompt**: Warm illustration of an Indian community centre courtyard with tidy stacked folding chairs, broom, and organized event supplies ready for daily utility helper tasks. Crisp morning light. No text.

---

## 🌾 Part 2: Mandi Crop & Commodity Images (G3)
- **Target Resolution**: 600 × 600 px (1:1 square)
- **Target File Size**: < 50 KB (WebP format)
- **Target Directory**: `assets/images/commodities/`

| Commodity | Kannada | Hindi | Target File | Ready-to-Paste Image Generation Prompt |
|:---|:---|:---|:---|:---|
| **Tomato** | ಟೊಮೇಟೊ | टमाटर | `tomato.webp` | Stylized soft photographic illustration of ripe bright red Indian desi tomatoes with green calyx on a rustic jute sack, fresh water droplets, soft morning sun, clean neutral background. 600x600 square, no text. |
| **Onion** | ಈರುಳ್ಳಿ | प्याज | `onion.webp` | Clean warm illustration of fresh firm red Bellary onions with papery skin on wooden cutting board, natural lighting, Indian kitchen setting. 600x600 square, no text. |
| **Potato** | ಆಲೂಗಡ್ಡೆ | आलू | `potato.webp` | Warm clean illustration of freshly dug golden Jyoti potatoes resting on clean brown burlap, gentle soil dusting, soft ambient light. 600x600 square, no text. |
| **Banana** | ಬಾಳೆಹಣ್ಣು | केला | `banana.webp` | Bright vibrant illustration of a bunch of ripe golden yellow Yelakki bananas on a green banana leaf, clean background, warm daylight. 600x600 square, no text. |
| **Green Chilli** | ಹಸಿಮೆಣಸಿನಕಾಯಿ | हरी मिर्च | `green_chilli.webp` | Crisp clean illustration of shiny fresh green Indian chillies in a small wicker basket, water droplets, bright natural light. 600x600 square, no text. |
| **Brinjal** | ಬದನೆಕಾಯಿ | बैंगन | `brinjal.webp` | Rich vibrant illustration of glossy purple Indian round brinjals with fresh green stems, clean studio lighting on light wood surface. 600x600 square, no text. |
| **Cabbage** | ಎಲೆಕೋಸು | पत्ता गोभी | `cabbage.webp` | Clean illustration of fresh tight green cabbage head with outer leaf layers on slate backdrop, crisp natural daylight. 600x600 square, no text. |
| **Cauliflower** | ಹೂಕೋಸು | फूलगोभी | `cauliflower.webp` | Fresh clean illustration of pristine white cauliflower curd surrounded by crisp green protective leaves on neutral surface. 600x600 square, no text. |
| **Carrot** | ಕ್ಯಾರೆಟ್ | गाजर | `carrot.webp` | Warm vibrant illustration of fresh crunchy orange carrots with green leafy carrot tops tied with twine on wooden table. 600x600 square, no text. |
| **Beans** | ಹುರುಳಿಕಾಯಿ | बीन्स | `beans.webp` | Fresh clean illustration of crisp slender green French beans in a neat bundle on a rustic linen cloth. 600x600 square, no text. |
| **Ladies Finger** | ಬೆಂಡೆಕಾಯಿ | भिंडी | `ladies_finger.webp` | Crisp illustration of fresh tender green Okra (ladies finger) pods arranged neatly on a clay plate, natural lighting. 600x600 square, no text. |
| **Cucumber** | ಸೌತೆಕಾಯಿ | खीरा | `cucumber.webp` | Refreshing clean illustration of crisp dark green Indian field cucumbers with one crosscut slice showing juicy seeds. 600x600 square, no text. |
| **Pumpkin** | ಕುಂಬಳಕಾಯಿ | कद्दू | `pumpkin.webp` | Warm illustration of a whole ribbed golden-orange Indian pumpkin resting on hay in an Indian farm barn. 600x600 square, no text. |
| **Coconut** | ತೆಂಗಿನಕಾಯಿ | नारियल | `coconut.webp` | Clean warm illustration of a mature brown fibrous coconut alongside a fresh coconut half showing white meat and water. 600x600 square, no text. |
| **Mango** | ಮಾವಿನಹಣ್ಣು | आम | `mango.webp` | Warm golden illustration of ripe juicy Alphonso and Badami mangoes with green mango leaf on wooden table. 600x600 square, no text. |
| **Grapes** | ದ್ರಾಕ್ಷಿ | अंगूर | `grapes.webp` | Lustrous clean illustration of a bunch of sweet green seedless grapes on vine in morning light. 600x600 square, no text. |
| **Pomegranate** | ದಾಳಿಂಬೆ | अनार | `pomegranate.webp` | Vibrant rich illustration of a ripe red Bhagwa pomegranate partially split open revealing ruby-red aril seeds. 600x600 square, no text. |
| **Papaya** | ಪಪ್ಪಾಯಿ | पपीता | `papaya.webp` | Warm illustration of a ripe golden-green Red Lady papaya with one sliced half showing black seeds. 600x600 square, no text. |
| **Lemon** | ನಿಂಬೆಹಣ್ಣು | नींबू | `lemon.webp` | Bright zesty illustration of small yellow Kagzi lemons with one cut wedge on a marble surface. 600x600 square, no text. |
| **Paddy** | ಭತ್ತ | धान | `paddy.webp` | Golden warm illustration of mature golden paddy rice grains still on ear heads in a woven bamboo basket. 600x600 square, no text. |
| **Wheat** | ಗೋಧಿ | गेहूं | `wheat.webp` | Warm sunlit illustration of golden wheat grains overflowing from a brass measuring vessel (padi). 600x600 square, no text. |
| **Ragi** | ರಾಗಿ | रागी | `ragi.webp` | Clean illustration of rustic reddish-brown finger millet (ragi) grains piled in a traditional earthen pot. 600x600 square, no text. |
| **Maize** | ಮುಸುಕಿನ ಜೋಳ | मक्का | `maize.webp` | Bright illustration of fresh yellow sweet corn cobs with partially peeled green husk showing plump golden kernels. 600x600 square, no text. |
| **Jowar** | ಜೋಳ | ज्वार | `jowar.webp` | Clean illustration of pearly cream Maldandi sorghum (jowar) grains in a shallow terracotta bowl. 600x600 square, no text. |
| **Bajra** | ಸಜ್ಜೆ | बाजरा | `bajra.webp` | Warm rustic illustration of greenish-gray pearl millet (bajra) grains on woven winnowing basket. 600x600 square, no text. |
| **Tur Dal** | ತೊಗರಿ ಬೇಳೆ | अरहर दाल | `tur_dal.webp` | Clean vibrant illustration of polished golden-yellow split pigeon peas (tur dal / arhar dal) in a bowl. 600x600 square, no text. |
| **Bengal Gram** | ಕಡಲೆ | चना | `bengal_gram.webp` | Warm illustration of whole brown desi chana (bengal gram) grains on clean gunny sack. 600x600 square, no text. |
| **Groundnut** | ಕಡಲೆಕಾಯಿ | मूंगफली | `groundnut.webp` | Warm earthy illustration of dried groundnut pods with a few cracked open showing red-skinned peanut kernels. 600x600 square, no text. |
| **Sunflower** | ಸೂರ್ಯಕಾಂತಿ | सूरजमुखी | `sunflower.webp` | Bright illustration of black striped sunflower oilseeds with bright yellow sunflower petals behind them. 600x600 square, no text. |
| **Sugarcane** | ಕಬ್ಬು | गन्ना | `sugarcane.webp` | Clean illustration of freshly cut thick purple and green sugarcane stalks tied with cord in sunlit field. 600x600 square, no text. |
| **Cotton** | ಹತ್ತಿ | कपास | `cotton.webp` | Soft clean illustration of fluffy white raw cotton bolls in brown calyx against a soft sky blue backdrop. 600x600 square, no text. |
| **Turmeric** | ಅರಿಶಿನ | हल्दी | `turmeric.webp` | Vibrant warm illustration of fresh golden-orange turmeric rhizome fingers and pure turmeric powder in brass bowl. 600x600 square, no text. |
| **Ginger** | ಶುಂಠಿ | अदरक | `ginger.webp` | Earthy clean illustration of fresh knobby ginger root with light soil dusting on wooden board. 600x600 square, no text. |
| **Garlic** | ಬೆಳ್ಳುಳ್ಳಿ | लहसुन | `garlic.webp` | Crisp clean illustration of whole white garlic bulbs with purple streaks and several separated cloves. 600x600 square, no text. |
| **Cardamom** | ಏಲಕ್ಕಿ | इलायची | `cardamom.webp` | Elegant fragrant illustration of plump green cardamom pods (chhoti elaichi) on dark slate surface. 600x600 square, no text. |
| **Black Pepper** | ಕಾಳುಮೆಣಸು | काली मिर्च | `pepper.webp` | Dramatic clean illustration of aromatic dried black peppercorns (kali mirch) in an olive wood bowl. 600x600 square, no text. |
| **Areca Nut** | ಅಡಿಕೆ | सुपारी | `arecanut.webp` | Traditional illustration of dried cured brown areca nut (supari / betel nut) halves on brass thali. 600x600 square, no text. |
| **Coffee** | ಕಾಫಿ | कॉफ़ी | `coffee.webp` | Warm aromatic illustration of roasted dark Arabica coffee beans and ripe red coffee cherries on burlap. 600x600 square, no text. |
| **Marigold** | ಚೆಂಡುಹೂ | गेंदा | `marigold.webp` | Vibrant festive illustration of dense bright orange and yellow marigold flowers in a brass puja vessel. 600x600 square, no text. |
| **Rose** | ಗುಲಾಬಿ | गुलाब | `rose.webp` | Elegant clean illustration of fragrant velvety red Indian country roses (desi gulab) with fresh green leaves. 600x600 square, no text. |

---

## 🚀 Execution & Verification
To verify the asset manifests and inspect which image files currently exist on disk versus which use gradient fallbacks, run:

```powershell
dart run tool/check_images.dart
```
