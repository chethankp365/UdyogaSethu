import json
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

RANGES = {
    'hi': (0x0900, 0x097F),  # Devanagari (Hindi)
    'mr': (0x0900, 0x097F),  # Devanagari (Marathi)
    'bn': (0x0980, 0x09FF),  # Bengali
    'or': (0x0B00, 0x0B7F),  # Odia
    'ta': (0x0B80, 0x0BFF),  # Tamil
    'te': (0x0C00, 0x0C7F),  # Telugu
    'kn': (0x0C80, 0x0CFF),  # Kannada
    'ml': (0x0D00, 0x0D7F),  # Malayalam
}

with open(r"c:\Users\cheth\Desktop\Udyoga Sethu\supabase\seed\seed_demo.sql", "r", encoding="utf-8") as f:
    lines = f.readlines()

cat_lines = []
in_cat = False
for line in lines:
    if "INSERT INTO public.service_categories" in line:
        in_cat = True
    if in_cat:
        cat_lines.append(line)
        if "ON CONFLICT" in line:
            in_cat = False

print("Category Seed Section in seed_demo.sql:")
category_errors = []

for line in cat_lines:
    jsonb_match = re.search(r"'(\{.*?\})'::jsonb", line)
    if jsonb_match:
        slug_match = re.search(r"'([a-z_]+)'", line)
        slug = slug_match.group(1) if slug_match else 'unknown'
        json_str = jsonb_match.group(1)
        data = json.loads(json_str)
        for lang, text in data.items():
            if lang not in RANGES:
                continue
            min_cp, max_cp = RANGES[lang]
            for char in text:
                cp = ord(char)
                if cp < 128:
                    continue
                is_indic = any(r[0] <= cp <= r[1] for r in RANGES.values())
                if is_indic:
                    if not (min_cp <= cp <= max_cp):
                        script_name = "Unknown"
                        for s, r in RANGES.items():
                            if r[0] <= cp <= r[1]:
                                script_name = s
                                break
                        category_errors.append({
                            'slug': slug,
                            'lang': lang,
                            'text': text,
                            'char': char,
                            'char_hex': f"U+{cp:04X}",
                            'found_script': script_name,
                            'expected_script': lang,
                        })

if category_errors:
    print(f"\nFound {len(category_errors)} script errors in category seeds in seed_demo.sql:\n")
    for err in category_errors:
        print(f"Slug: '{err['slug']}', Lang: '{err['lang']}', Current Text: '{err['text']}'")
        print(f"  -> Char '{err['char']}' ({err['char_hex']}) belongs to '{err['found_script']}' script, expected '{err['expected_script']}'\n")
else:
    print("\nNo script errors found in category seeds in seed_demo.sql!")
