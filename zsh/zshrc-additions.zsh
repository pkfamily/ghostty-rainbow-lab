# Allow `#` comments at an interactive prompt. Off by default in zsh (unlike
# bash), so pasting any snippet with a trailing comment is a parse error that
# aborts the whole paste, not just the commented line. Frameworks like oh-my-zsh
# set this, which is why the gotcha is easy to miss.
setopt interactive_comments

# zoxide — smarter cd (use `z <partial-name>` to jump)
eval "$(zoxide init zsh)"

# Saved greeting profiles. Copy zsh/greetings/ to the configured directory;
# greeting-profile switches the saved choice for subsequent shells.
typeset -g GREETING_PROFILE_DIR="${GREETING_PROFILE_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/ghostty-rainbow-lab/greetings}"
typeset -g GREETING_PROFILE_FILE="${GREETING_PROFILE_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/ghostty-rainbow-lab/greeting-profile}"

_greeting_active_profile() {
  local profile=landscape
  [[ -r $GREETING_PROFILE_FILE ]] && IFS= read -r profile < "$GREETING_PROFILE_FILE"
  [[ -r "$GREETING_PROFILE_DIR/$profile.txt" ]] || profile=landscape
  print -r -- "$profile"
}

_greeting_render() {
  local profile=$(_greeting_active_profile)
  local profile_file="$GREETING_PROFILE_DIR/$profile.txt"

  [[ -r $profile_file && -x "$(command -v lolcat)" ]] || return

  {
    local line
    while IFS= read -r line || [[ -n $line ]]; do
      print -r -- "$line"
    done < "$profile_file"
    print -r -- "welcome back  ·  ${(%):-"%D{%A %d %B}"}"
  } | lolcat -f -S 355 -F 0.2
}

greeting-profile() {
  local profile current file
  current=$(_greeting_active_profile)

  case $# in
    0)
      print -r -- "active greeting: $current"
      print -r -- "available greetings:"
      for file in "$GREETING_PROFILE_DIR"/*.txt(N); do
        profile=${file:t:r}
        print -r -- "  $([[ $profile == $current ]] && print -n '●' || print -n ' ') $profile"
      done
      ;;
    1)
      profile=$1
      [[ -r "$GREETING_PROFILE_DIR/$profile.txt" ]] || {
        print -u2 -r -- "unknown greeting profile: $profile"
        return 1
      }
      mkdir -p -- "${GREETING_PROFILE_FILE:h}" || return 1
      print -r -- "$profile" >| "$GREETING_PROFILE_FILE" || {
        print -u2 -r -- "could not save greeting profile: $GREETING_PROFILE_FILE"
        return 1
      }
      print -r -- "greeting profile set to: $profile"
      ;;
    *)
      print -u2 -r -- "usage: greeting-profile [name]"
      return 2
      ;;
  esac
}

_greeting_render

# Colorized ls (BSD/macOS)
export CLICOLOR=1
export LSCOLORS="ExGxFxdaCxDaDahbadExEx"

# eza — modern ls replacement
if command -v eza >/dev/null 2>&1; then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza -lah --icons --git --group-directories-first"
  alias la="eza -a --icons --group-directories-first"
  alias lt="eza --tree --level=2 --icons --group-directories-first"
  alias lg="eza -lah --icons --git --sort=modified"
fi

# Tab title — replaces Ghostty's `title` shell-integration feature, which is
# switched off in ghostty/config. Same two behaviours it provided (cwd at the
# prompt, running command while one executes) plus a marker for Claude Code
# sessions, which inherit CLAUDECODE=1 into any interactive shell they spawn.
#
# This lives here rather than in a starship theme because it is orthogonal to
# theme choice: starship has no include mechanism, so a prompt-based marker
# would have to be duplicated and recoloured across all nine themes.
autoload -Uz add-zsh-hook

_tt_emit()   { print -rn -- $'\e]2;'"$1"$'\a' }
# `== 1`, not `-n`: an empty CLAUDECODE must not count as a Claude session.
_tt_mark()   { [[ ${CLAUDECODE-} == 1 ]] && print -rn -- '󰚩 ' }
_tt_precmd() { _tt_emit "$(_tt_mark)${(%):-%(4~|…/%3~|%~)}" }
_tt_preexec() { _tt_emit "$(_tt_mark)${1//[[:cntrl:]]}" }

add-zsh-hook precmd  _tt_precmd
add-zsh-hook preexec _tt_preexec

# starship prompt (must be last)
eval "$(starship init zsh)"

# prompt-theme switcher
[[ -f ~/.config/starship-themes/_switcher.zsh ]] && source ~/.config/starship-themes/_switcher.zsh
