"""Helper: print itemId, shortName, candidate BG-Wiki URL for each naked item.

The URL is best-effort; we also keep a manual override table for items whose
canonical wiki name doesn't follow simple Capitalize_Words.
"""
import json
import os
import urllib.parse

REPO = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))
AUDIT = os.path.join(REPO, "tools", "gear_stat_audit.json")

# Manual overrides for items whose canonical wiki name differs from the
# capitalized-shortname.  Add new entries as needed.
WIKI_OVERRIDES = {
    # apostrophes
    "plunderers_bonnet_+3":   "Plun. Bonnet +3",
    "plunderers_vest_+3":     "Plun. Vest +3",
    "plunderers_armlets_+3":  "Plun. Armlets +3",
    "plunderers_culottes_+3": "Plun. Culottes +3",
    "plunderers_poulaines_+3":"Plun. Poulaines +3",
    "fallens_burgeonet_+3":   "Fall. Burgeonet +3",
    "fallens_cuirass_+3":     "Fall. Cuirass +3",
    "fallens_finger_gaunt._+3": "Fall. Finger Gauntlets +3",
    "fallens_finger_gauntlets_+3": "Fall. Finger Gauntlets +3",
    "fallens_flanchard_+3":   "Fall. Flanchard +3",
    "fallens_sollerets_+3":   "Fall. Sollerets +3",
    "skulkers_bonnet_+3":     "Skulker's Bonnet +3",
    "skulkers_vest_+3":       "Skulker's Vest +3",
    "skulkers_armlets_+3":    "Skulker's Armlets +3",
    "skulkers_culottes_+3":   "Skulker's Culottes +3",
    "skulkers_poulaines_+3":  "Skulker's Poulaines +3",
    "heathens_burgeonet_+3":  "Heathen's Burgeonet +3",
    "heathens_cuirass_+3":    "Heathen's Cuirass +3",
    "heathens_gauntlets_+3":  "Heathen's Gauntlets +3",
    "heathens_flanchard_+3":  "Heathen's Flanchard +3",
    "heathens_sollerets_+3":  "Heathen's Sollerets +3",
    "beckoners_horn_+3":      "Beckoner's Horn +3",
    "beckoners_doublet_+3":   "Beckoner's Doublet +3",
    "beckoners_bracers_+3":   "Beckoner's Bracers +3",
    "beckoners_spats_+3":     "Beckoner's Spats +3",
    "beckoners_pigaches_+3":  "Beckoner's Pigaches +3",
    "moms_bonnet_+3":         "Mummer's Bonnet +3",  # likely not this — placeholder
    "convokers_horn_+3":      "Convoker's Horn +3",
    "convokers_doublet_+3":   "Convoker's Doublet +3",
    "convokers_bracers_+3":   "Convoker's Bracers +3",
    "convokers_spats_+3":     "Convoker's Spats +3",
    "convokers_pigaches_+3":  "Convoker's Pigaches +3",
}


def candidate_name(short_name: str) -> str:
    if short_name in WIKI_OVERRIDES:
        return WIKI_OVERRIDES[short_name]
    # Capitalize words
    parts = short_name.split("_")
    out = []
    for p in parts:
        if p.startswith("+"):
            out.append(p)
        elif p.lower() in {"iii", "iv", "ii", "vi", "vii", "viii", "ix", "xi"}:
            out.append(p.upper())
        else:
            out.append(p.capitalize())
    return " ".join(out)


def to_url(name: str) -> str:
    # BG-Wiki uses underscores in URLs; encode characters
    underscored = name.replace(" ", "_")
    return "https://www.bg-wiki.com/ffxi/" + urllib.parse.quote(underscored, safe="_+")


if __name__ == "__main__":
    with open(AUDIT, "r", encoding="utf-8") as f:
        data = json.load(f)
    for item in data["naked_items"]:
        name = candidate_name(item["shortName"])
        url  = to_url(name)
        print(f"{item['itemId']}\t{item['shortName']}\t{name}\t{url}")
