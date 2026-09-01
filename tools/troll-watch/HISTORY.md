# Troll / ex-GM IP history (for Richard)

Written **1 Sep 2026**. Machine-readable copy: `watchlist.json`.
Read-only check on the VPS: desktop **Relaunch - Troll Check**.

This is the paper trail of who used which IP, which Windows accounts existed,
and what was already done on the live box. Do not treat a `/24` as proof unless
several exact IPs in that block already match.

---

## Never touch

| Who / what | Why |
|---|---|
| IP `185.124.0.99` | Kirin / Eren home. A troll used that *string* as a login (`185.124.0.99`). Never firewall it. |
| Katrrine accid `1075` | Real player. Name collision only. Home `24.242.157.37`. |
| Duda / Sara / Sofia / Thanos | Normal Reforge players. |
| Gaspard on login `zogen` | Real player. The squat was **Gaspar** / login `gaspard` (1122). |
| Falown, Pucca, Prale / Namers / Haha, Wishmoon, Deathgodking | Watch only unless a later IP/name tie appears. |
| `richard` / Jbae, `richard2` / Bdr IPs `69.130.180.41` and `204.195.87.159` | Owner accounts. A backup char named Bro sat on `richard2` — that is **not** the troll. |

---

## 1. Bro / High — old GM, Relaunch troll

Same person. Game only. **Never had a Windows / RDP user.**

### Identity timeline

| When | Who | Notes |
|---|---|---|
| 23 Jun 2026 | GM char **Bro** | 45 GM commands that day (promote, pearls, etc.). Chat is staff talk. **No game IP stored** — `account_ip_record` on this box starts 6 Jul. |
| 1 Jul | login **`high`** accid **1001** created | Continuation of the same person. |
| 5 Jul | GM char **High** | 35 GM commands. Alt login **`high2`** (1006) / char **Nut**. |
| 6 Jul – 3 Aug | `high` / `high2` game logins | IPs below. Source: `C:\server\db-backups\pre_char_wipe_FINAL_20260827_010546.sql`. Accounts wiped in the late-Aug char wipe; **not on live**. |
| 28 Aug 10:10–10:30 | First remake wave | **Same IP as High:** `69.1.199.233`. Source: `C:\server\db-backups\xi_relaunch-20260829-144413.sql`. Live `account_ip_record` no longer has these rows. |
| 28 Aug 11:03–13:09 | login `bro` / `bro2` | Brazil V.tal `187.40.228–229.*`. |

### Proven IPs (his, or hop he used)

| IP | ISP / note | Used as | When |
|---|---|---|---|
| **`69.1.199.233`** | WhiteSky Atlanta AS62887. Main stable address. | `high`, `high2`/Nut, then first remake wave | 23 Jul – 3 Aug; 28 Aug 10:10–10:30 |
| `108.160.120.67` | Highline fiber, Dallas TX | `high` / High | 6–7 Jul |
| `108.160.120.40` | Highline Dallas | `high` / High | 14 Jul |
| `129.222.78.130` | Starlink Dallas pop | `high` / High | 10 Jul |
| `98.97.80.43` | Starlink | `high` / High | 13 Jul |
| `187.40.229.77` | Brazil V.tal | `bro` / Bro | 28 Aug 11:03 |
| `187.40.229.2` | Brazil V.tal | `bro` / Bro | 28 Aug 11:25 |
| `187.40.228.105` | Brazil V.tal | `bro` and `bro2` / Drunk | 28 Aug 13:06–13:09 |
| `187.40.229.172` | Brazil V.tal same-hour remakes | `legendaryass`, `12345678910` / Abysseaenjoyer, `garvnigga` / Garvauniqqa | 28 Aug 15:04–15:13 |

Do **not** firewall whole Starlink or Highline `/24`s (shared). Exact IPs only.

### 28 Aug first wave on `69.1.199.233`

