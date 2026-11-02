#!/usr/bin/env python3
"""Render a Claude Code .jsonl transcript into a foldable org file.

Reconstructs the ENTIRE conversation — across every compaction boundary —
which the TUI's Ctrl-O viewer can't show after a resume. Output is one org
heading per turn, so you fold/scroll/search the whole thing in Emacs.

By DEFAULT the render is fully verbatim: user prompts, assistant text,
assistant internal *thinking*, tool *inputs*, and tool *outputs* — nothing
summarized or dropped. The only non-verbatim text is the org headings
(tool name + timestamps), which are navigation labels, not summaries.

Usage:
  render_transcript.py <session.jsonl> [-o out.org] [--nothinking] [--notools]

  --nothinking  omit the assistant's internal reasoning blocks
  --notools     omit tool calls and their results

Secrets (API keys / tokens) are masked in the output — see SECRET_PATTERNS.

This module is also imported by build_all_history.py; the reusable core is
`build_entries()` (parse → meta + body chunks) and `file_text()` (wrap a part
with the prop line + title header).  Keep both importable.
"""
import json, re, argparse, os

# --- secret masking -------------------------------------------------------
# Each pattern keeps a short readable prefix and masks the rest, so the output
# shows *that* a secret was present and its kind, without leaking the value.
# Broadened well past sk-ant- because these transcripts can land in a pushed
# git repo and span many projects (GitHub tokens, AWS, Slack, Google, OpenAI).
SECRET_PATTERNS = [
    re.compile(r'(sk-ant-[A-Za-z0-9_-]{4})[A-Za-z0-9_-]+'),      # Anthropic
    re.compile(r'(sk-proj-[A-Za-z0-9_-]{4})[A-Za-z0-9_-]+'),     # OpenAI project
    re.compile(r'(sk-[A-Za-z0-9]{3})[A-Za-z0-9]{17,}'),          # generic sk- key
    re.compile(r'(gh[pousr]_[A-Za-z0-9]{3})[A-Za-z0-9]{17,}'),   # GitHub token
    re.compile(r'(github_pat_[A-Za-z0-9]{3})[A-Za-z0-9_]{17,}'), # GitHub fine-grained PAT
    re.compile(r'(AKIA[0-9A-Z]{3})[0-9A-Z]{13}'),                # AWS access key id
    re.compile(r'(xox[baprs]-[A-Za-z0-9]{3})[A-Za-z0-9-]{10,}'), # Slack token
    re.compile(r'(AIza[0-9A-Za-z_-]{3})[0-9A-Za-z_-]{32}'),      # Google API key
]
# Danger patterns: a leaked FULL secret surviving the mask. build_all greps the
# written output with these as a second safety net; a hit means masking missed.
LEAK_PATTERNS = [
    re.compile(r'sk-ant-[A-Za-z0-9_-]{24,}'),
    re.compile(r'sk-proj-[A-Za-z0-9_-]{24,}'),
    re.compile(r'gh[pousr]_[A-Za-z0-9]{30,}'),
    re.compile(r'github_pat_[A-Za-z0-9_]{30,}'),
    re.compile(r'AKIA[0-9A-Z]{16}'),
    re.compile(r'xox[baprs]-[A-Za-z0-9-]{20,}'),
    re.compile(r'AIza[0-9A-Za-z_-]{35}'),
]

def mask(s):
    if not isinstance(s, str):
        return s
    for pat in SECRET_PATTERNS:
        s = pat.sub(r'\1…MASKED', s)
    return s

# --- formatting helpers ---------------------------------------------------
def indent(text):
    # 2-space indent so no body line starting with '*' is parsed as an org heading
    return "\n".join("  " + ln for ln in text.splitlines()) if text else "  "

def firstline(s, n=70):
    s = " ".join(s.split())
    return (s[:n] + "…") if len(s) > n else s

def blocks_text(content):
    """Concatenate verbatim text blocks from a content list."""
    out = [b.get("text", "") for b in content
           if isinstance(b, dict) and b.get("type") == "text"]
    return "\n".join(out).strip()

