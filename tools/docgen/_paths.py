"""Source-path resolution for docgen generators.

A generator's source may live in the repo (committed and visible to CI) or
only on the live server's checkout (gitignored). `resolve_source()` checks
the repo first, then `$LEGENDARY_LIVE_ROOT` if set.

CI never sees `$LEGENDARY_LIVE_ROOT`, so it only generates pages whose source
is committed. Generators gracefully skip when their source isn't available
rather than writing an empty/wrong page.

FAIL-CLOSED FRESHNESS GATE
--------------------------
The live docs site (OVH) rebuilds from the live server every hour. If a
generator's source is renamed/moved/deleted, `resolve_source` used to return
None and the generator would silently `return`, leaving that page's LAST
value published forever — the site drifts from the server and nobody notices.

To stop that: when building against the live tree (`$LEGENDARY_LIVE_ROOT`
set) we treat a *required* missing source as a hard error — `resolve_source`
raises `SourceMissing`. The orchestrator catches it, marks the generator
failed, and (in strict mode) fails the whole build so the refresh script
keeps the last-good site and the dead-man's-switch alarms, instead of
publishing a silently-stale page.

Off-box / CI (`$LEGENDARY_LIVE_ROOT` unset) keeps the old tolerant behavior:
required-missing returns None so live-only pages skip cleanly.

A generator with a genuinely OPTIONAL input passes `required=False` to opt out
of the gate for that lookup.
"""
from __future__ import annotations

import os
from pathlib import Path


class SourceMissing(FileNotFoundError):
    """A required generator source could not be found under the repo or the
    live tree while building the live site. Raising (rather than returning
    None) turns a silent stale page into a loud, build-failing error."""


# Resolution ledger for the current run. `reset_resolutions()` clears it at the
# start of a docgen run; the orchestrator reads it afterward to report which
# sources came from the repo vs the live tree vs went missing.
_RESOLUTIONS: list[tuple[str, str]] = []  # (sub_path, "repo" | "live" | "missing")


def reset_resolutions() -> None:
    _RESOLUTIONS.clear()


def get_resolutions() -> list[tuple[str, str]]:
    return list(_RESOLUTIONS)


def strict_mode() -> bool:
    """Strict (fail-closed) mode is on when building against the live tree."""
    return bool(os.environ.get("LEGENDARY_LIVE_ROOT"))


def fail_closed() -> bool:
    """Whether the freshness gate is ENFORCING (blocks a stale deploy) rather
    than just reporting. Opt-in via `DOCGEN_STRICT_FAIL=1` so the gate can be
    landed inert (identical deploy behavior) and switched on once the live
    tree's source audit is clean. Only meaningful when building against live."""
    return strict_mode() and bool(os.environ.get("DOCGEN_STRICT_FAIL"))


def _raising() -> bool:
    """Whether a required-missing source should raise. Audit mode
    (`DOCGEN_AUDIT=1`) records misses but never raises, so a single run
    enumerates EVERY missing source across all generators instead of
    fail-fast stopping at the first one. Raising is otherwise gated on the
    gate being in enforcing mode."""
    return fail_closed() and not os.environ.get("DOCGEN_AUDIT")


def resolve_source(repo_root: Path, sub_path: str, required: bool = True) -> Path | None:
    """Prefer the committed repo file so docs always reflect what's in GitHub.
    Falls back to LEGENDARY_LIVE_ROOT only for files not tracked in the repo
    (e.g. gitignored settings/*.lua). CI never sets the env var so it always
    uses repo content.

    When `required` (the default) and the file is missing *while building the
    live site* (`$LEGENDARY_LIVE_ROOT` set), raise `SourceMissing` so the build
    fails loudly instead of publishing a silently-stale page. Pass
    `required=False` for genuinely optional inputs to keep the old
    return-None-on-missing behavior.
    """
    repo_path = repo_root / sub_path
    if repo_path.exists():
        _RESOLUTIONS.append((sub_path, "repo"))
        return repo_path
    live = os.environ.get("LEGENDARY_LIVE_ROOT")
    if live:
        live_path = Path(live) / sub_path
        if live_path.exists():
            _RESOLUTIONS.append((sub_path, "live"))
            return live_path
    _RESOLUTIONS.append((sub_path, "missing"))
    if required and _raising():
        raise SourceMissing(
            f"required docgen source not found under repo or "
            f"$LEGENDARY_LIVE_ROOT: {sub_path}"
        )
    return None
