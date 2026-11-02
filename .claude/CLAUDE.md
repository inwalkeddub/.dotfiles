# Working with prior context

Before starting substantive work on a topic that may have prior history, check
`/Volumes/dev/org/claude-snapshots.org` — a dated index of past Claude session
snapshots, each entry carrying a one-line hook. If a hook looks relevant to the
task, **read that snapshot file before proceeding**: it holds prior decisions,
the reasoning behind them, and pending items. Prefer reading it over
re-deriving from scratch. The index is cheap to scan; pull a full snapshot only
when a hook matches. (This is the read side of the org-snapshot workflow whose
write side lives in the `snap` / `org-style` skills.)

# Pasted images of code or text

When I paste an image or screenshot that contains code or text, start your
reply by transcribing what you read from it, then answer. Pasted images don't
show up in the session history, so the transcription is how I can see the
context of your reply again later.

- **Code:** a fenced code block with the right language tag, copied exactly as
  shown. Mark anything you can't read with a comment rather than guessing.
- **Prose** (book pages, articles, docs): a `>` blockquote of the full text,
  verbatim, including typos or rendering glitches (point those out after the
  quote rather than silently fixing them). Add the source and page if known.
  For long images, quote everything relevant to my question and note what was
  skipped.
- **Formulas:** write them as plain text or code (e.g. `p_i = e^x_i / Σ_j
  e^x_j`).
- Mark unreadable parts with `[illegible]`.

# Dotfiles live under XDG, not bare in $HOME

I follow the XDG Base Directory layout, so **don't look for `~/.foo` dotfiles in
my home directory** — check the XDG locations instead, honoring the
`$XDG_*` env vars when set:

- **Config** → `~/.config/` (`$XDG_CONFIG_HOME`) — e.g. `~/.config/tmux/tmux.conf`,
  `~/.config/emacs/`, zsh config.
- **State** (history, logs) → `~/.local/state/` (`$XDG_STATE_HOME`) — e.g. zsh
  history at `~/.local/state/zsh/history`, `less` at `~/.local/state/less/history`.
- **Data** → `~/.local/share/` (`$XDG_DATA_HOME`).

My dotfiles are a bare git repo tracking these XDG paths (see the Dotfiles
Migration reference doc). When a tool's config or state file isn't where you
expect, assume it was moved to its XDG home before concluding it doesn't exist.
