# Downloads

Optional client-side files for the Relaunch server. **Nothing here is required to play** — the server is always the source of truth — but each one makes the client show custom content properly or adds quality-of-life tooling.

Every archive on this page is **packaged straight from the server repo on each site refresh**, so what you download always matches what the server is running. After a content update, just re-download and reinstall — the table below changes whenever the contents do.

| Download | What it is | Size | SHA-256 (first 12) |
|---|---|---:|---|
| [`relaunch-custom-dats.zip`](../assets/downloads/relaunch-custom-dats.zip) | Cosmetic client DAT overrides (custom item names, tooltips, and textures) with a one-click installer | 5.2 MB | `f4959a3f5455` |
| [`augment_browser.zip`](../assets/downloads/augment_browser.zip) | **AugmentBrowser** Windower addon (`//ab`) — browse the augment catalog, tiers, and your Sage rank in-game | 7 KB | `cf77df2006fc` |
| [`augment_trade.zip`](../assets/downloads/augment_trade.zip) | **AugmentTrade** Windower addon (`//at`) — plan and stage catalyst trades for the Augment Moogle | 8 KB | `00ee3b319917` |

!!! note "Looking for the loader?"
    `xiloader.exe` is pinned in the **Discord** getting-started channel — see [Install the Client](install.md#get-the-loader).

## Relaunch Custom DATs

Client DAT overrides that make custom Relaunch content display correctly — names, help text, and textures for custom items. They change **display only**: without the pack everything still works in-game, you just see the retail placeholder names and colors. The pack ships with a `README.md` and `manifest.md` listing exactly which files it overrides.

**Install (recommended):**

1. Download and unzip the whole folder anywhere.
2. Double-click **`Install Relaunch DATs.bat`** and approve the admin prompt. It finds your FFXI install and **backs up every original file** before copying.
3. Restart the game client.

To revert, double-click **`Uninstall Relaunch DATs.bat`** — it restores the backups the installer made. Works with Windower, Ashita, or a bare client.

**Alternative (non-destructive):** place the `Relaunch Custom DATs` folder inside your **XIPivot** overlay folder (keep the internal `ROM/...` structure), enable the overlay, and restart the client. Your retail files are never touched.

## Windower addons

Both addons carry a snapshot of the live augment catalog, so **re-download them after augment content updates** (this page repackages them automatically).

**Install:**

1. Download and unzip into your `Windower4/addons/` folder (so you end up with `addons/augment_browser/augment_browser.lua`).
2. In-game: `//lua load augment_browser` (or `augment_trade`).
3. Optional: add the load line to your Windower init script to load on startup.

Commands: `//ab` toggles the browser (filter by tier, category, owned catalysts); `//at` opens the trade planner (pick catalysts, see the pending trade, hand it to the Augment Moogle). Each addon prints its full command list when run with no arguments.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: ce3d9d60b3f2 -->
_Last updated: 2026-07-15 11:36 PDT_
<!-- DOCGEN:END id="last-updated" -->
