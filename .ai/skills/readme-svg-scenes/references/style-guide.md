# Terminal SVG style guide

This guide captures the design language used for the SVG assets in this repository.

## Why these SVGs look good on GitHub

- They are pure SVG, so they stay sharp on retina and low-DPI screens
- They avoid heavy effects and browser-fragile features
- They read like product screenshots, but remain easy to edit in a text editor

## Palette

Use a dark base plus a compact accent range:

- background shell: `#0b1120`, `#0f172a`, `#111827`, `#020617`
- borders: `#1e293b`
- main text: `#e2e8f0`, `#cbd5e1`
- secondary text: `#94a3b8`
- green accent: `#22c55e`
- cyan accent: `#38bdf8`
- purple accent: `#a78bfa`
- warm traffic lights: `#ef4444`, `#f59e0b`, `#22c55e`

Avoid using red/yellow/green as the only meaning-bearing channel unless they truly represent status.

## Spacing

- Outer margin: `24-32`
- Panel radius: `12-18`
- Vertical rhythm between text rows: `28-44`
- Keep side gutters wide enough for GitHub's centered README layout

## Typography

- Use the same monospace stack throughout
- Typical sizes:
  - small helper text: `18-20`
  - body lines: `20-22`
  - panel headings: `24`
  - hero headline: `42-50`

## Scene design

- Favor one strong idea per image
- Show believable product content instead of decorative lorem ipsum
- If the tool is interactive, communicate focus, selection, and details panel state
- Keep important labels left-aligned unless centering adds clear value

## Accessibility

Every SVG should include:

- `<title>`
- `<desc>`
- enough contrast between text and background

## Editing guidance

- Align coordinates on a simple grid when possible
- Prefer adding more whitespace over squeezing more labels
- If a line becomes too long, shorten copy first and resize last
