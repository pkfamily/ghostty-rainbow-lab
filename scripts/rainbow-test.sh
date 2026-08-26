#!/usr/bin/env zsh
# Rainbow output test harness
LINE="the quick brown fox jumps over the lazy dog and keeps on running forever"
SHORT="welcome back, poonv"

hdr() { print "\n\033[1m── $1 ──\033[0m"; }

hdr "frequency sweep (-F) on a LONG line (${#LINE} chars)"
for f in 0.02 0.05 0.1 0.2 0.3 0.6 1.0; do
  printf "%-5s " $f; echo "$LINE" | lolcat -f -F $f
done

hdr "frequency sweep (-F) on a SHORT line (${#SHORT} chars)"
for f in 0.05 0.15 0.3 0.6 1.0; do
  printf "%-5s " $f; echo "$SHORT" | lolcat -f -F $f
done

hdr "seed sweep (-S) at F=0.3"
for s in 0 60 120 180 240 300; do
  printf "%-5s " $s; echo "$SHORT" | lolcat -f -S $s -F 0.3
done

hdr "spread (-p) — chars per color step"
for p in 1 3 8 20; do
  printf "%-5s " $p; echo "$LINE" | lolcat -f -p $p
done

hdr "multiline block (gradient runs down, not just across)"
printf 'line one\nline two\nline three\nline four\n' | lolcat -f -F 0.1

hdr "preserves layout? (columns + box drawing)"
printf 'NAME    SIZE   TYPE\n────    ────   ────\nfoo.txt 1.2K   text\nbar.py  8.4K   code\n' | lolcat -f -F 0.05

hdr "unicode / emoji"
echo "✓ ✗ → ★ ♥ 🌈 🎨 ∆ π ∞ ── ╭─╮" | lolcat -f -F 0.2

hdr "vs. program's own colors (lolcat OVERRIDES them)"
print "with lolcat:"; ls -G ~ 2>/dev/null | head -3 | lolcat -f -F 0.1
print "without:";     ls -G ~ 2>/dev/null | head -3
print ""
