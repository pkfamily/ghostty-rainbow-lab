#!/usr/bin/env bash
# Compact Cursor CLI status line.
#
# Cursor invokes this command with session metadata on stdin. Keep the output to
# one short line: unlike Claude Code, Cursor replaces its native footer when a
# custom statusLine is configured.
set -uo pipefail

input=$(cat)

MODEL=$(jq -r '
  .model.display_name // .model.displayName // .model // "cursor"
' <<<"$input" 2>/dev/null || printf '%s' "cursor")
DIR=$(jq -r '
  .workspace.current_dir // .workspace.currentDir // .cwd // ""
' <<<"$input" 2>/dev/null || true)
BRANCH=$(jq -r '
  .git.branch // .git_branch // .branch // ""
' <<<"$input" 2>/dev/null || true)

# Prefer the basename to avoid duplicating Cursor's already-visible path.
PROJECT="${DIR##*/}"
[[ -z $PROJECT || $PROJECT == "/" ]] && PROJECT="workspace"

# Cursor has changed field names while the custom status line has been in beta;
# support the common context/usage shapes without making absent data noisy.
PCT=$(jq -r '
  .context_window.used_percentage //
  .contextWindow.usedPercentage //
  .usage.contextPercentage // ""
' <<<"$input" 2>/dev/null || true)
if [[ $PCT =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  PCT=${PCT%%.*}
  (( PCT > 100 )) && PCT=100
  CONTEXT=" ${PCT}%"
else
  CONTEXT=""
fi

# Cursor renders the custom line directly on the terminal background. Do not
# use the dark powerline foreground here without its matching background.
# Rainbow segments: purple model, cyan project, green branch, yellow context,
# bright blue separators throughout for contrast on the dark canvas.
printf '\033[38;2;199;125;255m %s \033[38;2;79;168;255m›\033[38;2;79;214;214m %s' "$MODEL" "$PROJECT"
[[ -n $BRANCH ]] && printf ' \033[38;2;79;168;255m›\033[38;2;93;219;127m %s' "$BRANCH"
[[ -n $CONTEXT ]] && printf ' \033[38;2;79;168;255m›\033[38;2;255;200;87m%s' "$CONTEXT"
printf '\033[0m '
