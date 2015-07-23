# vim:ft=zsh ts=2 sw=2 sts=2
#
# agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://github.com/Lokaltog/powerline-fonts).
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

# emulate -L zsh
# setopt typeset_silent

export CURRENT_BG='NONE'
SEGMENT_SEPARATOR=''
SEGMENT_SPACE=''

psvar[10]=1

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
+prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"

  if [[ $CURRENT_BG == 'NONE' && $1 != 'black' ]]; then
    echo -n "%{%(10V.$bg%F{black}.)%}%(10V.$SEGMENT_SEPARATOR.)%{%(10V.$fg.)%} "
  elif [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{%(10V.$bg%F{$CURRENT_BG}.)%}%(10V.$SEGMENT_SEPARATOR.>)%{%(10V.$fg.)%} "
  else
    [[ $1 != 'black' ]] && SEGMENT_SPACE=' '
    echo -n "%{%(10V.$bg$fg.)%}$SEGMENT_SPACE"
  fi
  export CURRENT_BG=$1
  SEGMENT_SPACE=' '
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
+prompt_end() {
  if [[ -n $CURRENT_BG && $CURRENT_BG != 'NONE' && $CURRENT_BG != 'black' ]]; then
    echo -n " %{%(10V.%k%F{$CURRENT_BG}.)%}%(10V.$SEGMENT_SEPARATOR.>)$SEGMENT_SPACE"
  else
    echo -n "%{%(10V.%k.)%}$SEGMENT_SPACE"
  fi
  echo -n "%{%(10V.%f.)%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

+box_name() {
    ( [ -f /etc/box-name ] && cat /etc/box-name ) || ( [ -f ~/.box-name ] && cat ~/.box-name ) || echo -n "%m"
}

# Context: user@hostname (who am I and where am I)
+prompt_context() {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    local name=$(+box_name)

    if [[ $name == '$'* ]]; then 
      +prompt_segment 88 white "%(10V:%(!.%{%F{208}%}.):)$USER%(10V.%F{white}.) @ %(10V.%F{208}.)$name"
    else
      +prompt_segment 25 white "%(10V:%(!.%{%F{208}%}.):)$USER%(10V.%F{white}.) @ %(10V.%F{yellow}.)$name"
    fi
  fi
}

# Git: branch/detached head, dirty status
+prompt_git() {
  local ref dirty mode repo_path
  repo_path=$(git rev-parse --git-dir 2>/dev/null)

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
    if [[ -n $dirty ]]; then
      +prompt_segment yellow black
    else
      +prompt_segment green black
    fi

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
      mode=" >R>"
    fi

    # setopt prompt_subst
    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' get-revision true
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr '✚'
    zstyle ':vcs_info:git:*' unstagedstr '●'
    zstyle ':vcs_info:*' formats ' %u%c'
    zstyle ':vcs_info:*' actionformats ' %u%c'
    vcs_info
    echo -n "${ref/refs\/heads\// }${vcs_info_msg_0_%% }${mode}"
  fi
}

+prompt_hg() {
  local rev status
  if $(hg id >/dev/null 2>&1); then
    if $(hg prompt >/dev/null 2>&1); then
      if [[ $(hg prompt "{status|unknown}") = "?" ]]; then
        # if files are not added
        +prompt_segment red white
        st='±'
      elif [[ -n $(hg prompt "{status|modified}") ]]; then
        # if any modification
        +prompt_segment yellow black
        st='±'
      else
        # if working copy is clean
        +prompt_segment green black
      fi
      echo -n $(hg prompt "☿ {rev}@{branch}") $st
    else
      st=""
      rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
      branch=$(hg id -b 2>/dev/null)
      if `hg st | grep -q "^\?"`; then
        +prompt_segment red black
        st='±'
      elif `hg st | grep -q "^(M|A)"`; then
        +prompt_segment yellow black
        st='±'
      else
        +prompt_segment green black
      fi
      echo -n "☿ $rev@$branch" $st
    fi
  fi
}

# Dir: current working directory
+prompt_dir() {
  +prompt_segment black cyan "%1v"
  # +prompt_segment black cyan "%~"
}

# Virtualenv: current working virtualenv
+prompt_virtualenv() {
  local virtualenv_path="${VIRTUAL_ENV/#$HOME/~}"
  if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
    +prompt_segment blue black "py $(basename $(dirname $virtualenv_path))/$(basename $virtualenv_path)"
  fi
}

# Golang
+prompt_go() {
  local golang_path="${GOPATH_PROMPT/#$HOME/~}"
  if [[ -n $golang_path ]]; then
    +prompt_segment yellow black "go $(basename $(dirname $golang_path))/$(basename $golang_path)"
  fi
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
+prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%(10V.%F{red}.)%}✘"
  [[ $UID -eq 0 ]] && symbols+="%{%(10V.%F{yellow}.)%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%(10V.%F{cyan}.)%}⚙"

  [[ -n "$symbols" ]] && +prompt_segment black default "$symbols"
}

if [[ $(whence -w iterm2_prompt_start | awk '{ print $2 }') != "function" ]]; then
  iterm2_prompt_start() {}
  iterm2_prompt_end() {}
fi

+prompt_first() {
  +prompt_context
  +prompt_dir
  +prompt_virtualenv
  +prompt_go
  +prompt_end
}

+prompt_second() {
  iterm2_prompt_start
  +prompt_status
  +prompt_git
  +prompt_hg
  +prompt_end
  iterm2_prompt_end
}

+prompt_precmd() {
  local RETVAL=$?

  local pwd="${PWD/#$HOME/~}"

  psvar[1]="$pwd"

  local PS0="$(+prompt_first)"

  psvar[10]=()
  local ln=${#${(%):-$PS0}}
  psvar[10]=1

  local trimsize=$(($ln - ${COLUMNS} + 5))

  if [[ $trimsize -gt 4 ]]; then
    psvar[1]="...$pwd[$trimsize,$ln]"
  fi

  print -rP "$PS0%E"
  PS1="$(+prompt_second)"
}

+prompt_preexec() {

}

[[ -z $precmd_functions ]] && precmd_functions=()
precmd_functions=($precmd_functions +prompt_precmd)

[[ -z $preexec_functions ]] && preexec_functions=()
preexec_functions=($preexec_functions iterm2_preexec)