| Time | Login | Char | What we did 1 Sep |
|---|---|---|---|
| 10:10 | `claude` (1036) | **Spyro** | Char **deleted** (1.0 name squat). Account banned. |
| 10:12 | `1234` (1061) | Migger | Char deleted. Account banned. |
| 10:15 | `12345` (1068) | **Phatdood** | Char **deleted** (1.0 name squat). Account banned. |
| 10:17 | `penis` (1074) | **Xio** | Char **deleted** (1.0 name squat). Account banned. |
| 10:19 | `penis1` (1077) | *(no char)* | Account banned. |
| 10:26 | `password` (1085) | **Pokoton** | Char **deleted** (1.0 name squat). Account banned. |
| 10:30 | `1234` | Migger again | — |

Spyro / Phatdood / Xio / Pokoton were **real 1.0 player names**. The squat chars are gone so those players can recreate. Soft-delete (`accid=0`) would have kept the names blocked; these rows were hard-deleted from `chars`.

Also deleted: Bro (157 / `bro` 1106), Drunk (199 / `bro2` 1146).

### Live lock state after 1 Sep

All of: `claude`, `1234`, `12345`, `penis`, `penis1`, `password`, `bro`, `bro2` → `accounts.status = 2` (banned).
`accounts_banned` comment: `Bro/High name-squat / remake purge 2026-09-01`.

---

## 2. Kahz / Shigu — old GM with RDP

| Field | Value |
|---|---|
| Game login | `ririn` accid **1000** (wiped; not on live) |
| GM char | **Ririn** (charid 3) plus alts Itsurboy, Smashurbatty, Enko, Eir, Rirint, Ririntwo |
| Windows user | **`Ririn`** — was Administrators + Remote Desktop Users |
| Git | Shigu Kahz / `shigukahz` |
| Last GM command | 5 Jul 2026 |
| Last game login | 6 Aug 2026 |
| Last RDP | 31 Jul 2026 |

### Proven IPs

| IP | ISP | Used for |
|---|---|---|
| **`109.146.153.213`** | BT UK home (AS2856) | RDP 13–30 Jul **and** almost every game login 12–28 Jul |
| `109.180.255.228` | BT UK (same line after reconnect) | Game only, 6 Aug (twice) |

No live Relaunch account uses those IPs.

### What we did 1 Sep

- Deleted Windows user `Ririn` (profile `C:\Users\Ririn` gone).
- Removed from Administrators and Remote Desktop Users.
- Left **Administrator** and **Kirin** only.
- Firewall inbound: `109.146.153.213`, `109.180.255.228`.

---

## 3. Windows Firewall on the VPS (live now)

Persistent inbound **Block** rules, exact IPs, all ports. Rule names `Block Bro-High <ip>` or `Block Kahz <ip>`.

```
69.1.199.233
108.160.120.67
108.160.120.40
129.222.78.130
98.97.80.43
187.40.229.77
187.40.229.2
187.40.229.172
187.40.228.105
109.146.153.213
109.180.255.228
```

There is **no** in-game IP-ban table. The connect server does not check IP allow/deny. The firewall is the IP ban.

A new BT / Starlink / V.tal address will **not** be blocked until someone adds it.

---

## 4. Other clusters (already in watchlist.json)

- **Bankai** NordVPN PacketHub `66.179.156.*` — banned 1 Sep. Separate from Bro/High.
- **Prale / Namers / Haha** — digit logins, watch only.
- **Pucca** — Japan KDDI, watch only.

---

## 5. Where the raw evidence still lives (VPS)

| Source | What it proves |
|---|---|
| `C:\server\db-backups\pre_char_wipe_FINAL_20260827_010546.sql` | `high` / `high2` / Ririn game IPs |
| `C:\server\db-backups\xi_relaunch-20260829-144413.sql` | 28 Aug `69.1.199.233` first wave |
| Live `audit_gm` | Bro 23 Jun, High 5 Jul, Ririn Jun–Jul |
| Live `audit_chat` | Bro / High / Ririn chat dates |
| Windows Event: TerminalServices-LocalSessionManager | Ririn RDP + `109.146.153.213` |
| `Get-NetFirewallRule -DisplayName 'Block *'` | Current IP blocks |

Security.evtx only goes back to **31 Aug 2026**, so it has no Kahz RDP.
