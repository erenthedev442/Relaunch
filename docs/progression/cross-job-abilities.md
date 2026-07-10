# Cross-Job Abilities

The **Cross-Job Ability Trainer** in <!--npc:cross_job_ability-->Purgonorgo Isle<!--/npc--> sells permanent ability licenses that let you use abilities from other jobs on **any main job** — no subjob required.

!!! tip "Summary"
    Find the Trainer in <!--npc:cross_job_ability-->Purgonorgo Isle<!--/npc-->. Pay **10,000,000 gil per ability** (one-time, per-character). Activate via `/ja "Ability Name" <me>`. The ability fires on any job you play, with normal recast timers.

---

## How It Works

1. **Talk to the Cross-Job Ability Trainer** in the Utility cluster in <!--npc:cross_job_ability-->Purgonorgo Isle<!--/npc-->.
2. **Browse by job group** — the menu is organized into groups (Warrior, Samurai, etc.).
3. **Confirm purchase** — 10,000,000 gil is deducted and the license is permanently recorded to your character.
4. **Use a macro** — `/ja "Meditate" <me>` (or whichever ability). The server validates the macro against your unlocked licenses and fires the ability.

### Important Notes

- **Purchased abilities do not appear in the in-game Job Abilities menu.** The menu is built client-side from game DATs and can't be extended. The abilities are real and server-enforced — they just don't show in that menu. Use macros.
- **Recast timers are normal.** The server enforces standard recasts exactly as if you had the ability natively.
- **No subjob needed.** The ability fires regardless of what job you have set as main or sub.
- **2-hour abilities are excluded.** The trainer does not sell any 2-hour abilities.
- **Pet abilities are excluded.** Abilities that require job mechanics (Sic, Ready, Rolls, Wyvern) are not available.

---

## Available Abilities

<!-- DOCGEN:BEGIN id="cross-job-abilities-catalog" -->
_Each ability costs **10,000,000 gil** — a one-time, per-character, per-ability purchase. After buying, activate via macro: `/ja "Ability Name" <me>`. Purchased abilities do **not** appear in the in-game Job Abilities menu (the menu is client-side); they are enforced server-side and their recast timers work normally._

_**9 abilities** available across 4 job groups._

<style>
.cja-group{margin:1.6rem 0 .55rem;font-size:1.05rem;font-weight:700;letter-spacing:.01em;
  display:flex;align-items:center;gap:.55rem}
.cja-group::after{content:"";flex:1;height:1px;background:var(--md-default-fg-color--lightest)}
.cja-count{font-size:.72rem;font-weight:600;color:var(--md-default-fg-color--light);
  background:var(--md-default-fg-color--lightest);border-radius:10px;padding:.05rem .5rem}
.cja-grid{display:grid;gap:.7rem;grid-template-columns:repeat(auto-fill,minmax(255px,1fr))}
.cja-card{border:1px solid var(--md-default-fg-color--lightest);border-left:4px solid var(--acc);
  border-radius:9px;padding:.7rem .85rem .75rem;background:var(--md-default-bg-color);
  transition:transform .12s ease,box-shadow .12s ease}
.cja-card:hover{transform:translateY(-2px);box-shadow:0 4px 14px rgba(0,0,0,.14)}
.cja-top{display:flex;align-items:center;justify-content:space-between;gap:.5rem;margin-bottom:.4rem}
.cja-name{font-weight:700;font-size:.96rem;line-height:1.2}
.cja-badges{display:flex;gap:.3rem;flex-shrink:0}
.cja-job{font-size:.64rem;font-weight:700;letter-spacing:.03em;color:#fff;background:var(--acc);
  padding:.12rem .42rem;border-radius:4px}
.cja-lvl{font-size:.64rem;font-weight:700;color:var(--md-default-fg-color--light);
  background:var(--md-default-fg-color--lightest);padding:.12rem .42rem;border-radius:4px;white-space:nowrap}
.cja-eff{margin:0;font-size:.82rem;line-height:1.4;color:var(--md-default-fg-color--light)}
</style>

