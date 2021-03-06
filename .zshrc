# This file is sourced by non-interactive and interactive zsh login shells.
# In an interactive shell, this is sourced before .zlogin.

###################
# CONFIGURE THESE #
###################
export NORMAL_USER=michael
export ZSH_CACHE_DIR="$(readlink -f ~/.zsh)"

# Init plugins.
source ~/.zsh/init.zsh

if echo "$-" | grep "l" > /dev/null; then
else
    function precmd() {
        print -Pn "\e]2;$USER@%~\a"
        print -Pn "\033]0;$USER@%~\007"
    }

    function preexec() {
        print -Pn "\e]2;$1\a"
        print -Pn "\033]0;$1\007"
    }
fi

################
# Autocomplete #
################

# Autocomplete.
autoload -U compinit promptinit
compinit

# Use an autocomplete cache to speed things up.
zstyle ':completion::completion:*' use-cache 1
zstyle ':completion::complete:*' use-cache 1

# Do completions of thins like partial paths.
setopt completeinword

# Autocomplete entry for killall.
zstyle ':completion:*:killall:*' command 'ps -u $USER -o cmd'

##########
# Colors #
##########

# Load colors.
autoload colors && colors

# Load colors into environment variables.
for COLOR in RED GREEN YELLOW BLUE MAGENTA CYAN BLACK WHITE; do
    eval $COLOR='%{$fg_no_bold[${(L)COLOR}]%}'
    eval BOLD_$COLOR='%{$fg_bold[${(L)COLOR}]%}'
done

# $RESET is used to reset colors to their normal value.
eval RESET='$reset_color'

# Ls colors.

eval `dircolors`
alias ls="ls -F --color=auto"

############
# Globbing #
############

# Use extended (better) globbing.
setopt extendedglob

# Ignore case while globbing.
unsetopt caseglob

#######
# Git #
#######

# Git the branch of a path.
function git_branch() {
    git branch 1>/dev/null 2>&1
}

# Get the branch name of a path.
git_branch_name() {
    TARGET="$PWD"
    if git_branch "$TARGET"
    then
        echo "`git rev-parse --abbrev-ref HEAD 2>/dev/null`"
    else
        echo ""
    fi
}

############
# History #
###########

# Save timestamps and runtimes to the history file.
setopt extendedhistory

# All shells immediatly see new history from other shells.
setopt sharehistory

###############
# Compilation #
###############

autoload -U zrecompile

#################
# Word matching #
#################

# We use this to tell zsh what qualifies as a word.
autoload select-word-style

# Shell mode for word detection.
select-word-style shell

#######
# VIM #
#######

# Vim mode.
bindkey -v

##############
# Statistics #
##############

# Auto report program time statistics for programs that take longer than 10 seconds to run.
REPORTTIME=10

##############
# Git Prompt #
##############
GIT_PROMPT_EXECUTABLE="haskell"
source /home/michael/.bin/zsh-git-prompt/zshrc.sh

# Configure Git Zsh Prompt
ZSH_THEME_GIT_PROMPT_PREFIX=""
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_PROMPT_SEPARATOR="|"
ZSH_THEME_GIT_PROMPT_BRANCH="%{$fg_bold[magenta]%}"
ZSH_THEME_GIT_PROMPT_STAGED="%{$fg[red]%}%{•%G%}"
ZSH_THEME_GIT_PROMPT_CONFLICTS="%{$fg[red]%}%{✖%G%}"
ZSH_THEME_GIT_PROMPT_CHANGED="%{$fg[blue]%}%{+%G%}"
ZSH_THEME_GIT_PROMPT_BEHIND="%{↓%G%}"
ZSH_THEME_GIT_PROMPT_AHEAD="%{↑%G%}"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{…%G%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}%{✔%G%}"
GIT_PROMPT='%b%f$(git_super_status)'

##########
# Prompt #
##########

# Setup prompt.
autoload -U promptinit
promptinit

# Extended PS1 and RPS1 substitution.
setopt promptsubst

# Prompt open and close brace.
export PS_OPEN='%b%f%k%B%F{red}['
export PS_CLOSE='%F{red}]%b%f%k'