# NOTE: in the content blocks the "thinking" field is blanked (only a signature
# is kept for API replay). The human-readable reasoning is persisted separately
# in the message line's top-level "thinkingDisplay" field — that's what we render.

def tool_uses(content):
    """(name, verbatim-input-json) for each tool_use block."""
    out = []
    for b in content:
        if isinstance(b, dict) and b.get("type") == "tool_use":
            inp = json.dumps(b.get("input", {}), indent=2, ensure_ascii=False)
            out.append((b.get("name", "?"), inp))
    return out

def has_tool_result(content):
    return isinstance(content, list) and any(
        isinstance(b, dict) and b.get("type") == "tool_result" for b in content)

def tool_result_text(content):
    """Verbatim text of tool_result blocks; images noted, not dumped."""
    out = []
    for b in content:
        if not (isinstance(b, dict) and b.get("type") == "tool_result"):
            continue
        c = b.get("content")
        if isinstance(c, str):
            out.append(c)
        elif isinstance(c, list):
            for bb in c:
                if isinstance(bb, dict):
                    if bb.get("type") == "text":
                        out.append(bb.get("text", ""))
                    elif bb.get("type") == "image":
                        out.append("[image omitted]")
    return "\n".join(out).strip()

def is_real_user(content):
    """A typed prompt (str, or a list with a text block) — not a tool_result."""
    if isinstance(content, str):
        return True
    if isinstance(content, list):
        return any(isinstance(b, dict) and b.get("type") == "text" for b in content)
    return False

# --- core -----------------------------------------------------------------
HEADER_PROP = "# -*- mode: org -*-"  # explicit file-local mode → Doom so-long honors it

def project_from_cwd(cwd):
    """A short, readable project label from the session's working directory.

    Anchored at /Volumes/dev or $HOME; uses the last 1–2 path segments so e.g.
    /Volumes/dev/moonbath/app → "moonbath-app" and the home dir → "home".
    The directory KEY under ~/.claude/projects is NOT used: it maps both '/'
    and '-' to '-', so it can't be reversed unambiguously (that very dir,
    -Volumes-dev-moonbath-app, is really /Volumes/dev/moonbath/app)."""
    home = os.path.expanduser("~")
    if not cwd:
        return "home"
    cwd = cwd.rstrip("/")
    if cwd == home:
        return "home"
    for root in ("/Volumes/dev", home, "/Volumes"):
        if cwd.startswith(root + "/"):
            segs = cwd[len(root) + 1:].split("/")
            return "-".join(segs[-2:]) if len(segs) > 1 else segs[0]
    return os.path.basename(cwd) or "home"

