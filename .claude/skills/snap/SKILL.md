---
name: snap
description: Snapshot recent work into Kevin's org directory (/Volumes/dev/org, claude- naming, claude-snapshots.org index). Two triggers. "snap that as is" — mark the indicated response for verbatim inclusion in the next snapshot (stash it immediately; nothing written to the org dir yet). "snap session" or /snap — write the snapshot of work since the last snapshot: summarized per the guidelines, plus every marked response included as-is, uncompressed.
---

# Snapshot recent work into the org directory

Two ways in:

- **"snap that as is"** (mid-session, about a specific response) → *mark mode*:
  stash that response for the next snapshot. No org-dir writes yet.
- **"snap session"** / `/snap` → *snapshot mode*: two phases — snapshot, then
  persist.

## Mark mode — "snap that as is"

Kevin liked a specific response and wants it in the eventual session snapshot
**uncompressed, as delivered**.

1. Immediately append the response **verbatim** (raw markdown) to the stash
   file `~/Claude/snap-pending/<cwd-key>.md` (create the directory if needed),
   preceded by a separator line with a short slug (`--- <slug> ---`).
   `<cwd-key>` is the session's working directory with `/` replaced by `-`
   (e.g. `/Users/kevinrathbun` → `-Users-kevinrathbun.md`). Stashing now
   protects the exact text from context compaction in long sessions. The stash
   is keyed by working directory, not session id, and lives outside `/tmp`,
   because a resume can change the session id and withdraw the session
   scratchpad (it did on 2026-10-10). Never use the scratchpad for it.
2. Acknowledge briefly and carry on. Nothing touches `/Volumes/dev/org` until
   "snap session".

## Snapshot mode — Phase 1: snapshot the chunk of work

Snapshot the work since the last snapshot (or session start) using this
structure. Omit sections that are empty; do not pad.

1. **What we built / changed (concrete state)** — files created or modified
   (with paths), commands run that changed system state, tools installed (with
   verified versions). Precision over prose: paths, versions, exact names.
2. **Key decisions** — each decision plus the *why*, especially options
   rejected and the reason. These are the highest-value lines; write them so
   they make sense months later without the chat.
3. **Concepts nailed down** — explanations or mental models established during
   the work, compressed to their load-bearing facts. Include corrections of
   earlier misunderstandings ("X was overstated; actually Y").
4. **As-is responses** — every response marked via "snap that as is", read
   back from the stash file (`~/Claude/snap-pending/<cwd-key>.md`, see Mark
   mode). Each gets its own
   subsection, transferred faithfully at the detail level originally
   delivered — markdown→org conversion only, **no compression**. If the stash
   is missing but marks happened, say so rather than reconstructing from
   memory.
5. **Still pending** — unfinished items as org checkboxes `- [ ]`, with enough
   context to resume cold.

Guidelines:
- Write for future-Kevin resuming after months away, not for the user who was
  just present.
- Keep evidence that earned a conclusion ("`brew uses --installed libgccjit` →
  emacs-plus-app, so don't uninstall"), drop narration of the search that led
  nowhere.
- Convert relative dates ("yesterday") to absolute dates.
- Compression applies to sections 1–3 and 5 — never to section 4.

## Snapshot mode — Phase 2: persist to the org directory

Target directory: **/Volumes/dev/org** (a git repo; Kevin's org knowledge base).

1. **Naming, style, immutability, index**: apply the `org-style` skill
   (`~/.claude/skills/org-style/SKILL.md`) — the single source of truth for
   destination, `claude-session-<date>-<topic>.org` naming, append-only
   immutability, document skeleton, markup, and the `claude-snapshots.org`
   index update. Do not duplicate or override its rules here. Snap-specific:
   the topic slug is yours to choose (Kevin doesn't supply titles), and the
   `* Reference docs (legacy)` index section never receives snapshots.
2. **No git operations** — Kevin commits and pushes the org repo himself. Just
   tell him what was written so he can push.
3. If `/Volumes/dev/org` is not mounted/available, do not write elsewhere
   silently — tell the user and ask where to save.
4. **After writing, delete the stash file**
   (`~/Claude/snap-pending/<cwd-key>.md`) so the next snapshot starts clean.

## Notes

- If converting existing markdown, use
  `nix shell nixpkgs#pandoc --command pandoc -f gfm -t org`, then strip
  pandoc's `:PROPERTIES:`/`:CUSTOM_ID:`/`:END:` lines and fix ` --- ` → ` — `.
