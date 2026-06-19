# Your First Session

You've finished [First Steps](first-steps.md) — your character is set up, you grabbed starter gear, and `!hunt` dropped you at Reisenjima Henge. This page is what comes next: the actual rhythm of playing Legendary, and the systems that quietly reward you just for showing up.

If you remember only one thing: **almost everything on Legendary runs on Hunt Marks.** You earn them by killing NMs in the Hunting League, and you spend them on seals, gear, and rank unlocks. Learn that one loop and the rest falls into place.

---

## The core loop

```
!buff        →  sustain (Refresh / Regen / Regain)
pop an NM    →  Hunt: Spawner
kill it      →  earn Hunt Marks
spend marks  →  seals, gear, next rank
rank up      →  repeat — tougher NMs pay more
```

That's the whole game in five beats. Everything else on this page just makes the loop faster or more rewarding.

---

## Your first 30 minutes at Henge

You arrived via `!hunt`. Before you swing at anything:

```
!buff
```

This grants Refresh, Regen, Regain, and your zone's regional buff (Signet / Sanction / Sigil / Ionis) — free sustain that makes solo hunting comfortable. Recast it whenever it wears off or you change zones.

Then work the loop using the two NPCs standing side-by-side where you landed:

1. **Talk to Hunt: Hub** — your rank board. It shows your current Hunting League rank, your Hunt Marks balance, and the reward shop. (Quick balance check anytime with `!marks`.)
2. **Talk to Hunt: Spawner** — pop a Rank I NM: **Leaping Lizzy**, **Valkurm Emperor**, or **Tom Tit Tat**. It appears right in front of you — no map navigation, no cooldown.
3. **Kill it.** You must land the killing blow (or be credited as the killer). Each Rank I kill pays **5 Hunt Marks**, and your very first kill also fires the **First Hunt** achievement for a bonus **+50**.
4. **Spend at the Hub.** You were handed **100 Hunt Marks** at character creation — a real head start. Convert some into **Seals** at the reward shop and take them to the Armor & Weapons vendors at Henge for your first real upgrade. (Full breakdown: [Gear Vendors](../progression/gear-vendors.md).)
5. **Keep popping.** Rack up marks, return to **Hunt: Hub**, and unlock **Rank II** for **12 marks**. Each rank opens a tougher NM roster that pays more per kill — 5 at Rank I climbing to **65** at Rank V.

Not sure what you need for the next rank? Ask the game directly:

```
!tier
```

It shows your current tier, the NMs available to you, and exactly what's required to rank up. For the full ladder — all five ranks, every NM, the reward shop — see the **[Hunting League page](../progression/index.md)**.

!!! warning "Don't underestimate the starters"
    Leaping Lizzy is buffed well beyond its retail stats (+1000 ATT, +200 DEF). The Rank I NMs are a real fight on fresh gear — that's what your starter marks and `!buff` are for.

---

## Rewards just for showing up

Legendary front-loads its generosity. You don't have to grind for hours to feel progress — Hunt Marks land in your lap for logging in and for hitting milestones:

| When | Reward |
|---|---|
| Create your character | **+100** Hunt Marks (starter stipend) |
| First login each day (UTC) | **+10** Hunt Marks |
| 7 days logged in a row | **+50** Hunt Marks |
| 14 days in a row | **+100** Hunt Marks |
| 30 days in a row | **+200** Hunt Marks |
| Your 1st NM kill | **+50** — *First Hunt* |
| Your 10th NM kill | **+100** — *Ten Hunts In* |
| Your 100th NM kill | **+300** + the *Desert Hunter* title |
| Your 1,000th NM kill | **+1,000** + the *Hero Among Heroes* title |

Login streaks reset if you skip a UTC day, so a quick daily login keeps them alive. There are plenty more milestones beyond the ones above — first kill at each tier, lifetime-marks landmarks, dungeon clears — and you can see the whole list, earned and unearned, with:

```
!achievements
```

!!! tip "Titles are yours to display"
    Achievement titles unlock for display without being forced on. Pick when to show one with `/title`.

---

## The weekly rhythm

Once the core loop clicks, two rotating boards give you a reason to come back beyond raw marks:

- **Weekly Hunt Board** — five objectives rolled fresh each week. Complete them for bonus marks and a lifetime "Weekly Hunter" sweep counter. Track it with `!weekly`. (Details: [Weekly Hunt Board](../progression/weekly-hunts.md).)
- **Featured Hunts** — one NM per tier is featured each week and pays **2× base marks** on your first kill of the week. See them with `!featured`.
- **Bonus Dungeon** — one dungeon each week awards **2× Infamy** on the first clear. Find this week's with `!bonus_dungeon`.
- **Daily Board** — lighter objectives that refresh every daily reset.

Two commands roll up everything time-sensitive:

```
!week     # your weekly objectives at a glance
!time     # server time + hours to daily reset, days to weekly reset
```

Resets land **daily at 00:00 UTC** and **weekly on Monday 00:00 UTC**.

---

## Commands worth memorizing

You don't need to learn every command — these are the ones a new hunter actually reaches for:

| Command | What it does |
|---|---|
| `!hunt` | Warp to Reisenjima Henge (the Hunting League) |
| `!buff` | Refresh / Regen / Regain + your regional buff |
| `!marks` | Hunt Marks balance — spendable and lifetime |
| `!tier` | Current tier + exactly what's needed to rank up |
| `!progress` | One-screen summary across every system |
| `!nms` | NM Encyclopedia — what you've killed, what's left |
| `!achievements` | Every milestone, earned and unearned |
| `!week` / `!weekly` | Weekly objectives and board progress |
| `!featured` / `!bonus_dungeon` | This week's 2× bonuses |
| `!lfg` | Broadcast "looking for group" server-wide |
| `!who` | Who's online, ranked by tier |
| `!help` | The full custom-command list |

Forgot one mid-session? `!help` prints them all. The complete reference lives on the **[Player Commands](../reference/commands.md)** page.

---

## Where you're headed

The Hunting League is the spine, but it isn't the whole skeleton. As you climb, these open up:

- **[Ascension (Prestige)](../progression/prestige.md)** — hit the top HL rank on a job, then reset it for permanent per-job bonuses.
- **[Gear Guide](../progression/gear-guide.md)** and **[Best-in-Slot](../progression/bis-guide.md)** — where your marks are best spent as you gear up.
- **[HNM Kings](../progression/hnm.md)** and the **[Hunter's Guild](../progression/hunters-guild.md)** — the endgame loops beyond the Henge.

To see your own trajectory, your character gets a public profile with a **personalized "recommended next step."** Browse the **[Player Profiles](../community/players/index.md)** list and click your name — it appears after your first stats sync.

---

## Stuck or solo? Join Discord

The fastest way to find a group, ask a question, or report something broken is the **Discord server**. Use `!lfg` in-game to ping for a group, and check the live **[Server Status](../community/status.md)** page to see who's on before you log in.

Welcome to the hunt.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 3ff484a56cbd -->
_Last updated: 2026-06-19 16:09 UTC_
<!-- DOCGEN:END id="last-updated" -->
