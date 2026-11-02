#!/usr/bin/env python3
"""Render ALL Claude Code transcripts to foldable org files in the org repo.

For every top-level session transcript ~/.claude/projects/<cwd-key>/<id>.jsonl
(subagent transcripts under */subagents/ are skipped), write a verbatim org
render into /Volumes/dev/org/claude-history/, splitting long sessions into
~18k-line parts at user-turn boundaries (so each part opens comfortably and
stays under Doom's 20k-line so-long rule). Then regenerate the index
/Volumes/dev/org/claude-history.org, grouped by project.

Designed to run nightly via launchd. Properties:
  * Idempotent and append-only-friendly: the .jsonl transcripts only grow, and
    splits happen at turn boundaries, so parts 1..N-1 of a session are
    byte-stable between runs; only the tail part of an active session changes.
  * Self-contained: stdlib only; imports the render core from render_transcript.
  * Safe-by-default: secrets are masked by the renderer, and every written file
    is grepped for leaked full secrets as a second net (LEAK_PATTERNS).

Exit non-zero (with a clear log line) if the org volume isn't mounted or if any
output file appears to leak a secret.
"""
import os, sys, glob, datetime
import render_transcript as R

HOME        = os.path.expanduser("~")
PROJECTS    = os.path.join(HOME, ".claude", "projects")
ORG_ROOT    = "/Volumes/dev/org"
HIST_DIR    = os.path.join(ORG_ROOT, "claude-history")
INDEX       = os.path.join(ORG_ROOT, "claude-history.org")
MAX_LINES   = 18000          # per-part body line budget (headroom under 20k)

def log(msg):
    print(f"[{datetime.datetime.now().isoformat(timespec='seconds')}] {msg}", flush=True)

def date_of(ts):
    return (ts or "")[:10]

def split_parts(body):
    """Split body chunks into parts of <= MAX_LINES, only at '* ' boundaries."""
    parts, cur, nlines = [], [], 0
    for ch in body:
        boundary = ch.startswith("\n* ") or ch.startswith("* ")
        if boundary and nlines >= MAX_LINES and cur:
            parts.append(cur); cur, nlines = [], 0
        cur.append(ch); nlines += ch.count("\n") + 1
    if cur:
        parts.append(cur)
    return parts or [[]]

def leak_scan(text):
    hits = []
    for pat in R.LEAK_PATTERNS:
        hits += pat.findall(text)
    return hits

def main():
    if not os.path.isdir(ORG_ROOT):
        log(f"ERROR: org volume not mounted ({ORG_ROOT} absent) — aborting."); sys.exit(1)
    os.makedirs(HIST_DIR, exist_ok=True)

    sessions = sorted(glob.glob(os.path.join(PROJECTS, "*", "*.jsonl")))  # 2 levels: skips */subagents/*
    log(f"{len(sessions)} candidate transcripts under {PROJECTS}")

    by_project = {}   # project -> list of entry dicts
    total_parts = total_leaks = skipped = 0

    for jsonl in sessions:
        try:
            meta, body = R.build_entries(jsonl, inc_think=True, inc_tools=True)
        except Exception as e:
            log(f"skip (parse error) {jsonl}: {e}"); continue
        if meta["turns"] == 0:
            skipped += 1; continue

        sid = meta["sid"]; short = sid[:8]; proj = meta["project"]
        d0 = date_of(meta["first_ts"])
        base = f"claude-history-{proj}-{d0}-{short}"
        parts = split_parts(body)
        nparts = len(parts)

        part_files = []
        for k, chunks in enumerate(parts, 1):
            name = f"{base}.org" if nparts == 1 else f"{base}-p{k}.org"
            text = R.file_text(sid, chunks, True, True,
                               part=k, nparts=nparts)
            leaks = leak_scan(text)
            if leaks:
                total_leaks += len(leaks)
                log(f"LEAK in {name}: {len(leaks)} match(es) — e.g. {leaks[0][:12]}…")
            with open(os.path.join(HIST_DIR, name), "w") as f:
                f.write(text)
            part_files.append(name); total_parts += 1

        by_project.setdefault(proj, []).append(dict(
            proj=proj, sid=sid, short=short, turns=meta["turns"],
            d0=d0, d1=date_of(meta["last_ts"]), hook=meta["first_prompt"],
            nparts=nparts, file=part_files[0],
            ncompact=len(meta["compactions"])))

    # NO pruning: this script never deletes. Kevin commits the mirror to git and
    # prefers harmless redundancy (a stale file from a renamed project or a changed
    # naming/render scheme) over any risk of an accidental delete — e.g. a session
    # whose .jsonl was removed should NOT vanish from the org mirror. Stale orphans
    # simply linger on disk (and in git); the index below only lists what we built
    # this run, so an orphan is unlinked clutter, not a live entry. Clean up by hand
    # if it ever bothers you.

    write_index(by_project)
    log(f"done: {total_parts} part-files across {sum(len(v) for v in by_project.values())} "
        f"sessions ({skipped} empty skipped); {total_leaks} leak hit(s).")
    if total_leaks:
        sys.exit(2)

def write_index(by_project):
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    out = []
    out.append(R.HEADER_PROP)
    out.append("# GENERATED by ~/Claude/history/build_all_history.py — regenerated")
    out.append("# nightly; do not hand-edit (your edits will be overwritten).")
    out.append("#+title: Claude Transcript History")
    out.append("#+startup: overview")
    out.append("")
    out.append("* Claude session transcripts (generated mirrors)")
    out.append("Verbatim, foldable renders of every Claude Code session transcript,")
    out.append("one subtree per project (mirroring the tmux sessions). These are")
    out.append("machine-generated companions to the curated [[file:claude-snapshots.org][snapshots]] — not part")
    out.append(f"of the immutable snapshot corpus. Regenerated nightly; last: {now}.")
    out.append("Long sessions are split into =-pN= parts at turn boundaries.")
    out.append("")
    for proj in sorted(by_project):
        out.append(f"** {proj}")
        for e in sorted(by_project[proj], key=lambda x: (x["d0"], x["sid"])):
            rng = e["d0"] if e["d0"] == e["d1"] else f"{e['d0']}→{e['d1']}"
            extras = f"{e['turns']} turns, {rng}"
            if e["nparts"] > 1:
                extras += f", {e['nparts']} parts"
            if e["ncompact"]:
                extras += f", {e['ncompact']} compaction(s)"
            desc = f"{e['d0']} — {proj} {e['short']}"
            hook = e["hook"] or "(no opening prompt)"
            out.append(f"- [[file:claude-history/{e['file']}][{desc}]] :: {hook} · {extras}")
        out.append("")
    with open(INDEX, "w") as f:
        f.write("\n".join(out))

if __name__ == "__main__":
    main()
