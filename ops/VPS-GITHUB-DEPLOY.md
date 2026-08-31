# VPS GitHub deploy (C:\server)

Use this the next time **Relaunch - Deploy** says
`Incoming: nothing new since your live code (or offline -- fetch skipped)`
or hangs on `Username for 'https://github.com':`.

## What that message actually means

Deploy only counts commits it can **fetch from `origin`**.
If GitHub auth fails, that line is empty even when GitHub has new commits.

This PC (`C:\Projects\Relaunch`) can push. The VPS uses HTTPS `origin`
and Git Credential Manager. GitHub **rejects your website password** for
`git fetch` / `git push`. The password box must be a **`ghp_…` PAT**, not
the login password.

## At the Username / Password prompt

- **Username:** `richardknutzjr`
- **Password:** the full classic PAT (`repo` scope). It must start with `ghp_`.

That is valid. A website password produces:
`Password authentication is not supported` / `Invalid username or token`.

## One-shot fetch if `origin` is broken

On the VPS, in `C:\server` (do not screenshot the token):

```powershell
git -c credential.helper= fetch https://richardknutzjr:ghp_TOKEN@github.com/richardknutzjr/Relaunch.git relaunch
git log --oneline HEAD..FETCH_HEAD
git rebase FETCH_HEAD
```

`-c credential.helper=` skips the popup.

If rebase conflicts on **`settings/map.lua`**, keep the VPS live file:

```powershell
git checkout --theirs settings/map.lua
git add settings/map.lua
git -c core.editor=true rebase --continue
```

Then **Relaunch - Deploy** → **Y**.
`Incoming: nothing new` is OK if `git log --oneline -8` already shows the
GitHub commits (e.g. `6d6b0e36c2`). Rebuild will say fetch failed and
**build on-disk code**.

A failed `git fetch origin` **wipes `FETCH_HEAD`**. Do not run `origin`
until rebase has finished.

## Lasting fix (do this so you are not repeating the workaround)

**SSH deploy key (preferred)**

```powershell
ssh-keygen -t ed25519 -C "vps-relaunch" -f $env:USERPROFILE\.ssh\id_ed25519 -N ""
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub
```

Repo → Settings → Deploy keys → add the `.pub` line, **Allow write access**.

```powershell
cd C:\server
ssh -o StrictHostKeyChecking=accept-new git@github.com
git remote set-url origin git@github.com:richardknutzjr/Relaunch.git
git fetch origin relaunch
```

**Or HTTPS + PAT stored once** (after GCM stops asking, or disable it):

```powershell
git config --global credential.helper "store --file C:/Users/Administrator/.git-credentials"
Set-Content C:\Users\Administrator\.git-credentials "https://richardknutzjr:ghp_NEW_TOKEN@github.com"
git fetch origin relaunch
```

Revoke any PAT that appeared in a screenshot or terminal history.

## After deploy, confirm it was this code

```powershell
git -C C:\server log --oneline -8
```

You want the commits you just pushed. Watch for `build OK - new binaries in place`.
C++ / `blueutils` changes need that full rebuild, not a light deploy.
