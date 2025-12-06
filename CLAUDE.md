# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

nvim-cursorline is a Neovim plugin written in Lua that provides cursor-related visual features:
- **cursorline**: Highlights multiple lines centered on cursor (configurable width)
- **cursorcolumn**: Highlights multiple columns centered on cursor (configurable width, extends into virtual space)
- **cursorword**: Underlines the word under the cursor

## Architecture

Single-file plugin at `lua/nvim-cursorline.lua`. Exports `setup(options)` which merges user config with `DEFAULT_OPTIONS` and registers autocommands.

### Cursorline/Cursorcolumn (extmark-based)
- Uses `nvim_buf_set_extmark` with dedicated namespaces (`ns_line`, `ns_col`)
- Cursorline: highlights N lines with `hl_group = "CursorLine"`, `hl_eol = true`
- Cursorcolumn: three rendering paths based on line length vs highlight range:
  1. All columns have real chars → extmark with `hl_group`
  2. Partial overlap → extmarks for real chars + `virt_text` for virtual space
  3. Entirely virtual → `virt_text` positioned with `virt_text_win_col`
- `timeout = 0` means always visible; `timeout > 0` hides on cursor move, reappears after delay
- Separate `vim.loop.new_timer()` instances for line and column

### Cursorword (matchadd-based)
- Window-local state in `vim.w` (cursorword, cursorword_id)
- Uses `matchadd()`/`matchdelete()` with `CursorWord` highlight group
- Pattern matching via Vim regex (`\k*` for keyword chars)

## Testing

No test framework. Manual testing:
```vim
:lua require('nvim-cursorline').setup{}
```
