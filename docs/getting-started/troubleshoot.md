# Troubleshooting

Common problems and how to fix them. If your issue isn't listed here, ask in Discord — the community and GMs are active and can usually sort things out quickly.

---

## Can't Connect to the Server

1. **Check Discord `#server-status`** first. If the server is down for maintenance or hit an unexpected crash, it'll be posted there before anywhere else.
2. **Verify your connection settings.** Make sure your client is pointing at the correct IP and port — see the [Connect to Server](connect.md) page for the exact values.
3. **Check your firewall / antivirus.** Overly aggressive security software occasionally blocks game client connections. Try temporarily disabling it to isolate the issue.

---

## Character Stuck in a Cutscene

The server has an **Auto-Unstick watchdog** that clears stuck event state on zone-in.

**Fix:**

1. Zone out — walk to a zone line, or use any warp command (`!gmhome`, `!hunt`, etc.).
2. Zone back in.
3. The watchdog fires on zone-in and should release the stuck state.

If one zone cycle doesn't fix it, **log out and back in** — that's a full zone-in cycle and always triggers the watchdog.

!!! tip
    If you're truly looped with no way to reach a zone line, try typing `!unstick` in chat. This is a self-rescue command that clears stuck event/sequence state on the spot.

---

## Lost an Item / Died to a Bug

If something was lost due to a server bug (not player error), a GM can investigate and restore it.

**What to do:**

1. Note your **character name**, **what was lost**, and **roughly when it happened** (within the last hour is ideal — log timestamps help a lot).
2. Head to Discord and open a ticket or post in the support channel.
3. A GM will follow up when they're available.

!!! warning "Be specific"
    "I lost my item" is hard to act on. "I lost my Ridill around 9pm EST — I was in Dragon's Aery when the server lagged" is actionable. The more detail you give, the faster it gets resolved.

---

## `!gmhome` Not Working

A few possible causes:

- **You don't have GM access for that command.** `!gmhome` is available to all players on this server — if it's not working at all, check if you see any error message in the chat log.
- **Command is on cooldown.** Some warp commands have a short cooldown between uses. Wait a few seconds and try again.
- **You're in a zone that blocks it.** A small number of instanced areas prevent teleport commands from firing. Zone out first, then use `!gmhome`.

Still not working? Ask in Discord.

---

## Lag / Rubber-Banding

The server runs at **69.130.180.41**. Performance issues can come from a few sources:

- **Server load.** If multiple players are reporting rubber-banding at the same time, the server is likely under load. Check `#server-status` in Discord.
- **Your connection.** If it's only you, run a quick latency check to the server IP. High packet loss between you and the server will cause rubber-banding even if the server itself is healthy.
- **Zone population.** Heavily populated zones with lots of AOE and particle effects can stress client rendering. Try a less busy area to isolate the issue.

In most cases, lag during peak hours resolves on its own. If it's persistent and only happening to you, mention it in Discord with your approximate location and what time it started.

---

## Version Mismatch Error

If you get a version mismatch error on login:

1. Run the **PlayOnline updater** and let it fully complete.
2. Restart the client after updating.
3. Try connecting again.

If the updater says you're up to date but the error persists, the server may have been updated while your client wasn't patched yet. Check `#server-status` in Discord for any recent update announcements.

---

## Something Else

If your problem isn't covered here:

1. Check the [FAQ](../community/faq.md).
2. Ask in **Discord** — describe what happened, what you expected, and what you saw instead.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 019f24d0cfca -->
_Last updated: 2026-05-31 00:24 UTC_
<!-- DOCGEN:END id="last-updated" -->
