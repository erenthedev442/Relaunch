"""Item link + hover-image URL helpers.

Item links and hover-preview images are keyed on the **item ID** and point
at FFXIAH, which serves both reliably:

    page  : https://www.ffxiah.com/item/<id>
    icon  : https://static.ffxiah.com/images/icon/<id>.png

Why not BG-Wiki? BG-Wiki names are guessed from the display name, and that
guess fails constantly: it abbreviates ("Mallquis Chapeau +2" -> page
"Mall. Chapeau +2"), keeps apostrophes the catalogs drop ("Bunzi's Hat"),
and its description-image filenames don't follow one rule. ~35% of the
guessed `<name>_description.png` images 404, the search endpoint 403s
scripted requests, and BG-Wiki's own API can't even resolve the apostrophe
items. FFXIAH keyed on the ID we already have is 100% reliable, so we use
it for every item link + tooltip.

How the ID is obtained, in order:
  1. An explicit `item_id` passed by the caller (the catalog row's id) —
     always correct, required for multi-level weapons whose names collide
     (Caliburnus I/II/III, Aeneas, etc.).
  2. A display-name -> id lookup built from sql/item_basic.sql by
     `build_item_index()`. Names that map to MORE THAN ONE id are dropped
     from the index, so we never silently link to the wrong item — those
     fall through to the fallback unless the caller passes an explicit id.

Fallback when no id is found: a BG-Wiki search link (which never hard-404s
for a real browser) and NO hover image (item-tooltip.js skips empty
data-img), so a missing id degrades to a plain working link, never a
broken-image icon.
"""
from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path
from urllib.parse import quote, urlencode


_FFXIAH_ITEM_URL = "https://www.ffxiah.com/item"
_FFXIAH_ICON_URL = "https://static.ffxiah.com/images/icon"
_BG_WIKI_IMAGE_BASE = "https://www.bg-wiki.com/images"
_BG_WIKI_INDEX_URL  = "https://www.bg-wiki.com/index.php"

# Populated by build_item_index(); display-name -> id for UNAMBIGUOUS names.
_NAME_TO_ID: dict[str, int] = {}

# Populated by build_item_index() from bgwiki_images.json (written by
# resolve_bgwiki_images.py): item id (str) -> BG-Wiki description-box image URL
# (the in-game stat box). Items absent here fall back to the FFXIAH icon.
_IMAGE_BY_ID: dict[str, str] = {}

# item_basic INSERT row: VALUES (id, subid, 'internal_name', ...).
_ITEM_BASIC_RE = re.compile(
    r"INSERT INTO `item_basic` VALUES\s*\(\s*(\d+)\s*,\s*\d+\s*,\s*'([^']*)'"
)


def _display_name(internal: str) -> str:
    """item_basic stores lowercase_with_underscores; catalogs show Title Case."""
    return internal.replace("_", " ").title()


def build_item_index(repo_root) -> int:
    """Build the display-name -> item-id index from sql/item_basic.sql.

    Names that resolve to multiple ids (multi-level weapons, NQ/HQ pairs,
    re-used names) are AMBIGUOUS and excluded, so a name lookup can never
    pick the wrong item. Callers with collision-prone items must pass an
    explicit item_id. Returns the number of unambiguous names indexed.
    Call once at the start of a docgen run.
    """
    global _NAME_TO_ID, _IMAGE_BY_ID
    from tools.docgen._paths import resolve_source

    # Load the resolved BG-Wiki description-box image cache (id -> url), written
    # by resolve_bgwiki_images.py; items absent here fall back to the FFXIAH icon.
    cache = Path(__file__).resolve().parent / "bgwiki_images.json"
    if cache.exists():
        try:
            _IMAGE_BY_ID = {k: v for k, v in
                            json.loads(cache.read_text(encoding="utf-8")).items() if v}
        except Exception:
            _IMAGE_BY_ID = {}

    src = resolve_source(repo_root, "sql/item_basic.sql")
    if src is None:
        _NAME_TO_ID = {}
        return 0
    idx: dict[str, int] = {}
    ambiguous: set[str] = set()
    text = src.read_text(encoding="utf-8", errors="replace")
    for m in _ITEM_BASIC_RE.finditer(text):
        iid = int(m.group(1))
        disp = _display_name(m.group(2))
        if disp in idx and idx[disp] != iid:
            ambiguous.add(disp)
        else:
            idx.setdefault(disp, iid)
    for dup in ambiguous:
        idx.pop(dup, None)
    _NAME_TO_ID = idx
    return len(_NAME_TO_ID)


def resolve_item_id(item_name: str, item_id: int | None = None) -> int | None:
    """Return the item id: explicit id wins; otherwise an unambiguous name
    match. item_basic names carry no apostrophes ("skulkers_earring") while
    catalog display names sometimes do ("Skulker's Earring"), so we also try
    apostrophe-stripped / Title-cased forms. Every lookup hits the
    UNAMBIGUOUS index, so any hit is safe (never the wrong item)."""
    if item_id:
        return item_id
    for key in (item_name, item_name.title(),
                item_name.replace("'", ""), item_name.replace("'", "").title()):
        rid = _NAME_TO_ID.get(key)
        if rid:
            return rid
    return None


def ffxiah_page_url(item_id: int) -> str:
    return f"{_FFXIAH_ITEM_URL}/{item_id}"


def ffxiah_icon_url(item_id: int) -> str:
    return f"{_FFXIAH_ICON_URL}/{item_id}.png"


def search_redirect_url(query: str) -> str:
    """BG-Wiki search-redirect — the no-id fallback page link. Never hard
    404s for a browser; lands on the article on an exact title match."""
    return f"{_BG_WIKI_INDEX_URL}?{urlencode({'search': query, 'go': 'Go'})}"


def urls_for_item(item_name: str, override: str | None = None,
                  item_id: int | None = None) -> tuple[str, str]:
    """Return `(page_url, image_url)` for an item.

    Prefers an FFXIAH link + icon keyed on the item id (explicit, or an
    unambiguous name match). With no id, returns a BG-Wiki search link and
    an EMPTY image url (no broken hover image).
    """
    rid = resolve_item_id(item_name, item_id)
    if rid:
        # Hover image = BG-Wiki description-box (stat box) when we resolved one,
        # else the always-available FFXIAH icon. Link always FFXIAH (reliable).
        image = _IMAGE_BY_ID.get(str(rid)) or ffxiah_icon_url(rid)
        return ffxiah_page_url(rid), image
    search_query = (override or item_name).replace("_", " ")
    return search_redirect_url(search_query), ""


# ---------------------------------------------------------------------------
# Back-compat shims (kept so any older import keeps working; unused by the
# id-based path above).
# ---------------------------------------------------------------------------
def slug_for(item_name: str, override: str | None = None) -> str:
    return override.strip() if override else item_name.replace(" ", "_")


def image_filename(slug: str) -> str:
    return f"{slug}_description.png"


def image_url_for_filename(filename: str) -> str:
    md5 = hashlib.md5(filename.encode("utf-8")).hexdigest()
    return f"{_BG_WIKI_IMAGE_BASE}/{md5[0]}/{md5[:2]}/{quote(filename)}"
