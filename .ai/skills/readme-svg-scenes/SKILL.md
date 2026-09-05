---
name: readme-svg-scenes
description: Create polished README SVG hero and demo visuals with a terminal-style aesthetic. Use this when asked to design repo banners, CLI screenshots, or reusable SVG visuals similar to reclaimit's assets.
license: MIT
---

# README SVG scenes

Use this skill to create **clean, portable SVG visuals** for repository documentation without needing design tools or raster assets.

Ask for these inputs if they are not already clear:

1. Repository or product name
2. Short tagline
3. One or two representative commands or outputs
4. Whether the user wants a **hero banner**, a **demo scene**, or **both**
5. Preferred accent colors, if any

## Design goals

- Produce **plain SVG files** that render well on GitHub and can live in `assets/`
- Keep the style close to a polished terminal or TUI screenshot
- Prefer **dark backgrounds**, rounded panels, monospace text, and a small accent palette
- Make the image self-explanatory even when the repository name is unfamiliar
- Keep the composition readable at GitHub README width

## Required visual language

- Use a rounded outer canvas with a dark background
- Add one or more inner panels to mimic a terminal or split UI
- Use only a few primitives: `rect`, `circle`, `text`, and optional `defs` for gradients
- Use a monospace font stack such as `ui-monospace, SFMono-Regular, Menlo, Consolas, monospace`
- Include accessibility metadata: `role="img"`, `title`, and `desc`
- Prefer restrained colors:
  - background: slate / navy tones
  - neutral text: light gray / blue-gray
  - accents: green, cyan, purple
- Use icons or emoji sparingly and only when they improve scanability

## Composition rules

### Hero banner

- Target roughly `1280x360`
- Show:
  - product name
  - tagline
  - one representative command
  - one short “result” line
  - one benefits line
- Add subtle window chrome with three circles in the top-left
- Keep line count low and whitespace generous

### Demo scene

- Target roughly `1280x720`
- Mimic a real product moment, not generic decoration
- Use at least two panels when the tool has a tree + details layout
- Make states visually clear:
  - focused row
  - selected row
  - categories or statuses
- Ensure labels are legible and not overcrowded

## Content rules

- Never invent features that the repository does not have
- Prefer realistic commands, paths, filenames, and outputs
- Escape text that could break XML
- Keep individual text lines short enough to avoid overflow
- If a path is too long, shorten it intentionally instead of letting it collide visually

## Working process

1. Inspect the repository README, CLI help, screenshots, or TUI structure
2. Pick the smallest scene that communicates the product clearly
3. Start from one of the bundled templates in `templates/`
4. Replace placeholders with repo-specific content
5. Save the final file under `assets/`
6. Reference it from the README with a normal Markdown image

## File layout

- Use `templates/terminal-hero.svg` as the base for banners
- Use `templates/terminal-demo.svg` as the base for split-pane demos
- Use `references/style-guide.md` for spacing, palette, and copy guidance

## Output expectations

When applying this skill:

- create or update the SVG asset files directly
- keep them human-editable
- avoid embedded base64 images
- avoid unnecessary filters or effects
- keep the markup tidy so future edits are easy

## Examples from this repository

- `assets/reclaimit-hero.svg`
- `assets/reclaimit-demo.svg`

Use them as the style reference for future repos unless the user asks for a different visual direction.
