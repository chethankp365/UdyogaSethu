import json
import re
import sys
import os

sys.stdout.reconfigure(encoding='utf-8')

RANGES = {
    'hi': (0x0900, 0x097F),  # Devanagari (Hindi, Marathi)
    'mr': (0x0900, 0x097F),  # Devanagari (Marathi)
    'bn': (0x0980, 0x09FF),  # Bengali
    'or': (0x0B00, 0x0B7F),  # Odia
    'ta': (0x0B80, 0x0BFF),  # Tamil
    'te': (0x0C00, 0x0C7F),  # Telugu
    'kn': (0x0C80, 0x0CFF),  # Kannada
    'ml': (0x0D00, 0x0D7F),  # Malayalam
}

files_to_scan = [
    r"c:\Users\cheth\Desktop\Udyoga Sethu\supabase\seed\seed_demo.sql",
    r"c:\Users\cheth\Desktop\Udyoga Sethu\supabase\migrations\0150_seed_skills.sql",
    r"c:\Users\cheth\Desktop\Udyoga Sethu\supabase\migrations\0170_student_parttime_skills.sql",
]

all_errors = []
total_scanned = 0

for file_path in files_to_scan:
    try:
        fname = os.path.basename(file_path)
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        jsonb_matches = re.findall(r"'(\{.*?\})'::jsonb", content)
        
        for json_str in jsonb_matches:
            try:
                data = json.loads(json_str)
                if not isinstance(data, dict):
                    continue
                for lang, text in data.items():
                    if lang not in RANGES or not isinstance(text, str):
                        continue
                    total_scanned += 1
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
                                all_errors.append(
                                    f"[{fname}] Language '{lang}' string '{text}': "
                                    f"character '{char}' (U+{cp:04X}) is from {script_name} script, expected {lang} (U+{min_cp:04X}-U+{max_cp:04X})"
                                )
            except json.JSONDecodeError:
                pass
    except Exception as e:
        print(f"Error reading {file_path}: {e}")

print(f"Scanned {total_scanned} localized JSON strings across seed and migration files.")
if all_errors:
    print(f"Found {len(all_errors)} script errors:")
    for err in all_errors:
        print("  -", err)
else:
    print("SUCCESS: 0 script errors found across all scanned files.")
