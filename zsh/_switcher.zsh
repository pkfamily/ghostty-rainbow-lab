# prompt-theme — switch starship prompt themes by name
# usage: prompt-theme            list available (● = active)
#        prompt-theme tokyo-night   apply one
#        prompt-theme -            revert to previous
_PT_DIR="$HOME/.config/starship-themes"
_PT_ACTIVE="$HOME/.config/starship.toml"
_PT_PREV="$HOME/.config/.starship-prev.toml"

prompt-theme() {
  local name="$1"
  if [[ -z $name ]]; then
    print "\033[1mavailable prompt themes\033[0m  ($_PT_DIR)"
    local f b cur
    cur=$(shasum "$_PT_ACTIVE" 2>/dev/null | cut -d' ' -f1)
    for f in "$_PT_DIR"/*.toml; do
      b=${${f:t}%.toml}
      if [[ $(shasum "$f" | cut -d' ' -f1) == "$cur" ]]; then
        print "  \033[1;32m●\033[0m $b"
      else
        print "    $b"
      fi
    done
    print "\n  prompt-theme <name>   apply"
    print "  prompt-theme -        revert to previous"
    return 0
  fi

  if [[ $name == "-" ]]; then
    [[ -f $_PT_PREV ]] || { print "no previous theme saved" >&2; return 1; }
    cp "$_PT_ACTIVE" "$_PT_ACTIVE.tmp" && cp "$_PT_PREV" "$_PT_ACTIVE" && mv "$_PT_ACTIVE.tmp" "$_PT_PREV"
    print "reverted"
    return 0
  fi

  local target="$_PT_DIR/$name.toml"
  if [[ ! -f $target ]]; then
    print "no such theme: $name" >&2
    print "try: prompt-theme   (to list)" >&2
    return 1
  fi
  cp "$_PT_ACTIVE" "$_PT_PREV" 2>/dev/null
  cp "$target" "$_PT_ACTIVE"
  print "→ $name"
}

# tab-completion
_prompt_theme() {
  local -a themes
  themes=(${${(f)"$(ls $_PT_DIR/*.toml 2>/dev/null)"}:t:r})
  _describe 'theme' themes
}
compdef _prompt_theme prompt-theme 2>/dev/null
