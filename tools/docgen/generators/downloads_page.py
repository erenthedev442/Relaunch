"""Full-page owner for docs/getting-started/downloads.md — player downloads.

Packages the repo's player-facing client files into deterministic zips under
docs/assets/downloads/ and writes the Downloads page that lists them:

    relaunch-custom-dats.zip  <- "Custom DATs/Relaunch Custom DATs/" (cosmetic
                                 client DAT overrides + installer/uninstaller)
    augment_browser.zip       <- tools/windower/augment_browser/  (//ab addon)
    augment_trade.zip         <- tools/windower/augment_trade/    (//at addon)

The zips are built with FIXED timestamps and sorted entries so an unchanged
source tree produces byte-identical archives — re-running docgen never churns
git or re-uploads to the site. The page table (size + SHA-256) is computed
from the freshly built zips, so it can never drift from what players download.

The addon data files are themselves generated (tools/gen_windower_catalog.py)
from the live augment catalog — when content changes, regenerate those first,
then this page repackages them on the next docgen pass.
"""
from __future__ import annotations

import hashlib
import io
import zipfile
from pathlib import Path

# Fixed timestamp for every zip entry (determinism; value is arbitrary).
_ZIP_DATE = (2026, 1, 1, 0, 0, 0)

# (zip name, source dir relative to repo root, top-level folder inside the zip)
_PACKAGES = [
    ('relaunch-custom-dats.zip', 'Custom DATs/Relaunch Custom DATs', 'Relaunch Custom DATs'),
    ('augment_browser.zip',      'tools/windower/augment_browser',   'augment_browser'),
    ('augment_trade.zip',        'tools/windower/augment_trade',     'augment_trade'),
]

_SKIP_NAMES = {'.gitignore', '__pycache__', 'Thumbs.db', '.DS_Store'}


def _build_zip(src: Path, root_name: str) -> bytes:
    """Deterministic zip of `src` with `root_name/` as the top-level folder."""
    files = sorted(
        (p for p in src.rglob('*')
         if p.is_file()
         and p.name not in _SKIP_NAMES
         and not p.name.endswith('.orig')
         and '__pycache__' not in p.parts),
        key=lambda p: p.relative_to(src).as_posix(),
    )
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, 'w', zipfile.ZIP_DEFLATED) as zf:
        for p in files:
            arcname = f'{root_name}/{p.relative_to(src).as_posix()}'
            info = zipfile.ZipInfo(arcname, date_time=_ZIP_DATE)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            zf.writestr(info, p.read_bytes())
    return buf.getvalue()


def _fmt_size(n: int) -> str:
    if n >= 1024 * 1024:
        return f'{n / (1024 * 1024):.1f} MB'
    return f'{n / 1024:.0f} KB'


