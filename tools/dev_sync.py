#!/usr/bin/env python3
"""
dev_sync.py -- pre-deploy sync of the collaborator's GitHub work.

Run by deploy-everything-sync.bat BEFORE anything ships. It pulls shigukahz's
(and anyone else's) commits from fjb/Legendary into your local tree so the Azure
box gets THEIR files too -- the plain deploy only ever ships your laptop's copy.

Conflict policy (your choice): LINE-LEVEL + REVIEW LIST.
  * git does a 3-way merge: edits to different parts of the same file are
    combined automatically -- nobody's work is lost.
  * It STOPS only when you both edited the SAME lines (a true conflict).
  * Either way it prints every file you BOTH touched, so you can spot-check
    even the ones git merged cleanly.

Exit codes (the .bat checks these):
  0  -> clean (already in sync, or merged with no conflict). Deploy may proceed.
  1  -> conflict, error, or a merge still needs resolving. Deploy MUST abort.

Usage:  python dev_sync.py [REPO_PATH] [BRANCH]   (defaults: cwd, Legendary)
"""
import os
import subprocess
import sys
from datetime import datetime

REPO   = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
BRANCH = sys.argv[2] if len(sys.argv) > 2 else "Legendary"
REMOTE = "fjb"
TRACK  = f"{REMOTE}/{BRANCH}"

os.chdir(REPO)


def git(*args, check=True):
    r = subprocess.run(["git", *args], capture_output=True, text=True)
    if check and r.returncode != 0:
        sys.stdout.write(r.stdout)
        sys.stderr.write(r.stderr)
        fail(f"git {' '.join(args)}  ->  exit {r.returncode}")
    return r.stdout.strip()


def out(msg=""):
    print(msg, flush=True)


def banner(title):
    out()
    out("=" * 64)
    out(f"  {title}")
    out("=" * 64)


def fail(msg):
    banner("DEV SYNC ABORTED -- nothing shipped")
    out(f"  {msg}")
    out()
    sys.exit(1)


# --- branch sanity -----------------------------------------------------------
cur = git("rev-parse", "--abbrev-ref", "HEAD")
if cur != BRANCH:
    fail(f"You are on branch '{cur}', not '{BRANCH}'. Switch first: git checkout {BRANCH}")

# --- 0. a merge from a previous run still hanging around? ---------------------
if os.path.exists(os.path.join(".git", "MERGE_HEAD")):
    unmerged = git("diff", "--name-only", "--diff-filter=U").split()
    if unmerged:
        banner("CONFLICT FLAG -- a previous merge is still UNRESOLVED")
        out("  You both edited the same lines in these files. Pick a side or")
        out("  combine them, then commit -- the deploy will not run until you do:")
        for f in unmerged:
            out(f"     !!  {f}")
        out()
        out("  Resolve options per file:")
        out(f"     keep YOURS : git checkout --ours   <file> && git add <file>")
        out(f"     take THEIRS: git checkout --theirs <file> && git add <file>")
        out(f"     combine    : edit the <<<<<<< / ======= / >>>>>>> markers, git add <file>")
        out(f"  then:  git commit --no-edit   (and re-run the deploy)")
        sys.exit(1)
    # conflicts already resolved but the merge was never committed -> finish it
    git("commit", "--no-edit")
    out("  Finished a previously-resolved merge. Proceeding.")
    sys.exit(0)

# --- 1. commit your own working-tree changes so the merge is clean -----------
git("add", "-A")
if git("diff", "--cached", "--name-only"):
    stamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    git("commit", "-m", f"local pre-sync {stamp}")
    out("  Committed your local working-tree changes (so nothing is lost).")
else:
    out("  No local changes to commit.")

# --- 2. fetch the collaborator's commits -------------------------------------
out(f"  Fetching {TRACK} ...")
git("fetch", REMOTE, BRANCH)

# --- 3. is there anything to pull in? ----------------------------------------
counts = git("rev-list", "--left-right", "--count", f"HEAD...{TRACK}").split()
ahead, behind = (int(counts[0]), int(counts[1])) if len(counts) == 2 else (0, 0)
if behind == 0:
    out(f"  Already in sync with the collaborator (you are {ahead} ahead, 0 behind). Nothing to merge.")
    sys.exit(0)

base   = git("merge-base", "HEAD", TRACK)
mine   = set(git("diff", "--name-only", base, "HEAD").splitlines())
theirs = set(git("diff", "--name-only", base, TRACK).splitlines())
both   = sorted(mine & theirs)
only_t = sorted(theirs - mine)

banner(f"Collaborator is {behind} commit(s) ahead -- merging their work in")
if only_t:
    out(f"  Incoming (only THEY changed -- {len(only_t)} file(s)):")
    for f in only_t[:60]:
        out(f"     +  {f}")
    if len(only_t) > 60:
        out(f"     ... and {len(only_t) - 60} more")
if both:
    out()
    out(f"  >>> REVIEW LIST: you BOTH changed these {len(both)} file(s) <<<")
    for f in both:
        out(f"     !  {f}")

# --- 4. line-level 3-way merge -----------------------------------------------
out()
out("  Merging (line-level)...")
r = subprocess.run(["git", "merge", "--no-edit", TRACK], capture_output=True, text=True)
out(r.stdout.strip())
if r.stderr.strip():
    out(r.stderr.strip())

conflicts = git("diff", "--name-only", "--diff-filter=U").split()
if conflicts:
    banner("CONFLICT FLAG -- you both edited the SAME lines")
    out("  The deploy is ABORTED. Resolve these, then re-run it:")
    for f in conflicts:
        out(f"     !!  {f}")
    out()
    out("  Per file:")
    out("     keep YOURS : git checkout --ours   <file> && git add <file>")
    out("     take THEIRS: git checkout --theirs <file> && git add <file>")
    out("     combine    : edit the <<<<<<< markers, then git add <file>")
    out("  then:  git commit --no-edit   (re-running the deploy also finishes it)")
    sys.exit(1)

banner("Merge clean -- collaborator's work is integrated")
if both:
    out("  NOTE: the REVIEW LIST files above were auto-merged (no line clash),")
    out("        but both of you touched them -- worth a quick look before it ships.")
out("  Proceeding with the deploy.")
sys.exit(0)
