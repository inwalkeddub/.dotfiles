# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source ${ZDOTDIR}/antigen.zsh


antigen bundle zsh-users/zsh-syntax-highlighting

antigen theme romkatv/powerlevel10k

antigen apply

zmodload zsh/complist
bindkey -v
KEYTIMEOUT=1    # default is 0.4s pause
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history


autoload -U compinit; compinit

# https://thevaluable.dev/zsh-completion-guide-examples/
# ^x h for completion help
zstyle ':completion:*' completer _extensions _complete _approximate                 # ^x^a expands aliases
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/.zcompcache"
zstyle ':completion:*' menu select                                                  # search for fuzzy-search ; interactive to filter completion menu
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'              # color descriptions for the match types
zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f' # color corrections for completer _approximate
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*' group-name ''                                                # group different match types under their descriptions
zstyle ':completion:*:*:-command-:*:*' group-order alias builtins functions commands    # order of match type descriptions
zstyle ':completion:*' file-list all                                                # ls -l details
zstyle ':completion:*' file-sort modification                                       # sort by modification date

zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}                       # NOT WORKING; tried: gdircolors -p > ~/.dircolors ; eval "$(gdircolors -b .dircolors)"
                                                                                    # sets $LS_COLORS, used by gnu coreutils 'ls --color=auto'
# https://unix.stackexchange.com/questions/6620/how-to-edit-command-line-in-full-screen-editor-in-zsh
autoload -z edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line

# Bash-style kill/yank in vi insert mode (kill ring carries text across keystrokes)
# ^U cut-to-start, ^K cut-to-end, ^Y yank most recent, Alt-Y cycle older yanks
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^K' kill-line
bindkey -M viins '^Y' yank
bindkey -M viins '^[y' yank-pop

# install fzf zsh key bindings
if command -v fzf >/dev/null; then
  source <(fzf --zsh)
fi
# Use fd instead of the default find command for listing path candidates.
_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}
# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}
export FZF_DEFAULT_OPTS="--tmux right,70%,90%"
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix'
# --hidden to search dotfiles
# --follow symbolic links
# --exclude .git respects .gitignore
# export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

export BAT_THEME="ansi"
alias cat=bat
function xcat () { BAT_PAGER="less -RFKX" bat "$@" }  # -X prevents screen clear on exit, -F skips paging if output fits

export LEDGER_FILE=/Volumes/budpowell/accounting/2024.journal

HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=50000
SAVEHIST=10000
HIST_STAMPS="dd.mm.yyyy"

setopt hist_expire_dups_first # delete dups first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore consecutive duplicated commands history
setopt hist_ignore_all_dups   # removes dups of lines still in the history list, keeping newly added one
setopt hist_save_no_dups      # do not save duplicated lines to HISTFILE more than once
setopt hist_find_no_dups      # backward searches with editor commands dont show dups more than once
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion at prompt before running it
setopt extended_history       # record timestamp of command in HISTFILE
setopt append_history         # append the new history to the old in histfile
setopt inc_append_history_time # same but supports extended_history (set below)

setopt no_beep
setopt extended_glob        # enables ^ ~ negations et al chars for filename globbing
setopt correct              # asks to correct a mistyped command

function less () {      # https://zsh.sourceforge.io/Guide/zshguide05.html
    integer i=1
    local args arg
    args=($*)

    for arg in $*; do
        case $arg in
            (*.bz2)     args[$i]="=(bunzip2 -c ${(q)arg})"
                ;;
            (*.(gz|Z))  args[$i]="=(zcat ${(q)arg})"        # assumes zcat is the one installed with gzip
                ;;
            (*)         args[$i]=${(q)arg}
                ;;
        esac
        (( i++ ))
    done

    eval command ${PAGER:-less} $args
}

function fkill () {
    (date; ps -ef) |
      fzf --bind='ctrl-r:reload(date; ps -ef)' \
          --header=$'Press CTRL-R to reload\n\n' --header-lines=2 \
          --preview='echo {}' --preview-window=down,3,wrap \
          --layout=reverse --height=80% | awk '{print $2}' | xargs kill -9
}

fignore+=(.DS_Store)

alias his="history -20"
alias more="less -i"

alias rm="rm -i"
alias mv="mv -i"
alias cp="cp -i"
alias ls="gls --color=auto -F"   # gnu ls without pulling in all of gnubin
alias la="ls -a"
alias ll="ls -l"

alias cd..="cd ../.."
alias cd...="cd ../../.."
alias cd....="cd ../../../.."
cdpath=(/Volumes/dev $cdpath)
dev=/Volumes/dev
src=/Users/kevinrathbun/Documents/src
# create named directory from current directory
namedir () { $1=$PWD ;  : ~$1 }

setopt nocaseglob
DIRSTACKSIZE=8
setopt autopushd        # save all dir changes to stack
setopt pushdminus       # swap - and + directions in stack
setopt pushdsilent      # dont list stack on each pushd
setopt pushdignoredups  # no dups in stack
setopt autocd           # change to dir in cdpath with 'cd'
setopt cdablevars       # autocd to named directories without '~'
alias ds="dirs -v"
alias pd=pushd
alias pp=popd

alias diffy="diff -by --width=200"

alias gdot='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias gg="git grep"
alias ggi="git grep -i"

typeset -U path     # only unique entries in path

if [ "$JAVA_HOME" = "" ]; then
    JAVA_HOME=$(/usr/libexec/java_home 2&> /dev/null)
    export JAVA_HOME
fi

path=($HOME/.local/bin
      $HOME/bin
      $HOME/.emacs.d/bin
      $path)

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

[[ ! -f "$ZDOTDIR"/.p10k.zsh ]] || source "$ZDOTDIR"/.p10k.zsh