def _page(rows: list[dict]) -> str:
    by_name = {r['name']: r for r in rows}
    dats  = by_name['relaunch-custom-dats.zip']
    ab    = by_name['augment_browser.zip']
    at    = by_name['augment_trade.zip']

    def link(r):
        return f"[`{r['name']}`](../assets/downloads/{r['name']})"

    L = []
    L.append('# Downloads')
    L.append('')
    L.append('Optional client-side files for the Relaunch server. **Nothing here is required '
             'to play** — the server is always the source of truth — but each one makes the '
             'client show custom content properly or adds quality-of-life tooling.')
    L.append('')
    L.append('Every archive on this page is **packaged straight from the server repo on each '
             'site refresh**, so what you download always matches what the server is running. '
             'After a content update, just re-download and reinstall — the table below changes '
             'whenever the contents do.')
    L.append('')
    L.append('| Download | What it is | Size | SHA-256 (first 12) |')
    L.append('|---|---|---:|---|')
    L.append(f"| {link(dats)} | Cosmetic client DAT overrides (custom item names, tooltips, "
             f"and textures) with a one-click installer | {dats['size']} | `{dats['sha']}` |")
    L.append(f"| {link(ab)} | **AugmentBrowser** Windower addon (`//ab`) — browse the augment "
             f"catalog, tiers, and your Sage rank in-game | {ab['size']} | `{ab['sha']}` |")
    L.append(f"| {link(at)} | **AugmentTrade** Windower addon (`//at`) — plan and stage "
             f"catalyst trades for the Augment Moogle | {at['size']} | `{at['sha']}` |")
    L.append('')
    L.append('!!! note "Looking for the loader?"')
    L.append('    `xiloader.exe` is pinned in the **Discord** getting-started channel — see '
             '[Install the Client](install.md#get-the-loader).')
    L.append('')
    L.append('## Relaunch Custom DATs')
    L.append('')
    L.append('Client DAT overrides that make custom Relaunch content display correctly — '
             'names, help text, and textures for custom items. They change **display only**: '
             'without the pack everything still works in-game, you just see the retail '
             'placeholder names and colors. The pack ships with a `README.md` and `manifest.md` '
             'listing exactly which files it overrides.')
    L.append('')
    L.append('**Install (recommended):**')
    L.append('')
    L.append('1. Download and unzip the whole folder anywhere.')
    L.append('2. Double-click **`Install Relaunch DATs.bat`** and approve the admin prompt. It '
             'finds your FFXI install and **backs up every original file** before copying.')
    L.append('3. Restart the game client.')
    L.append('')
    L.append('To revert, double-click **`Uninstall Relaunch DATs.bat`** — it restores the '
             'backups the installer made. Works with Windower, Ashita, or a bare client.')
    L.append('')
    L.append('**Alternative (non-destructive):** place the `Relaunch Custom DATs` folder inside '
             'your **XIPivot** overlay folder (keep the internal `ROM/...` structure), enable '
             'the overlay, and restart the client. Your retail files are never touched.')
    L.append('')
    L.append('## Windower addons')
    L.append('')
    L.append('Both addons carry a snapshot of the live augment catalog, so **re-download them '
             'after augment content updates** (this page repackages them automatically).')
    L.append('')
    L.append('**Install:**')
    L.append('')
    L.append('1. Download and unzip into your `Windower4/addons/` folder (so you end up with '
             '`addons/augment_browser/augment_browser.lua`).')
    L.append('2. In-game: `//lua load augment_browser` (or `augment_trade`).')
    L.append('3. Optional: add the load line to your Windower init script to load on startup.')
    L.append('')
    L.append('Commands: `//ab` toggles the browser (filter by tier, category, owned '
             'catalysts); `//at` opens the trade planner (pick catalysts, see the pending '
             'trade, hand it to the Augment Moogle). Each addon prints its full command list '
             'when run with no arguments.')
    L.append('')
    return '\n'.join(L) + '\n'


def generate(repo_root: Path, docs_dir: Path) -> None:
    out_dir = docs_dir / 'assets' / 'downloads'
    out_dir.mkdir(parents=True, exist_ok=True)

    rows = []
    for zip_name, rel_src, root_name in _PACKAGES:
        src = repo_root / rel_src
        if not src.is_dir():
            print(f'[downloads_page] FAIL: source dir missing: {rel_src} — page not written')
            return
        data = _build_zip(src, root_name)
        dst = out_dir / zip_name
        if not dst.exists() or dst.read_bytes() != data:
            dst.write_bytes(data)
            action = 'rebuilt'
        else:
            action = 'unchanged'
        rows.append({
            'name': zip_name,
            'size': _fmt_size(len(data)),
            'sha':  hashlib.sha256(data).hexdigest()[:12],
        })
        print(f'[downloads_page] {zip_name}: {rows[-1]["size"]} ({action})')

    page = docs_dir / 'getting-started' / 'downloads.md'
    page.parent.mkdir(parents=True, exist_ok=True)
    page.write_text(_page(rows), encoding='utf-8', newline='\n')
    print(f'[downloads_page] wrote {page.relative_to(docs_dir)}')
