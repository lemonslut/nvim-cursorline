# clearview.nvim

Tools for a readable, transparent terminal experience in Neovim.

## Features

- **Cursorline** - Multi-line highlight centered on cursor with fade effect at edges
- **Cursorcolumn** - Multi-column highlight (extends into virtual space)
- **Cursorword** - Underline word under cursor
- **Zen mode** - Padding split to constrain content width for focused writing

Designed to work with semi-transparent terminals (e.g., Kitty with `transparent_background_colors`).

## Installation

```lua
-- lazy.nvim
{
  "lemonslut/clearview.nvim",
  config = function()
    require("clearview").setup({
      cursorline = {
        enable = true,
        timeout = 0,
        lines = 9,
        fade_lines = 2,
      },
    })

    require("zen").setup({
      width = 90,
    })
  end,
}
```

## Cursorline Options

```lua
require("clearview").setup({
  cursorline = {
    enable = true,
    timeout = 0,           -- 0 = always visible, >0 = hide on move, reappear after ms
    lines = 9,             -- number of lines to highlight (centered on cursor)
    fade_lines = 2,        -- lines at edge using CursorLineFade1, CursorLineFade2, etc.
    disable_native = true, -- disable vim's native cursorline
  },
  cursorcolumn = {
    enable = false,
    timeout = 0,
    columns = 3,
    disable_native = true,
  },
  cursorword = {
    enable = false,
    min_length = 3,
    hl = { underline = true },
  },
})
```

## Zen Mode Options

```lua
require("zen").setup({
  width = 90,        -- content width in columns
  on_open = function()
    vim.b.cmp_enabled = false
  end,
  on_close = function()
    vim.b.cmp_enabled = true
  end,
})
```

**Commands**: `:Zen`, `:ZenOpen`, `:ZenClose`

## Highlight Groups

For the fade effect, define these highlight groups:

```lua
hl.CursorLine = { bg = "#3d2845" }
hl.CursorLineFade1 = { bg = "#3b2643" }
hl.CursorLineFade2 = { bg = "#392441" }
```

For transparent terminals, add matching colors to your terminal config (e.g., Kitty's `transparent_background_colors`).

## License

MIT
