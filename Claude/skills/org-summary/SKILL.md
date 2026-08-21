---
name: org-summary
description: Summarize requested work or discussion into an org doc in Kevin's house style. Use for "summarize X to org" or /org-summary with an optional topic argument — ad-hoc summaries, any surface. NOT for end-of-session Claude Code snapshots ("snap session" / marked responses) — that's the snap skill.
---

# Summarize to org

1. **Scope**: the argument names what to summarize; with no argument, the
   current discussion / chunk of work.
2. **Style**: FIRST load the =org-style= skill
   (~/.claude/skills/org-style/SKILL.md) and follow it for all formatting,
   naming, destination, immutability, and index rules. Do not improvise
   style; do not duplicate its rules.
3. **Structure**: fit the content — an ad-hoc summary need not use snap's
   section template. Always keep: a preamble linking related docs, decisions
   with the why, and pending items as checkboxes when follow-up work exists.
4. **Destination**: /Volumes/dev/org as a dated file per org-style, plus the
   index link. If the org dir is not accessible from this surface (e.g. a
   chat without file access), emit the complete org source in one code block
   with the intended filename stated, for Kevin to save.
5. **No git operations** — report what was written so Kevin can push.
