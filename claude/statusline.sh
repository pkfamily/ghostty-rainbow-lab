#!/usr/bin/env bash
# Two-line Claude Code status line.
#
#   line 1  build-cli gateway budget  (delegated upstream, unchanged)
#   line 2  starship prompt rendered with the Ghostty Rainbow palette
#
# Claude Code sends session JSON on stdin and prints whatever we write to
# stdout; each echo becomes its own row. Install: see README.
set -uo pipefail

input=$(cat)

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# --- line 1: build-cli budget -------------------------------------------------
# build-cli's own statusline script ignores stdin (`exec ... < /dev/null`), so
# there is nothing to forward. Call the binary directly rather than its
# generated wrapper, which is rewritten on every `build-cli claude setup`.
BUILD_CLI="${BUILD_CLI_BIN:-$HOME/.local/bin/build-cli}"
if [[ -x $BUILD_CLI ]]; then
  # Command substitution strips trailing newlines; echo adds exactly one back,
  # so line 2 can never get glued onto line 1.
  budget=$("$BUILD_CLI" claude statusline </dev/null 2>/dev/null)
  [[ -n $budget ]] && echo "$budget"
fi

# --- line 2: starship ---------------------------------------------------------
IFS=$'\t' read -r MODEL DIR PCT COST < <(
  jq -r '[
    .model.display_name // "claude",
    .workspace.current_dir // .cwd // ".",
    (.context_window.used_percentage // 0),
    (.cost.total_cost_usd // 0)
  ] | @tsv' <<<"$input"
)

PCT=${PCT%%.*}; PCT=${PCT:-0}
(( PCT < 0 )) && PCT=0
(( PCT > 100 )) && PCT=100

# 10-cell context gauge
filled=$(( PCT / 10 ))
bar=""
for ((i = 0; i < 10; i++)); do
  (( i < filled )) && bar+="█" || bar+="░"
done
gauge="${bar} ${PCT}%"

# starship has no conditionals, so severity is expressed as three mutually
# exclusive modules. It skips an env_var module only when the variable is
# UNSET -- an empty string still renders the format string and leaves a stray
# separator behind. Hence `unset`, not `export FOO=""`.
unset CC_CTX_OK CC_CTX_WARN CC_CTX_HIGH
if   (( PCT >= 80 )); then export CC_CTX_HIGH="$gauge"
elif (( PCT >= 60 )); then export CC_CTX_WARN="$gauge"
else                       export CC_CTX_OK="$gauge"
fi

export CC_MODEL="$MODEL"
export CC_COST="$(printf '$%.2f' "$COST")"

# starship's directory/git modules read the process cwd, not --path.
cd "$DIR" 2>/dev/null || cd / || exit 0

# `starship init zsh` exports STARSHIP_SHELL=zsh, which this script inherits.
# That makes starship wrap output in zsh prompt escapes (%{ %}) and double every
# literal %. Claude Code is not zsh, so those would print as raw garbage.
unset STARSHIP_SHELL

STARSHIP_CONFIG="${CC_STARSHIP_CONFIG:-$HERE/starship-claude.toml}" \
  starship prompt --terminal-width="${COLUMNS:-100}"
echo
