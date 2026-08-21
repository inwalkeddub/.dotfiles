---
name: org-style
description: Kevin's org-mode house style — load BEFORE writing any org output for him (files in /Volumes/dev/org, org snippets, summaries destined for his org repo), from any surface (Claude Code, Desktop/cowork). The snap and org-summary skills defer to this file for all formatting/naming; do not duplicate its rules elsewhere.
---

# Org house style — single source of truth

Registry of ratified conventions for org output. Kevin is deliberately growing
this style as he adopts more org features: when a doc would benefit from an
unratified feature (tags, TODO keywords, agenda hooks, org-attach, …),
*propose* it — don't unilaterally adopt. Once he ratifies a convention, record
it here so every future output (any Claude, any surface) follows it.

## Destination & naming
- Org docs live in =/Volumes/dev/org= (a git repo; Kevin commits and pushes
  himself — never run git operations there).
- Filenames: lowercase kebab-case. Claude-generated docs carry the =claude-=
  prefix. Dated docs: =claude-session-<YYYY-MM-DD>-<topic>.org=.
- The dated corpus is *chronological, append-only, immutable*: never edit,
  merge into, or refresh an existing doc — continue a topic by linking to the
  prior file. Same-day/same-topic collision → =-2= suffix or a more specific
  topic.
- Every new =claude-*= file gets a link in =claude-snapshots.org= under
  =* Session snapshots (dated)=, format
  =- [[file:<filename>][<YYYY-MM-DD> — <Title>]]=, kept in date order.
- Kevin's own hand-authored topic files (=<topic>.org=; e.g. =claude.org= is
  his Claude *agenda*) are his — never restructure them.

## Document skeleton
- Open with =#+title: <Short Title>= and =#+startup: overview=, then a blank
  line.
- ONE top-level headline (=*=) per doc so the tree merges cleanly into other
  files; nest with =**= / =***=.
- Under the top headline: a short preamble — what this doc is, with
  =[[file:...]]= links to related docs.

## Markup
- ==verbatim== for paths, commands, filenames, identifiers, versions.
- =*bold*= for labels/strong emphasis, =/italic/= for light emphasis.
- Real em-dash (—), never =---= (org renders a lone =-----= line as a
  horizontal rule; pandoc conversions: fix =" --- "= → =" — "=).
- Lists with =- =; checkboxes =- [ ]= / =- [x]= for task state. In immutable
  dated docs, never retro-tick a checkbox — completion is recorded in a later
  doc.
- Org tables for tabular data.
- Links: =[[file:doc.org][desc]]= within the repo, =[[https://…][desc]]=
  external.
- Code: =#+begin_src <lang>= … =#+end_src=. Command output:
  =#+begin_example= … =#+end_example=. When commands + outputs carry the
  evidence for a conclusion, preserve them verbatim.

## Drawers & metadata
- NO =:PROPERTIES:= / =:ID:= / =:CUSTOM_ID:= drawers on prose/summary docs
  (strip them from pandoc conversions).
- Property drawers ARE the convention where they carry real per-entry data —
  e.g. =quotes.org= uses =:AUTHOR:= / =:SOURCE:= per quote. Data files, not
  prose.
- No TODO keywords, tags, or priorities yet — not ratified; propose when
  genuinely useful.

## Content guidelines (for summaries/snapshots)
- Write for future-Kevin resuming months later; absolute dates, never
  "yesterday".
- Precision over prose: exact paths, versions, commands.
- Decisions carry the *why* and the rejected alternatives.
- Keep evidence that earned a conclusion; drop narration of dead ends.
