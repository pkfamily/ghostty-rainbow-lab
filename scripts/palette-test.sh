#!/usr/bin/env zsh
# Preview the active Ghostty palette
print "\n\033[1m── ANSI palette ──\033[0m"
for i in {0..15}; do
  printf "\033[48;5;${i}m %3d \033[0m" $i
  (( (i+1) % 8 == 0 )) && echo
done

print "\n\033[1m── foreground text ──\033[0m"
names=(black red green yellow blue magenta cyan white)
for i in {0..7}; do
  printf "\033[38;5;${i}m%-9s\033[0m \033[1;38;5;${i}m%-9s\033[0m\n" "$names[i+1]" "bold"
done

print "\n\033[1m── real output ──\033[0m"
ls --color=always ~ 2>/dev/null | head -5 || ls -G ~ | head -5
git -C ~ diff --color=always 2>/dev/null | head -5

print "\n\033[1m── 256-color ramp ──\033[0m"
for i in {16..51}; do printf "\033[48;5;${i}m \033[0m"; done; echo
print ""
