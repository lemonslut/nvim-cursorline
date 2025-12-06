# nvim-cursorline

Highlight words, lines, and columns around the cursor for Neovim

- Highlights multiple lines centered on cursor (configurable width)
- Highlights multiple columns centered on cursor (extends into virtual space)
- Underlines the word under the cursor

## Installation

Install with your favorite plugin manager.

**Important:** Disable native `cursorline` and `cursorcolumn` in your config, as this plugin replaces them with extmark-based rendering.

```lua
vim.opt.cursorline = false
vim.opt.cursorcolumn = false
```

## Usage

```lua
require('nvim-cursorline').setup {
  cursorline = {
    enable = true,
    timeout = 0,    -- 0 = always visible, >0 = hide on move, reappear after ms
    lines = 3,      -- number of lines to highlight (centered on cursor)
  },
  cursorcolumn = {
    enable = true,
    timeout = 0,
    columns = 3,    -- number of columns to highlight (centered on cursor)
  },
  cursorword = {
    enable = true,
    min_length = 3,
    hl = { underline = true },
  }
}
```

## Acknowledgments

Thanks goes to these people/projects for inspiration:

- [delphinus/vim-auto-cursorline](https://github.com/delphinus/vim-auto-cursorline)
- [itchyny/vim-cursorword](https://github.com/itchyny/vim-cursorword)

## License

This software is released under the MIT License, see LICENSE.
