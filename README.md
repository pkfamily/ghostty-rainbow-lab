# ghostty-rainbow-lab

Notes and configs from an afternoon of making a fresh [Ghostty](https://ghostty.org)
install colorful on macOS. Everything here is working config, not aspirational.

Ghostty 1.3.1 · macOS 25.5 (Darwin) · zsh

---

## What's here

```
ghostty/config          main Ghostty config
ghostty/themes/Rainbow  custom 16-slot ANSI palette
scripts/                palette + lolcat test harnesses (no API calls)
starship/               9 prompt themes, incl. a hand-tuned "custom"
zsh/_switcher.zsh       `prompt-theme` command
zsh/zshrc-additions.zsh everything appended to ~/.zshrc
```

## Install

```zsh
brew install zoxide lolcat eza starship
brew install --cask font-jetbrains-mono-nerd-font

cp -r ghostty/* ~/.config/ghostty/
mkdir -p ~/.config/starship-themes && cp starship/*.toml ~/.config/starship-themes/
cp zsh/_switcher.zsh ~/.config/starship-themes/
cat zsh/zshrc-additions.zsh >> ~/.zshrc
```

Reload Ghostty with `cmd+shift+,`.

---

## The three color systems (this was the main confusion)

Terminal color is not one thing. These are independent and don't interact.

| | Mechanism | Set by | Looks like |
|---|---|---|---|
| **ANSI palette** | index `30–37` / `90–97` | `ghostty/themes/Rainbow` | one solid color per element |
| **Truecolor** | `38;2;R;G;B` | the emitting program | arbitrary RGB, gradients |
| **256-color** | index `16–255` | `palette = N=...` | xterm cube + grayscale ramp |

Programs never choose colors — they emit a **number**, and the terminal decides
what it looks like. Traced from real output:

| Program | Emits | Palette slot |
|---|---|---|
| `grep` match | `1;31` | 1 (red) |
| `git diff` removed | `31` | 1 (red) |
| `git diff` added | `32` | 2 (green) |
| `git diff` hunk header | `36` | 6 (cyan) |
| `eza` executable | `1;32` | 2 (green) |
| `eza` directory | `1;34` | 4 (blue) |

So editing `palette = 2` changes git-added lines *and* eza executables *and*
every "success" message, simultaneously. One slot, many meanings — which is why
theme design is constrained.

**To find which slot to edit:**
```zsh
<command> --color=always | cat -v | head -3   # read the ^[[NNm codes, subtract 30
```

### The rainbow greeting is NOT the palette

The startup greeting uses lolcat's truecolor (`38;2;R;G;B`) and bypasses the
palette entirely. Deleting the `Rainbow` theme wouldn't change it. Same for the
starship prompt. The palette only affects programs that emit *indexed* color.

You never see the palette as a rainbow — only one slot at a time.

---

## Gotchas that cost real time

### `lolcat -F` depends on text length

`-F` is hue rotation **per character**, so the right value is a function of how
long the text is. There is no single good value.

| `-F` | 43-char line | paragraph |
|---|---|---|
| 0.02 | one solid color | one full rainbow ✓ |
| 0.05 | one solid color | broad bands |
| 0.3 | one full rainbow ✓ | tight noisy bands |

Setting `-F 0.05` on a short greeting produced **solid green** — technically a
gradient from `rgb(65,254,63)` to `rgb(147,227,9)`, visually one color.

### Ghostty falls back on unknown fonts silently

Config said `JetBrainsMono Nerd Font`; the registered family is
`JetBrainsMono Nerd Font Mono`. No error, just a silent fallback. Always verify:

```zsh
ghostty +list-fonts | grep -i <name>   # unindented lines = family names
```

Same class of problem with themes — they're case- and space-sensitive
(`Catppuccin Mocha`, not `catppuccin-mocha`).

### `claude -p` costs ~$0.24 per call

Every print-mode call reloads the full plugin/skill/MCP context (~35k cache
tokens) before answering. A test loop that calls it once per color variation
costs several dollars for zero extra information.

`scripts/claude-rainbow-test.sh` makes **zero API calls** — it uses canned text
shaped like a Claude response instead.

### BSD `ls` strips color when piped

`CLICOLOR=1` only applies to a TTY. Use `CLICOLOR_FORCE=1` to verify config
through a pipe. Also: the common `LSCOLORS` string floating around the internet
maps world-writable directories to a **green background**, which looks alarming
in a folder full of cloned repos. Slots 10 and 11 here are set to match normal
directories instead.

---

## Rainbow that doesn't break workflows

The rule: **decorate, never overwrite semantics.** Color that carries meaning
(diffs, file types, syntax) must stay untouched.

Safe:
- gradient prompt (starship — truecolor, independent of palette)
- rainbow greeting at shell start
- `figlet | lolcat` banners, `cal | lolcat`
- Ghostty `background-image` gradient

Not safe:
- `alias git='git | lolcat'` — destroys diff red/green
- piping interactive `claude` — wrecks TUI redraw
- `lolcat` as `$PAGER` — breaks `less` search highlighting
- `lolcat -a` in a prompt — ~1s added to every command

---

## Commands added

| Command | Does |
|---|---|
| `z <frag>` | jump to a visited directory by fragment (zoxide) |
| `zi <frag>` | interactive picker |
| `ls` `ll` `la` `lt` `lg` | eza with icons, git status, tree |
| `prompt-theme` | list prompt themes (● = active) |
| `prompt-theme <name>` | switch (tab-completes) |
| `prompt-theme -` | revert to previous |
| `scripts/palette-test.sh` | render all 16 slots with indices |
| `scripts/rainbow-test.sh` | lolcat `-F` / `-S` / `-p` sweeps |

## Ghostty options worth knowing

```
palette-generate = true     # derive all 256 colors from your base 16 (1.3+)
palette-harmonious = true   # reverse generated order for light/dark parity
minimum-contrast = 1.1      # auto-bump unreadable fg/bg pairs
theme = light:X,dark:Y      # auto-switch with macOS appearance
```

`palette-generate` is off by default because legacy TUIs hardcode xterm's
256-color assumptions. Not enabled here — worth trying, easy to revert.

## Per-window profiles

Ghostty has no profile switcher. On macOS the CLI can't launch the terminal
directly — use `open`:

```zsh
open -na Ghostty.app --args --theme=Rainbow --font-size=16
open -na Ghostty.app --args --config-file=$HOME/.config/ghostty/work.conf
```

Custom themes go in `~/.config/ghostty/themes/<Name>` and show up in
`ghostty +list-themes` tagged `(user)`.
