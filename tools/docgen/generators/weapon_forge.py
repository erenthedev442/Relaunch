"""Write the interactive Weapon Forge widget to docs/progression/weapon-forge.md.

The widget HTML lives in tools/docgen/templates/weapon_forge_widget.html.
This generator reads that template and writes it verbatim into the
weapon-forge-widget DOCGEN marker in the docs page.

To update the widget content, edit the template file and the next cron
run will deploy the changes automatically.
"""
from __future__ import annotations

from pathlib import Path

from tools.docgen._markers import write_between_markers


def generate(repo_root: Path, docs_dir: Path) -> None:
    template = repo_root / "tools" / "docgen" / "templates" / "weapon_forge_widget.html"
    if not template.exists():
        print("[weapon_forge] skip: weapon_forge_widget.html template not found")
        return

    widget_html = template.read_text(encoding="utf-8")
    page = docs_dir / "progression" / "weapon-forge.md"

    ok = write_between_markers(page, "weapon-forge-widget", widget_html)
    print(f"[weapon_forge] {'widget written' if ok else 'marker not found — skipped'}")