# The string we want printed for normal mode.
export PS_VI_NORMAL="$PS_OPEN%B%F{yellow}NORMAL$PS_CLOSE"
# The string we want printed for insert mode.
export PS_VI_INSERT=""

# these don't really change between zsh sessions
# show username if its not the default
SHOW_USER=
if [[ $(whoami) != $NORMAL_USER ]]; then
    SHOW_USER=true
fi

# Renders the prompt, gets called whenever the keymap changes (i.e. change from
# insert to normal mode, or vice versa), or when the prompt is asked to be
# re-rendered.
function prompt-init {

    # Immediatly grab the return status of the last program the user ran, so
    # that we don't clober it later.
    local ret_status="$?"

    # Holds the tokens to eventually render.
    local tokens

    # show username if its not the default
    if [[ $SHOW_USER ]]; then
        tokens+=(green:'%n')
    fi

    # show hostname if its not the default
    if [ -n "$SSH_CLIENT" -o -n "$SSH_TTY" ]; then
        tokens+=(yellow:'%m')
    fi

    # Always render top-level directory.
    tokens+=(cyan:'%1~')

    # If a program returned an error code, inform the user
    if [[ "$ret_status" -ne "0" ]]; then
        tokens+=(yellow:"✖ $ret_status")
    fi

    # If we are in a git repo, have git branch token.
    if git_branch "$PWD"; then
        tokens+=(white:"${GIT_PROMPT}%B%F")
    fi

    # Reset prompt string.
    PS1=""

    # The length of the tokens rendered so far.
    local running_length=0

    # Never render more than 2/3 screen width.
    local top_length=$(( $COLUMNS * 200 / 3 / 100 ))

    # For every token, render the token.
    for i in $tokens; do

        # Extract the color of the token.
        local token_color=$(echo $i | cut -f1 -d:)

        # Extract the content of the token.
        local content=$(echo $i | cut -f2- -d:)

        # Strips color codes from the token content.
        local zero='%([BSUbfksu]|([FB]|){*})'

        # Construct the new token.
        local new_token="$PS_OPEN%B%F{$token_color}$content$PS_CLOSE "

        # Count the width of the new token, ignoring non-rendered characters.
        local length=${#${(S%%)new_token//$~zero/}}

        # If the top-length has not been overrun, render the new token.
        if [[ $(( $running_length + $length )) -lt $top_length ]]; then
            PS1="$PS1$new_token"
            running_length=$(( $running_length + $length ))
        fi
    done

    # Export the new prompts.
    export PS_PROMPT='%B%F{red}$%b%f%k'
    export PS1="$PS1${PS_PROMPT} "
    export RPS1="${${KEYMAP/vicmd/$PS_VI_NORMAL}/(main|viins)/$PS_VI_INSERT}"

    # Re-render the new prompt.
    if zle; then
        zle reset-prompt
    fi
}

function zle-line-init {
    prompt-init
}

function zle-keymap-select {
    prompt-init
}

zstyle ':completion:*' completer _oldlist _complete

zle -N zle-line-init
zle -N zle-keymap-select
prompt-init

# If the window resizes, re-render the prompt.
function TRAPWINCH() {
    zle-line-init
}

#########
# Alias #
#########
alias ls='ls -F --color=auto --group-directories-first'
alias open='xdg-open'
alias please='sudo $(fc -ln -1)'
alias http='python3 -m http.server'
alias cde='cd /home/michael/cde'
alias again='until $(fc -ln -1); do :; done'
alias clbin="curl -F 'clbin=<-' https://clbin.com"
alias sudo='sudo -E ' # keep environment & check for alias
alias vi=nvim

#############
# Functions #
#############
function targz() {
    tar -zcvf "${1}.tar.gz" "${1}"
}

function watch() {
    while :; do
        inotifywait -e close_write "$1"
        RUN=$(echo $@ | cut -d " " -f2-)
        echo "Running $RUN..."
        eval "$RUN"
    done
}

function latex_watch() {
    FILE="$1"
    watch "$FILE" pdflatex -halt-on-error "$FILE"
}

#############
# Variables #
#############
export EDITOR=nvim

#############
# RAM Setup #
#############
mkdir -p ~/RAM/.desktop
mkdir -p ~/RAM/.downloads

###############
# Autosuggest #
###############
# use the defaults