def build_entries(jsonl, inc_think=True, inc_tools=True):
    """Parse a transcript. Return (meta, body_chunks).

    meta: dict with sid, turns, first_ts, last_ts, first_prompt, cwd, project,
          compactions (list of (ts, trigger)).
    body_chunks: list of org strings (the conversation, no header), each top
          user turn / compaction boundary starting with '\\n* '.
    """
    sid = os.path.basename(jsonl).replace(".jsonl", "")
    turn = 0
    body = []
    first_ts = last_ts = None
    first_prompt = ""
    cwd = None
    compactions = []
    pending_trig = []    # compactMetadata lives on a sibling record just before
                         # the isCompactSummary; pair them by order, not timestamp
                         # (their timestamps can differ by a second).

    for line in open(jsonl, errors="replace"):
        line = line.strip()
        if not line:
            continue
        try:
            d = json.loads(line)
        except Exception:
            continue
        if cwd is None and d.get("cwd"):
            cwd = d.get("cwd")
        # Capture compaction trigger BEFORE the type filter: the record carrying
        # compactMetadata is not itself the isCompactSummary (user) message, and
        # may be a type we otherwise skip. Pair to the summary by timestamp.
        cm = d.get("compactMetadata")
        if cm and cm.get("trigger"):
            cts = (d.get("timestamp") or "")[:19].replace("T", " ")
            pending_trig.append(cm["trigger"])
            compactions.append((cts, cm["trigger"]))
        t = d.get("type")
        if t not in ("user", "assistant"):
            continue
        if d.get("isMeta") or d.get("isSidechain"):
            continue
        msg = d.get("message")
        if not isinstance(msg, dict):
            continue
        content = msg.get("content")
        ts = (d.get("timestamp") or "")[:19].replace("T", " ")
        if ts:
            first_ts = first_ts or ts
            last_ts = ts

        if d.get("isCompactSummary"):
            trig = pending_trig.pop(0) if pending_trig else None
            tag = f"  [{trig}]" if trig else ""
            body.append(f"\n* ⟐ ───── COMPACTION BOUNDARY  {ts}{tag} ─────\n")
            b = content if isinstance(content, str) else blocks_text(content)
            body.append(indent(mask(b)) + "\n")
            continue

        if t == "user":
            if is_real_user(content):
                b = content if isinstance(content, str) else blocks_text(content)
                b = mask(b).strip()
                if not b:
                    continue
                turn += 1
                # Index hook: first *typed* prompt, skipping slash-command
                # wrappers (<command-name>/login…</command-name> etc.) that are
                # recorded as user turns but say nothing about the session.
                if not first_prompt:
                    bl = b.lstrip()
                    if not (bl.startswith("<command-name>") or
                            bl.startswith("<command-message>") or
                            bl.startswith("<local-command")):
                        first_prompt = firstline(b, 90)
                body.append(f"\n* [{turn}] {ts}  ▶ USER — {firstline(b)}\n")
                body.append(indent(b) + "\n")
            elif inc_tools and has_tool_result(content):
                txt = mask(tool_result_text(content))
                if txt:
                    body.append(f"** ⟵ TOOL RESULT  {ts}\n")
                    body.append(indent(txt) + "\n")
        else:  # assistant
            txt = mask(blocks_text(content))
            th = mask(d.get("thinkingDisplay") or "") if inc_think else ""
            tu = tool_uses(content) if inc_tools else []
            if not (txt or th or tu):
                continue
            body.append(f"** 🤖 ASSISTANT  {ts}\n")
            if th:
                body.append("*** 🧠 thinking\n" + indent(th) + "\n")
            if txt:
                body.append(indent(txt) + "\n")
            for name, inp in tu:
                body.append(f"*** ⚙ tool_use: {name}\n" + indent(mask(inp)) + "\n")

    project = project_from_cwd(cwd)
    meta = dict(sid=sid, turns=turn, first_ts=first_ts, last_ts=last_ts,
                first_prompt=first_prompt, cwd=cwd, project=project,
                compactions=compactions)
    return meta, body

def header(sid, inc_think, inc_tools, part=None, nparts=None):
    parts = ["prompts", "assistant text"]
    if inc_think: parts.append("thinking")
    if inc_tools: parts.append("tool I/O")
    title = f"Transcript {sid}"
    if nparts and nparts > 1:
        title += f"  (part {part}/{nparts})"
    return (f"{HEADER_PROP}\n"
            "# GENERATED — do not hand-edit (regenerated from the .jsonl transcript).\n"
            f"#+title: {title}\n#+startup: overview\n"
            "# Full conversation across all compactions, verbatim ("
            + ", ".join(parts) + ").\n"
            "# Fold: TAB on a heading; S-TAB cycles all. Search: / or C-s.\n")

def file_text(sid, body_chunks, inc_think, inc_tools, part=None, nparts=None):
    return "\n".join([header(sid, inc_think, inc_tools, part, nparts)] + body_chunks)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("jsonl")
    ap.add_argument("-o", "--out")
    ap.add_argument("--nothinking", action="store_true", help="omit assistant reasoning")
    ap.add_argument("--notools", action="store_true", help="omit tool calls and results")
    a = ap.parse_args()
    inc_think = not a.nothinking
    inc_tools = not a.notools
    out = a.out or (os.path.splitext(a.jsonl)[0] + ".org")
    meta, body = build_entries(a.jsonl, inc_think, inc_tools)
    with open(out, "w") as f:
        f.write(file_text(meta["sid"], body, inc_think, inc_tools))
    print(f"wrote {out}  ({meta['turns']} user turns)")

if __name__ == "__main__":
    main()
