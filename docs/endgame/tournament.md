# Tournament

The **Tournament** is a GM-run last-team-standing PvE event. When a GM opens sign-ups, players register solo or as named teams. Once the GM starts the event, every team is warped to **Qu'Bia Arena** where they fight eight escalating waves of mobs — each team on their own independent wave. The last team with any survivors wins.

!!! tip "Summary"
    Type `!tournament join` during sign-ups (or `!tournament join <team>` to form a team). You'll be warped in, fight 8 waves, and the last team standing takes the crown. Trusts are not allowed.

---

## Joining

Use these commands during the sign-up phase:

```
!tournament                  -- show current status / registration list
!tournament join             -- register solo (your character name = your team)
!tournament join <teamname>  -- join or create a named team
!tournament leave            -- withdraw before the event starts
```

Teams can have any number of members. Solo entrants are a team of one.

---

## Rules

- **Trusts are blocked.** Any trusts you have summoned are dismissed when you zone in. You cannot cast new ones during the event.
- **Independent waves.** Each team fights their own private mob wave — mobs only aggro your team's members. Competing teams cannot interfere with your mobs, and you cannot steal kills from them.
- **Team elimination.** Your team stays in until *every member* has been KO'd. One surviving teammate keeps your team alive.
- **HP scales with team size.** Larger teams face mobs with proportionally higher HP so solo players and full parties have comparable difficulty.
- **Victory.** Clear all 8 waves, or be the last team standing when every other team is eliminated.

---

## Wave Table

<!-- DOCGEN:BEGIN id="tournament-waves" -->
| Wave | Mobs | Level | Difficulty |
|---|---|---|---|
| Wave 1 | 3 | 110 | ×6 |
| Wave 2 | 4 | 130 | ×10 |
| Wave 3 | 4 | 150 | ×16 |
| Wave 4 | 5 | 170 | ×24 |
| Wave 5 | 5 | 190 | ×36 |
| Wave 6 | 6 | 210 | ×52 |
| Wave 7 | 6 | 230 | ×72 |
| Wave 8 | 7 | 250 | ×96 |
<!-- DOCGEN:END id="tournament-waves" -->

_Difficulty is the HP multiplier applied to base mob HP. Larger teams face proportionally higher HP — mob HP is scaled by 0.6 × total team size (floor 1), so a 3-member team faces 1.8× base HP multiplier._

---

## GM Commands

GMs control the tournament lifecycle:

```
!tournament open              -- open sign-ups
!tournament start             -- warp all entrants in and begin wave 1
!tournament cancel            -- abort the event and warp survivors home
!tournament kick <name>       -- eliminate a player or remove from sign-ups
!tournament team <pl> <team>  -- reassign a player to a team (sign-up phase only)
!tournament add  <name>       -- force-add a player to sign-ups
```

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: c6c1f9d0c75b -->
_Last updated: 2026-06-19 16:09 UTC_
<!-- DOCGEN:END id="last-updated" -->
