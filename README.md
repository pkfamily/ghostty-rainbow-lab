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
claude/                 starship-rendered Claude Code status line
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

## Claude Code status line, rendered by starship

Claude Code's `statusLine` runs any command, hands it session JSON on stdin, and
prints stdout in a row at the bottom of the UI. Point it at starship and the bar
matches the shell prompt — same separators, same `Rainbow` palette.

```
build-cli gateway | ████░░░░░░░░░░░░░░░░  $353.67 / $2,000.00 (17.7%) weekly
  Opus 5  ghostty-rainbow-lab   main ?  ██░░░░░░░░ 23%  $0.42
```

Line 1 is delegated to build-cli untouched; line 2 is starship. Each `echo` is a
row. Total runtime ~166 ms, of which ~127 ms is the build-cli call.

`$directory`, `$git_branch`, `$git_status` come free — the script `cd`s to
`workspace.current_dir` and starship's own modules do truncation, repo
detection, and dirty-state glyphs. Claude-only data (model, context, cost)
arrives as `env_var` modules, so it is styled in TOML like any other segment.

Truecolor, so it is independent of the palette — same category as the prompt.

```zsh
cp -r claude ~/.config/ghostty-rainbow-claude   # or run it from the repo
```

Then set `statusLine.command` in `~/.claude/settings.json` to that
`statusline.sh`, keeping `refreshInterval` so the budget line stays current
while the session is idle.

### Gotchas

**`starship init zsh` exports `STARSHIP_SHELL=zsh`, and the script inherits it.**
starship then wraps output in zsh's non-printing markers and doubles every
literal `%`. Claude Code is not zsh, so it prints raw:

```
%{[38;2;199;125;255m%}  Opus 5 ... ██░░░░░░░░ 23%%
```

`unset STARSHIP_SHELL` before `starship prompt` fixes both symptoms.

**starship skips an `env_var` module only when the variable is *unset*.**
`export CC_CTX_WARN=""` still renders the format string. The context gauge uses
three mutually exclusive vars for its green/yellow/red bands (starship has no
conditionals), so the two inactive ones must be `unset`, not set to empty —
otherwise they emit stray colored spaces after the bar.

**`git_status` renders its format inside a repo even with no glyphs to show.**
A bare trailing space to clear the powerline separator therefore leaks a stray
space on every clean tree. Use a group — `[($all_status$ahead_behind )]` —
which starship drops entirely when all variables inside are empty.

**build-cli owns its statusline script.** `~/.config/build-cli/statusline.sh` is
marked auto-generated and is overwritten by `build-cli claude setup`, which also
repoints `statusLine.command`. `build-cli config set statusline_disabled true`
is the documented escape hatch; without it, the next setup run silently reclaims
the bar. The wrapper calls the `build-cli` binary directly rather than that
generated script, and drops the line cleanly if the binary is missing.

Two things that are easy to assume wrong about that flag, both measured:

- It does **not** silence `build-cli claude statusline`. With the flag on, the
  command still exits 0 and prints its 76 bytes, so line 1 survives. The flag
  gates only what `setup` *writes*, not what the binary *prints*.
- It is not immediate — it reports `Run 'build-cli claude setup' to apply`. It
  is a standing guard against the next setup, not a change you can observe now.

Setting it touches `~/.config/build-cli/config.json` only. Verified by checksum
that `~/.claude/settings.json` and the generated script are both left alone, so
enabling it cannot clobber a `statusLine.command` you have already repointed.

## Marking agent-driven shells

Claude Code exports `CLAUDECODE=1`, `CLAUDE_CODE_ENTRYPOINT`, and
`CLAUDE_CODE_SESSION_ID`, and interactive shells it spawns inherit them. The
marker goes in the **tab title**, not the prompt:

```
󰚩 …/Repos/ghostty-rainbow-lab      agent-driven tab
…/Repos/ghostty-rainbow-lab        normal tab
󰚩 git rebase -i main               while a command runs
```

### Why the title and not the prompt

- **A tab is the thing being disambiguated.** With `macos-titlebar-style = tabs`
  the title is already in the tab bar. A prompt marker only exists at a prompt:
  it scrolls away, and it never appears during agent tool calls at all, because
  those run non-interactively with `PS1` unset.
- **starship has no include mechanism.** `starship config` edits single keys;
  there is no `include`/`extends`. A prompt marker is orthogonal to theme
  choice, so putting it in themes means duplicating and recolouring it across
  all nine, and remembering it for every new one.
- Costs nothing per prompt, and survives `prompt-theme` switching.

### Ghostty's title feature has to be turned off

The two cannot cooperate. Ghostty's integration registers
`_ghostty_deferred_init` as a precmd and only defines `_ghostty_precmd` when
that *first fires* — after `~/.zshrc` has finished. So at rc time there is no
function to append to, and the integration deliberately forces its own hook to
the end of `precmd_functions` (its comment: "We'll break them as much as they
are breaking us"). Hence `title` is dropped from `shell-integration-features`
and `zshrc-additions.zsh` reimplements both behaviours it provided — cwd at the
prompt, running command during execution — in six lines.

Note the runtime value is normalised and not what you wrote: a config of
`cursor,sudo,title` reports as `GHOSTTY_SHELL_FEATURES=cursor:steady,path,sudo,title`.

### Details worth keeping

The test is `[[ ${CLAUDECODE-} == 1 ]]`, not `-n`. An empty `CLAUDECODE` must not
count — the same set-but-empty trap that bites `env_var` modules elsewhere here.

Command titles run through `${1//[[:cntrl:]]}`, as Ghostty's own does. A command
containing `\e]2;HIJACK\a` loses its `ESC` and lands in the title as inert text;
verified the output carries exactly one `ESC`, the opener.

Related: interactive shells spawned by Claude Code run `~/.zshrc` in full, so the
lolcat greeting fires on each one.

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
