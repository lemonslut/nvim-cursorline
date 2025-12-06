local M = {}

local w = vim.w
local a = vim.api
local fn = vim.fn
local hl = a.nvim_set_hl
local au = a.nvim_create_autocmd
local timer_line = vim.loop.new_timer()
local timer_col = vim.loop.new_timer()

local ns_line = a.nvim_create_namespace("nvim_cursorline")
local ns_col = a.nvim_create_namespace("nvim_cursorcolumn")

local DEFAULT_OPTIONS = {
  cursorline = {
    enable = true,
    timeout = 1000,
    lines = 3, -- total lines to highlight (centered on cursor)
  },
  cursorcolumn = {
    enable = true,
    timeout = 1000,
    columns = 3, -- total columns to highlight (centered on cursor)
  },
  cursorword = {
    enable = true,
    min_length = 3,
    hl = { underline = true },
  },
}

local function clear_cursorline(bufnr)
  a.nvim_buf_clear_namespace(bufnr, ns_line, 0, -1)
end

local function draw_cursorline(bufnr)
  clear_cursorline(bufnr)
  local cursor_row = a.nvim_win_get_cursor(0)[1] - 1 -- 0-indexed
  local total_lines = a.nvim_buf_line_count(bufnr)
  local spread = math.floor(M.options.cursorline.lines / 2)

  for offset = -spread, spread do
    local row = cursor_row + offset
    if row >= 0 and row < total_lines then
      a.nvim_buf_set_extmark(bufnr, ns_line, row, 0, {
        end_row = row + 1,
        hl_group = "CursorLine",
        hl_eol = true,
        priority = 100,
      })
    end
  end
end

local function clear_cursorcolumn(bufnr)
  a.nvim_buf_clear_namespace(bufnr, ns_col, 0, -1)
end

local function draw_cursorcolumn(bufnr, winid)
  clear_cursorcolumn(bufnr)
  local cursor_col = a.nvim_win_get_cursor(winid)[2] -- 0-indexed byte offset
  local spread = math.floor(M.options.cursorcolumn.columns / 2)
  local top_line = fn.line("w0", winid)
  local bot_line = fn.line("w$", winid)

  for lnum = top_line, bot_line do
    local row = lnum - 1 -- 0-indexed
    local line = a.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
    local line_len = #line

    local leftmost_col = cursor_col - spread
    local rightmost_col = cursor_col + spread

    if line_len <= leftmost_col then
      -- entire highlight range is in virtual space
      a.nvim_buf_set_extmark(bufnr, ns_col, row, 0, {
        virt_text = { { string.rep(" ", M.options.cursorcolumn.columns), "CursorColumn" } },
        virt_text_pos = "overlay",
        virt_text_win_col = leftmost_col,
        priority = 99,
      })
    elseif line_len <= rightmost_col then
      -- partial: some real chars, some virtual
      for offset = -spread, spread do
        local col = cursor_col + offset
        if col >= 0 and col < line_len then
          a.nvim_buf_set_extmark(bufnr, ns_col, row, col, {
            end_col = col + 1,
            hl_group = "CursorColumn",
            priority = 99,
          })
        end
      end
      -- fill the gap with virtual text starting exactly at line end
      local virtual_cols = rightmost_col - line_len + 1
      a.nvim_buf_set_extmark(bufnr, ns_col, row, 0, {
        virt_text = { { string.rep(" ", virtual_cols), "CursorColumn" } },
        virt_text_pos = "overlay",
        virt_text_win_col = line_len,
        priority = 99,
      })
    else
      -- all columns have real characters
      for offset = -spread, spread do
        local col = cursor_col + offset
        if col >= 0 and col < line_len then
          a.nvim_buf_set_extmark(bufnr, ns_col, row, col, {
            end_col = col + 1,
            hl_group = "CursorColumn",
            priority = 99,
          })
        end
      end
    end
  end
end

local function matchadd()
  local column = a.nvim_win_get_cursor(0)[2]
  local line = a.nvim_get_current_line()
  local cursorword = fn.matchstr(line:sub(1, column + 1), [[\k*$]])
    .. fn.matchstr(line:sub(column + 1), [[^\k*]]):sub(2)

  if cursorword == w.cursorword then
    return
  end
  w.cursorword = cursorword
  if w.cursorword_id then
    vim.call("matchdelete", w.cursorword_id)
    w.cursorword_id = nil
  end
  if
    cursorword == ""
    or #cursorword > 100
    or #cursorword < M.options.cursorword.min_length
    or string.find(cursorword, "[\192-\255]+") ~= nil
  then
    return
  end
  local pattern = [[\<]] .. cursorword .. [[\>]]
  w.cursorword_id = fn.matchadd("CursorWord", pattern, -1)
end

function M.setup(options)
  M.options = vim.tbl_deep_extend("force", DEFAULT_OPTIONS, options or {})

  if M.options.cursorline.enable then
    local function show_cursorline()
      draw_cursorline(a.nvim_get_current_buf())
    end

    local function hide_cursorline()
      clear_cursorline(a.nvim_get_current_buf())
    end

    show_cursorline()

    au("WinEnter", { callback = show_cursorline })
    au("WinLeave", { callback = hide_cursorline })
    au("BufEnter", { callback = show_cursorline })

    au({ "CursorMoved", "CursorMovedI" }, {
      callback = function()
        if M.options.cursorline.timeout > 0 then
          hide_cursorline()
          timer_line:start(
            M.options.cursorline.timeout,
            0,
            vim.schedule_wrap(show_cursorline)
          )
        else
          show_cursorline()
        end
      end,
    })
  end

  if M.options.cursorcolumn.enable then
    local function show_cursorcolumn()
      draw_cursorcolumn(a.nvim_get_current_buf(), a.nvim_get_current_win())
    end

    local function hide_cursorcolumn()
      clear_cursorcolumn(a.nvim_get_current_buf())
    end

    show_cursorcolumn()

    au("WinEnter", { callback = show_cursorcolumn })
    au("WinLeave", { callback = hide_cursorcolumn })
    au("BufEnter", { callback = show_cursorcolumn })
    au("WinScrolled", { callback = show_cursorcolumn })

    au({ "CursorMoved", "CursorMovedI" }, {
      callback = function()
        if M.options.cursorcolumn.timeout > 0 then
          hide_cursorcolumn()
          timer_col:start(
            M.options.cursorcolumn.timeout,
            0,
            vim.schedule_wrap(show_cursorcolumn)
          )
        else
          show_cursorcolumn()
        end
      end,
    })
  end

  if M.options.cursorword.enable then
    au("VimEnter", {
      callback = function()
        hl(0, "CursorWord", M.options.cursorword.hl)
        matchadd()
      end,
    })
    au({ "CursorMoved", "CursorMovedI" }, {
      callback = function()
        matchadd()
      end,
    })
  end
end

M.options = nil

return M
