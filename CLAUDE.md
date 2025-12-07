# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

clearview.nvim is a Neovim plugin for readable, transparent terminal experiences. Two modules:

- **clearview** (`lua/clearview.lua`): Multi-line cursorline with fade effect, cursorcolumn, cursorword
- **zen** (`lua/zen.lua`): Padding split for constrained-width focused writing

Designed to pair with semi-transparent terminals like Kitty using `transparent_background_colors`.

## Architecture

### clearview module

Single-file at `lua/clearview.lua`. Exports `setup(options)` which merges user config with `DEFAULT_OPTIONS` and registers autocommands.

**Cursorline/Cursorcolumn (extmark-based)**:
- Uses `nvim_buf_set_extmark` with dedicated namespaces (`ns_line`, `ns_col`)
- Cursorline: highlights N lines centered on cursor
- `fade_lines` option uses `CursorLineFade1`, `CursorLineFade2`, etc. for gradient effect at edges
- `timeout = 0` means always visible; `timeout > 0` hides on cursor move, reappears after delay

**Cursorword (matchadd-based)**:
- Window-local state in `vim.w`
- Uses `matchadd()`/`matchdelete()` with `CursorWord` highlight group

### zen module

Single-file at `lua/zen.lua`. Exports `setup(opts)`, `open(opts)`, `close()`, `toggle(opts)`, `is_active()`.

Creates a right vsplit with an empty scratch buffer to constrain content width. Registers `:Zen`, `:ZenOpen`, `:ZenClose` commands.

## Testing

No test framework. Manual testing:
```vim
:lua require('clearview').setup{}
:lua require('zen').setup{ width = 80 }
:Zen
```
