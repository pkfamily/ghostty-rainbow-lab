# zoxide — smarter cd (use `z <partial-name>` to jump)
eval "$(zoxide init zsh)"

# Rainbow greeting on new shells
if command -v lolcat >/dev/null 2>&1; then
  echo "welcome back, poonv  ·  $(date +%A\ %d\ %B)" | lolcat -f -S 240 -F 0.3
fi

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
