---
name: org-style
description: Kevin's org-mode house style — load BEFORE writing any org output for him (files in /Volumes/dev/org, org snippets, summaries destined for his org repo), from any surface (Claude Code, Desktop/cowork). The snap and org-summary skills defer to this file for all formatting/naming; do not duplicate its rules elsewhere.
---

# Org house style — single source of truth

Registry of ratified conventions for org output. Kevin is deliberately growing
this style as he adopts more org features: when a doc would benefit from a
still-unratified feature (tags, priorities, org-attach, …), *propose* it —
don't unilaterally adopt. Once he ratifies a convention, record it here so
every future output (any Claude, any surface) follows it.

## Destination & naming
- Org docs live in =/Volumes/dev/org= (a git repo; Kevin commits and pushes
  himself — never run git operations there).
- Filenames: lowercase kebab-case. Claude-generated docs carry the =claude-=
  prefix. Dated session snapshots live in the =claude-session/= subdirectory
  (moved there 2026-11-02), named
  =claude-session/claude-session-<YYYY-MM-DD>-<topic>.org=. The index and
  Kevin's topic files stay at the repo root. A link from a snapshot *up* to a
  root file (e.g. =bankruptcy.org=) therefore uses =../=; links *between*
  snapshots stay bare filenames (they resolve within =claude-session/=).
- The dated corpus is *chronological, append-only, immutable*: never edit,
  merge into, or refresh an existing doc — continue a topic by linking to the
  prior file. Same-day/same-topic collision → =-2= suffix or a more specific
  topic. (*Sanctioned exception*: a one-time structural move of the corpus —
  e.g. the 2026-11-02 relocation into =claude-session/= — may mechanically
  rewrite link *paths* to keep existing links resolving. Paths only, never
  content; it preserves meaning and is not a content edit.)
- *Generated mirrors are the exception to the immutable rule.* The
  =claude-history-*.org= files in =claude-history/= (and their
  =claude-history.org= index) are machine-generated, regenerable renders of the
  raw =~/.claude/projects/*.jsonl= transcripts, rewritten nightly by
  =~/Claude/history/build_all_history.py=. The append-only/immutable rule above
  does NOT apply to them: never hand-edit them (edits are overwritten), and they
  index into =claude-history.org=, not =claude-snapshots.org=. The deliberate
  =claude-history-= prefix (vs =claude-session-=) is what marks them so no
  session mistakes them for the curated snapshot corpus.
- Every new =claude-*= file gets a link in =claude-snapshots.org= under
  =* Session snapshots (dated)=, kept in date order. The index is a *retrieval
  aid*: each entry MUST carry a one-line hook so a future session can judge
  relevance WITHOUT opening the file. Format:
  =- [[file:claude-session/<filename>][<YYYY-MM-DD> — <Title>]] :: <hook>=
  The hook names the concrete searchable nouns in the doc — tools, filenames,
  concepts, the decisions made (e.g. "gptel Anthropic backend; org link
  durability; heading-vs-list") — not a restatement of the title. One line.
- Kevin's own hand-authored topic files (=<topic>.org=; e.g. =claude.org= is
  his Claude *agenda*) are his — never restructure them.

## Output shape (file · subtree · snippet)
Before generating org, establish where it lands. Three cases:
- *New file in the repo* — naming rules apply; add the =claude-snapshots.org=
  entry with its hook.
- *Content destined for one of Kevin's existing topic files* (=bankruptcy.org=,
  =claude.org=, …) — the common case when the topic already has a home. Emit a
  pasteable subtree, NOT a whole document: no =#+title=/=#+startup=, and
  headline depth chosen to nest under the target's existing structure (ask or
  infer the level). No snapshots entry — no file was created.
- *Snippet for the conversation* — no naming or indexing.
When unsure, ask which. Defaulting to a standalone file when the topic already
has a home creates an orphan Kevin has to merge by hand.

## Document skeleton (new-file case)
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
- Drawers are fine where they carry real state or data — =:PROPERTIES:= with
  =:ORDERED:= (enforce subtask order on a parent), =:LOGBOOK:= from
  =org-log-done= (completion timestamps), =:AUTHOR:= / =:SOURCE:= per entry in
  =quotes.org=.
- Still strip the *empty* =:PROPERTIES:= / =:ID:= / =:CUSTOM_ID:= drawers
  pandoc leaves behind in prose conversions — they carry nothing. (Kevin's
  files use =#+title= but no =:ID:= drawers even though org-id is active; match
  that — don't add IDs a file wouldn't otherwise have.)

## Agenda: TODO keywords & timestamps
Ratified 2026-08-30 — Kevin is learning org-agenda. Use these in *living* task
docs (his hand-authored =<topic>.org= agendas, project trackers), NOT in the
immutable =claude-session-*= snapshots: those stay prose with static
checkboxes, and the append-only rule means you never cycle a keyword or
retro-tick state in one.
- TODO keywords per file via =#+todo: TODO WAITING | DONE CANCELLED=. Left of
  =|= are active states, right are done states; cycle with =C-c C-t=.
- Reserve keywords for *sequenced or blocked* work — a =WAITING= headline is
  genuinely blocked, not merely un-started. Flat inventory/checklists stay as
  =- [ ]= checkboxes; keywords only earn their weight when a headline needs a
  state a checkbox can't express.
- TODO / =DEADLINE= / =SCHEDULED= attach to *headlines only*, never checkbox
  items — adopting them promotes a list into =***= subheadings (the real cost:
  more vertical). Promote only when agenda visibility is worth it.
- =DEADLINE:= = due-by (prefer it for constraints); =SCHEDULED:= = start-on.
  Goes on the line *immediately after* the headline (=C-c C-d= / =C-c C-s=).
  Active =<2026-09-15 Tue>= is agenda-visible; inactive =[2026-09-15 Tue]= is
  not. Warning lead-time: =<2026-11-01 Sat -21d>=.
- A file only reaches the agenda if it is in =org-agenda-files=.
- Tags and priorities remain unratified — propose before using.

## Content guidelines (for summaries/snapshots)
- Write for future-Kevin resuming months later; absolute dates, never
  "yesterday".
- Precision over prose: exact paths, versions, commands.
- Decisions carry the *why* and the rejected alternatives.
- Keep evidence that earned a conclusion; drop narration of dead ends.
