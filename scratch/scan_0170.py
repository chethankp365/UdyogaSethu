import json
import re
import sys

# Ensure UTF-8 output encoding for Windows terminal
sys.stdout.reconfigure(encoding='utf-8')

sql_file = r"c:\Users\cheth\Desktop\Udyoga Sethu\supabase\migrations\0170_student_parttime_skills.sql"

RANGES = {
    'kn': (0x0C80, 0x0CFF),  # Kannada
    'hi': (0x0900, 0x097F),  # Devanagari (Hindi)
    'te': (0x0C00, 0x0C7F),  # Telugu
    'ta': (0x0B80, 0x0BFF),  # Tamil
}

with open(sql_file, 'r', encoding='utf-8') as f:
    content = f.read()

jsonb_matches = re.findall(r"'(\{.*?\})'::jsonb", content)

errors = []
total_strings = 0

for json_str in jsonb_matches:
    try:
        data = json.loads(json_str)
        for lang, text in data.items():
            if lang not in RANGES:
                continue
            total_strings += 1
            min_codepoint, max_codepoint = RANGES[lang]

            for char in text:
                cp = ord(char)
                if cp < 128:
                    continue
                is_indian_char = any(r[0] <= cp <= r[1] for r in RANGES.values())
                if is_indian_char:
                    if not (min_codepoint <= cp <= max_codepoint):
                        errors.append(f"Mismatch in [{lang}] string '{text}': char '{char}' (U+{cp:04X}) belongs to wrong script")

    except json.JSONDecodeError as e:
        errors.append(f"JSON Parse error: {e} in string {json_str}")

print(f"Scanned {total_strings} localized strings across kn, hi, te, ta in 0170_student_parttime_skills.sql.")
if errors:
    print(f"FAILED: Found {len(errors)} script errors:")
    for err in errors:
        print("  -", err)
else:
    print("SUCCESS: 0 mixed script errors found! All kn, hi, te, ta strings use purely their own script.")
