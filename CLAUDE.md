# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

nvim-cursorline is a Neovim plugin written in Lua that provides two cursor-related features:
- **cursorword**: Underlines the word under the cursor
- **cursorline**: Shows/hides the cursorline based on cursor movement with a configurable timeout

## Architecture

Single-file plugin located at `lua/nvim-cursorline.lua`. The module exports a `setup(options)` function that:
1. Merges user options with `DEFAULT_OPTIONS`
2. Sets up autocommands for cursorline visibility toggling (uses `vim.loop.new_timer()` for delayed re-show)
3. Sets up autocommands for cursorword highlighting via `matchadd()`/`matchdelete()`

Key implementation details:
- Window-local state stored in `vim.w` (cursorword, cursorword_id)
- Uses `CursorMoved`/`CursorMovedI` events for both features
- Cursorword pattern matching uses Vim regex (`\k*` for keyword chars)

## Testing

No test framework is currently set up. To test manually, load the plugin in Neovim:
```vim
:lua require('nvim-cursorline').setup{}
```
