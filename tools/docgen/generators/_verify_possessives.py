"""One-off: determine which gear-name first-words are possessives that BG-Wiki
spells with an apostrophe (Judges -> Judge's) vs. proper nouns that aren't
(Murgleis, Magus, Dynamis). We can't tell these apart by spelling, so we ask
BG-Wiki directly: HEAD the candidate's description image with each apostrophe
form and keep whichever returns 200.

Writes _possessive_names.json next to gear_finder.py: {word: apostrophe_form}.
Run once (needs network); the generator just reads the cached map afterwards.
"""
from __future__ import annotations
import hashlib, json, re
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from urllib.parse import quote
from urllib.request import Request, urlopen

HERE = Path(__file__).resolve().parent
DATA = HERE.parent.parent.parent / "docs" / "assets" / "gear-data.json"
OUT = HERE / "_possessive_names.json"

UA = {"User-Agent": "Mozilla/5.0 (gear-finder possessive check)"}


def img_url(filename: str) -> str:
    h = hashlib.md5(filename.encode("utf-8")).hexdigest()
    return f"https://www.bg-wiki.com/images/{h[0]}/{h[:2]}/{quote(filename)}"


def ok(filename: str) -> bool:
    try:
        req = Request(img_url(filename), method="HEAD", headers=UA)
        return urlopen(req, timeout=10).status == 200
    except Exception:
        return False


def candidates() -> dict[str, str]:
    """{first_word: representative full item name} for multi-word names whose
    first word ends in a single 's'."""
    d = json.loads(DATA.read_text(encoding="utf-8"))
    rep: dict[str, str] = {}
    for it in d["items"]:
        toks = it["n"].split(" ")
        if len(toks) < 2:
            continue
        w = toks[0]
        if len(w) < 3 or not w.endswith("s") or w.endswith("ss"):
            continue
        if not re.match(r"^[A-Za-z]", toks[1]):
            continue
        rep.setdefault(w, it["n"])
    return rep


def classify(word_and_name):
    word, name = word_and_name
    before = word[:-1] + "'" + word[-1]          # Judges -> Judge's
    trailing = word + "'"                          # Ares   -> Ares'
    for form in (before, trailing):
        fn = name.replace(word, form, 1).replace(" ", "_") + "_description.png"
        if ok(fn):
            return word, form
    return word, None


def main():
    reps = candidates()
    print(f"{len(reps)} candidate words; querying BG-Wiki…")
    found = {}
    with ThreadPoolExecutor(max_workers=10) as ex:
        for word, form in ex.map(classify, reps.items()):
            if form:
                found[word] = form
    found = dict(sorted(found.items()))
    OUT.write_text(json.dumps(found, indent=0, ensure_ascii=False), encoding="utf-8")
    print(f"possessive words: {len(found)} / {len(reps)}")
    print("sample:", dict(list(found.items())[:20]))


if __name__ == "__main__":
    main()
