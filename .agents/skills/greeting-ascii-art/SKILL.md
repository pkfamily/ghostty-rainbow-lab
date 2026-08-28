---
name: greeting-ascii-art
description: Create, revise, and save monospaced ASCII art for terminal greetings, login banners, and welcome messages. Use for plain-text greeting artwork; do not use for bitmap illustrations or ANSI color effects alone.
---

# Greeting ASCII Art

Create attractive greeting art that remains legible when displayed as plain text
in a monospaced terminal.

## Design the greeting

- Honor requested words, motif, mood, alignment, and dimensions. If the user
  gives no size, aim for at most 72 columns and 8–16 lines so the greeting fits
  an ordinary terminal.
- Use printable 7-bit ASCII and newlines by default. Use Unicode only when the
  user requests it. Do not embed tabs, ANSI escape sequences, or color codes;
  keep coloring separate so renderers such as `lolcat` can apply it.
- Prefer a clear silhouette and readable lettering over dense texture. Check
  every requested word visually—stylized letters must not become ambiguous.
- Avoid trailing spaces as structural content. Keep blank lines only when they
  are intentional, and end saved text files with one newline.
- When a text banner would benefit from `figlet` and it is available, use it to
  explore compact fonts, then inspect and refine the result. Do not make the
  output depend on `figlet` at display time.

## Align multi-line artwork

- Choose the canvas width before laying out repeated or multi-line objects. In
  1-indexed columns, its center is `(width + 1) / 2`; a 94-column canvas is
  centered between columns 47 and 48.
- Give each object stable anchor columns, then derive every row of that object
  from those anchors. A tree tip and trunk, or a mountain peak and slopes, must
  stay on the same centerline. Do not independently center rows by their stored
  string lengths—leading indentation is part of the shape.
- Match glyph parity to the anchor. Odd-width motifs center on an integer
  column; even-width motifs center between columns. On an even-width canvas, a
  lone odd-width center glyph cannot sit on the half-column canvas center. Use
  a symmetric pair, an even number of repeated motifs, or an even-width apex
  instead of accepting a half-column drift.
- Generate repeated motifs from explicit centers and fixed spacing when
  practical. Verify that anchor characters occur at the intended columns on
  every row.
- For a centered layer, the first and last visible columns should sum to
  `width + 1`. This bounds check is necessary but not sufficient; also verify
  the internal anchors because a layer can be centered while its objects are
  individually misaligned.

## Deliver the result

- For a chat response, show the final art in a plain-text code fence so spacing
  is preserved. Include its width and height when a size constraint matters.
- For a file request, save only the art—without a Markdown fence, commentary,
  or terminal color escapes—and use a short lowercase filename.
- In the `ghostty-rainbow-lab` repository, save a new selectable profile as
  `zsh/greetings/<name>.txt`. Do not include the dynamic `welcome back` line;
  `zsh/zshrc-additions.zsh` appends that line at render time. Preserve existing
  profiles unless the user explicitly asks to replace one.
- When a revision should coexist with an existing profile, use a distinct,
  descriptive slug and keep the original bytes intact. Keep any README source
  sample synchronized with the profile it names. If installing profiles into
  the live configuration, copy both versions and select only the requested one.

## Verify

Before handing off a saved artifact:

1. Measure the longest line and confirm it fits the requested or inferred
   width.
2. Check for tabs, control characters, unexpected non-ASCII characters, and
   accidental trailing whitespace.
3. Inspect multi-line objects by anchor column, not only by whole-row center.
   When the user identifies a specific layer as wrong, preserve accepted layers
   and revise only that layer until its anchors and visible bounds pass.
4. Render the file in the intended monospaced font and inspect a screenshot.
   Character counts alone do not prove visual alignment. Re-render after every
   spacing change and compare the actual pixels before claiming it is fixed.
5. If color is requested, validate the plain art first. In this repository,
   use the runtime settings `lolcat -f -S 355 -F 0.2`; raw ANSI escapes do not
   render reliably in chat, so provide a terminal screenshot or raster preview
   when the user needs to see the colors.
