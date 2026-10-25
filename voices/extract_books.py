"""Collect readable books and notes and their English text."""

import json
import os
import sqlite3
import xml.etree.ElementTree as ET
from pathlib import Path

REDKIT = Path(os.environ.get("W3_REDKIT", ""))
if not REDKIT:
    raise SystemExit("Set W3_REDKIT to your REDkit r4data folder.")
ROOT = REDKIT
DB = ROOT / "LocalEditorStringDataBaseW3_UTF8.db"
OUT = Path(__file__).resolve().parent / "books.json"

SKIP_CATEGORIES = {
    "alchemy_recipe",
    "crafting_schematic",
    "crafting_recipe",
    "cooking_recipe",
    "recipe",
}

GLOBS = [
    ROOT / "gameplay" / "items",
    ROOT / "gameplay" / "items_plus",
]
for dlc in (ROOT / "dlc").glob("*"):
    GLOBS.append(dlc / "data" / "gameplay" / "items")
    GLOBS.append(dlc / "data" / "gameplay" / "items_plus")


def local_name(item):
    key = item.attrib.get("localisation_key_name")
    if key:
        return key.strip()
    for child in item:
        if child.tag == "localisation_key_name" and child.attrib.get("name"):
            return child.attrib["name"].strip()
    return ""


def tags_of(item):
    found = []
    for child in item:
        if child.tag == "tags":
            found.append("".join(child.itertext()))
    return ",".join(found)


def load_texts(keys):
    con = sqlite3.connect(DB)
    cur = con.cursor()
    wanted = {key + "_text": key for key in keys}
    texts = {}
    # Keys are stored space-padded to 128 characters.
    rows = cur.execute(
        """
        SELECT TRIM(i.STRING_KEY), s.TEXT, s.VERSION
        FROM STRING_INFO i
        JOIN STRINGS s ON s.STRING_ID = i.STRING_ID
        WHERE s.LANG = 2 AND TRIM(i.STRING_KEY) LIKE '%\\_text' ESCAPE '\\'
        """
    )
    best = {}
    for key, text, version in rows:
        if key not in wanted:
            continue
        old = best.get(key)
        if old is None or version >= old[0]:
            best[key] = (version, text or "")
    for key, (_version, text) in best.items():
        texts[wanted[key]] = text
    return texts


def main():
    items = []
    seen = set()
    files = []
    for folder in GLOBS:
        if folder.is_dir():
            files.extend(folder.glob("*.xml"))
    for path in files:
        try:
            raw = path.read_bytes()
            if raw.startswith(b"\xff\xfe") or raw.startswith(b"\xfe\xff"):
                xml_text = raw.decode("utf-16")
            else:
                xml_text = raw.decode("utf-8-sig")
            tree = ET.fromstring(xml_text)
        except (ET.ParseError, UnicodeError):
            continue
        for item in tree.iter("item"):
            name = (item.attrib.get("name") or "").strip()
            if not name or name in seen:
                continue
            tag_text = tags_of(item)
            if "ReadableItem" not in tag_text:
                continue
            category = (item.attrib.get("category") or "").strip()
            if category in SKIP_CATEGORIES:
                continue
            loc = local_name(item)
            if not loc:
                continue
            seen.add(name)
            items.append(
                {
                    "name": name,
                    "loc": loc,
                    "category": category,
                    "source": str(path.relative_to(ROOT)),
                }
            )

    texts = load_texts([item["loc"] for item in items])
    kept = []
    missing = []
    for item in items:
        text = texts.get(item["loc"], "")
        if not text or not text.strip():
            missing.append(item["name"])
            continue
        item["text"] = text
        item["chars"] = len(text)
        kept.append(item)

    kept.sort(key=lambda row: row["name"].lower())
    OUT.write_text(json.dumps(kept, ensure_ascii=False, indent=1), encoding="utf-8")
    chars = sum(row["chars"] for row in kept)
    print(f"files {len(files)}")
    print(f"readable {len(items)}")
    print(f"with text {len(kept)}")
    print(f"missing {len(missing)}")
    print(f"chars {chars}")
    if kept:
        longest = max(kept, key=lambda row: row["chars"])
        print(f"longest {longest['chars']} {longest['name']}")
    print("missing sample", missing[:12])


if __name__ == "__main__":
    main()
