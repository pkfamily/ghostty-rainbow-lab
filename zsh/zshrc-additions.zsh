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

# starship prompt (must be last)
eval "$(starship init zsh)"

# prompt-theme switcher
[[ -f ~/.config/starship-themes/_switcher.zsh ]] && source ~/.config/starship-themes/_switcher.zsh
