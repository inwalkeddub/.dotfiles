# sourced for every new shell, including non-interactive shells

export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:="$HOME/.config"}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:="$HOME/.cache"}
export XDG_DATA_HOME=${XDG_DATA_HOME:="$HOME/.local/share"}
export XDG_STATE_HOME=${XDG_STATE_HOME:="$HOME/.local/state"}

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export IPYTHONDIR="$XDG_CONFIG_HOME/ipython"
export JUPYTER_CONFIG_DIR="$XDG_CONFIG_HOME/jupyter"
export SCREENRC="$XDG_CONFIG_HOME"/screen/screenrc

export GITLIBS=$XDG_CACHE_HOME/clojure-gitlibs

export GRADLE_USER_HOME="$XDG_DATA_HOME"/gradle

export LESSHISTFILE="$XDG_STATE_HOME/less/history"

# -t: open a frame in the current terminal; -a '': start an Emacs daemon
# if no server is running, so this works even when Emacs isn't already up.
export EDITOR="emacsclient -t -a ''"
export VISUAL="$EDITOR"
