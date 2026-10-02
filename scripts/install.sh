#!/usr/bin/env bash
set -euo pipefail

if [[ "${OSTYPE:-}" != darwin* ]]; then
  printf 'This installer currently supports macOS only.\n' >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  printf 'Homebrew is required: https://brew.sh\n' >&2
  exit 1
fi

brew install zoxide lolcat eza starship
brew install figlet
brew install --cask font-jetbrains-mono-nerd-font

if ! command -v ghostty >/dev/null 2>&1; then
  printf 'The Nerd Font was installed, but Ghostty is not available to verify it.\n' >&2
  printf 'Install Ghostty, then run: ghostty +list-fonts | grep -F "JetBrainsMono Nerd Font Mono"\n' >&2
  exit 1
fi

if ! ghostty +list-fonts 2>/dev/null | grep -Fq 'JetBrainsMono Nerd Font Mono'; then
  printf 'JetBrainsMono Nerd Font Mono was not found by Ghostty.\n' >&2
  printf 'Restart Ghostty or macOS so the newly installed font is registered, then retry.\n' >&2
  exit 1
fi

printf 'Verified: JetBrainsMono Nerd Font Mono is available to Ghostty.\n'
