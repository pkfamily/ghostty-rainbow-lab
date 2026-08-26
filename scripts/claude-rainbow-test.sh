#!/usr/bin/env zsh
# Rainbow tests for Claude-style output. ZERO API calls — uses a canned sample
# that mimics Claude's markdown (prose + code fence + list + inline code).
hdr() { print "\n\033[1m── $1 ──\033[0m"; }

SAMPLE=$(cat <<'EOF'
zoxide is a smarter `cd` written in Rust. It tracks every directory you
visit and ranks them by frequency and recency, so you can jump to a deeply
nested path by typing a fragment of its name instead of the whole thing.

Install and initialize:

```zsh
brew install zoxide
eval "$(zoxide init zsh)"
```

Key commands:
- `z foo`  — jump to the best match for "foo"
- `zi foo` — interactive picker when several match
- `z -`    — previous directory

The database lives in ~/.local/share/zoxide and improves as you use it.
EOF
)

hdr "raw (no lolcat) — baseline"
print -r -- "$SAMPLE"

for f in 0.02 0.05 0.1 0.3; do
  hdr "F=$f"
  print -r -- "$SAMPLE" | lolcat -f -F $f
done

hdr "spread -p 10 — color changes on word boundaries"
print -r -- "$SAMPLE" | lolcat -f -p 10

hdr "code fence only"
print -r -- "$SAMPLE" | sed -n '/```/,/```/p' | lolcat -f -F 0.05

hdr "does it wreck indentation / list alignment?"
print -r -- "$SAMPLE" | grep '^-' | lolcat -f -F 0.08
print ""
print "\033[2mno API calls made. To rainbow real output: claude -p \"...\" | lolcat -f -F 0.05\033[0m"
