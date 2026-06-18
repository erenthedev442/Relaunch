# Docs site generator

The player-facing site at https://legendary-ffxi.pages.dev/ is built from `docs/` by MkDocs. Some pages are written by hand; some have auto-generated sections from the server's source data (`sql/`, `scripts/commands/`, `settings/`, `modules/custom/`, etc.).

## Layout

```
docs/                                 # Site source (committed)
  index.md                            # Landing
  getting-started/                    # Install + connect (hand-written)
  changes/index.md                    # What's custom: narrative + auto-gen settings diff
  progression/index.md                # Hunting League: narrative + auto-gen tiers + rewards
  reference/
    commands.md                       # ← fully auto-generated
    spells/                           # ← fully auto-generated
  admin/                              # Public admin info (hand-written)

_private/                             # Local-only admin notes (gitignored)

mkdocs.yml                            # Site config
tools/docgen/                         # Generator framework
  generate.py                         # Orchestrator — run this
  _paths.py                           # Source resolution (repo + LEGENDARY_LIVE_ROOT)
  _markers.py                         # DOCGEN marker replacement
  requirements.txt
  generators/
    spells.py                         # sql/spell_list.sql -> docs/reference/spells/
    commands.py                       # scripts/commands/*.lua -> docs/reference/commands.md
    settings_changes.py               # settings/{main,map}.lua diff -> markers in docs/changes/
    hunting_league.py                 # hunting_league_catalog.lua -> markers in docs/progression/
```

## How a generator works

Each generator is a Python module with a `generate(repo_root, docs_dir)` function. Three patterns are in use:

1. **Owns a whole file** (`spells.py`, `commands.py`) — writes the entire markdown page from scratch every run.
2. **Writes between DOCGEN markers** (`settings_changes.py`, `hunting_league.py`) — replaces only the block between `<!-- DOCGEN:BEGIN id="X" -->` and `<!-- DOCGEN:END id="X" -->`. Hand-written content outside the markers is preserved.
3. **Skips when source is missing** — every generator checks for its source via `_paths.resolve_source()` and logs `[name] skip:` without overwriting anything if the source isn't found.

## Source resolution and `LEGENDARY_LIVE_ROOT`

Some generators read files that aren't committed to the repo:

- `settings/main.lua`, `settings/map.lua` — gitignored (`/settings/*.lua` in `.gitignore`)
- `modules/custom/lua/hunting_league_catalog.lua` — gitignored (`modules/custom/` is local)
- `scripts/commands/*.lua` — committed, but your live server may have different `permission` values than upstream

For local generation against your actual live server, set the env var:

```powershell
# PowerShell
$env:LEGENDARY_LIVE_ROOT = "D:\server"
python tools/docgen/generate.py
```

```bash
# Bash
export LEGENDARY_LIVE_ROOT=/d/server
python tools/docgen/generate.py
```

When set, generators look in `<LEGENDARY_LIVE_ROOT>/<path>` if the source isn't in the repo. CI never sets this, so CI only generates pages whose source is committed — the others are skipped without clobbering whatever's already in `docs/`.

## Typical local workflow

```powershell
# 1. Make changes on your live server (edit settings, command perms, hunting league catalog).
# 2. Regenerate the affected docs pages:
$env:LEGENDARY_LIVE_ROOT = "D:\server"
python tools/docgen/generate.py

# 3. Preview:
python -m mkdocs serve

# 4. Commit the changed markdown files and push:
git add docs/
git commit -m "Refresh docs from live server"
git push fjb HEAD:main
```

The GitHub Actions workflow then builds and deploys.

## Adding a new generator

1. Create `tools/docgen/generators/<name>.py` with a `generate(repo_root, docs_dir)` function.
2. Use `resolve_source(repo_root, "path/to/source")` to find your input.
3. Either write a whole page (`(docs_dir / "reference" / "foo.md").write_text(...)`) or write between markers (`write_between_markers(page, "marker-id", content)`).
4. Import the module in `generate.py` and add it to the iteration list.
5. If you used markers, add `<!-- DOCGEN:BEGIN id="..." -->` / `<!-- DOCGEN:END id="..." -->` to the target page.

## Local preview

```powershell
python -m pip install --user -r tools/docgen/requirements.txt
python tools/docgen/generate.py
python -m mkdocs serve
```

Opens at http://localhost:8000.

## Production build

```powershell
python tools/docgen/generate.py
python -m mkdocs build --strict
```

Output goes to `site/` (gitignored). Don't commit `site/`.

## How CI publishes

`.github/workflows/docs.yml` runs on every push to `main` that touches docs/site source. It installs dependencies, runs `tools/docgen/generate.py`, builds with `mkdocs build --strict`, and deploys to GitHub Pages.

CI has no `LEGENDARY_LIVE_ROOT`, so generators that need files outside the repo (settings, hunting league catalog) will skip. The previously-committed markdown stays in place — meaning the live site reflects whatever was last generated locally and committed.

## Pushing this branch to your fork

```powershell
git remote add fjb https://github.com/richardknutzjr/FFXI-Private-Server-FJB.git
git push fjb HEAD:main
```

## Private notes

For server credentials, GM-only command lists, DB passwords: put them in `_private/` in the repo root. That folder is in `.gitignore`, so it never ships.