<div class="cja-group">Warrior<span class="cja-count">5 abilities</span></div>
<div class="cja-grid">
<div class="cja-card" style="--acc:#c0392b"><div class="cja-top"><span class="cja-name">Berserk</span><span class="cja-badges"><span class="cja-job">WAR</span><span class="cja-lvl">Lv.15</span></span></div><p class="cja-eff">Boosts attack; lowers defense.</p></div>
<div class="cja-card" style="--acc:#c0392b"><div class="cja-top"><span class="cja-name">Aggressor</span><span class="cja-badges"><span class="cja-job">WAR</span><span class="cja-lvl">Lv.45</span></span></div><p class="cja-eff">Boosts accuracy; lowers evasion.</p></div>
<div class="cja-card" style="--acc:#c0392b"><div class="cja-top"><span class="cja-name">Warcry</span><span class="cja-badges"><span class="cja-job">WAR</span><span class="cja-lvl">Lv.35</span></span></div><p class="cja-eff">Party-wide attack boost (AoE).</p></div>
<div class="cja-card" style="--acc:#c0392b"><div class="cja-top"><span class="cja-name">Blood Rage</span><span class="cja-badges"><span class="cja-job">WAR</span><span class="cja-lvl">Lv.87</span></span></div><p class="cja-eff">Party-wide critical hit rate boost (AoE).</p></div>
<div class="cja-card" style="--acc:#c0392b"><div class="cja-top"><span class="cja-name">Retaliation</span><span class="cja-badges"><span class="cja-job">WAR</span><span class="cja-lvl">Lv.60</span></span></div><p class="cja-eff">Chance to counter melee attacks while standing.</p></div>
</div>
<div class="cja-group">Thief<span class="cja-count">1 ability</span></div>
<div class="cja-grid">
<div class="cja-card" style="--acc:#27ae60"><div class="cja-top"><span class="cja-name">Conspirator</span><span class="cja-badges"><span class="cja-job">THF</span><span class="cja-lvl">Lv.87</span></span></div><p class="cja-eff">Boosts accuracy and Subtle Blow; scales with nearby allies.</p></div>
</div>
<div class="cja-group">Samurai<span class="cja-count">1 ability</span></div>
<div class="cja-grid">
<div class="cja-card" style="--acc:#d35400"><div class="cja-top"><span class="cja-name">Third Eye</span><span class="cja-badges"><span class="cja-job">SAM</span><span class="cja-lvl">Lv.15</span></span></div><p class="cja-eff">Anticipate (evade) your next incoming attack.</p></div>
</div>
<div class="cja-group">Paladin/DRK<span class="cja-count">2 abilities</span></div>
<div class="cja-grid">
<div class="cja-card" style="--acc:#34495e"><div class="cja-top"><span class="cja-name">Last Resort</span><span class="cja-badges"><span class="cja-job">DRK</span><span class="cja-lvl">Lv.15</span></span></div><p class="cja-eff">Boosts attack; lowers defense.</p></div>
<div class="cja-card" style="--acc:#34495e"><div class="cja-top"><span class="cja-name">Souleater</span><span class="cja-badges"><span class="cja-job">DRK</span><span class="cja-lvl">Lv.30</span></span></div><p class="cja-eff">Adds part of your HP to melee damage, costing HP.</p></div>
</div>
<!-- DOCGEN:END id="cross-job-abilities-catalog" -->

---

## Strategy Notes

**Most popular picks:**

| Ability | Why |
|---|---|
| **Meditate** | Free TP buildup — valuable on any melee job |
| **Souleater** | High burst damage at the cost of HP — strong on DD jobs |
| **Berserk** | Straight attack boost — pure DD value on any melee |
| **Warcry** | Party-wide attack boost — great for coordinated parties |
| **Rampart** | Party-wide damage-reduction ward — strong in tough content |
| **Sentinel** | Heavy defense + enmity burst — useful off-tank tool |

There's no wrong choice — the 10M gil cost means you'll pick deliberately, but the license lasts forever. Start with the ability that fills a hole in your job's toolkit.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: e1e7fc29cb3e -->
_Last updated: 2026-07-05 07:37 UTC_
<!-- DOCGEN:END id="last-updated" -->
