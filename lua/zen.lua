local M = {}

local a = vim.api

M.config = {
  width = 90,
  on_open = nil,
  on_close = nil,
}

M.state = {
  active = false,
  layout = nil, -- "left", "right", "center"
  padding_wins = {},
  padding_bufs = {},
  original = {},
}

local function create_padding_buf()
  local buf = a.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  return buf
end

local function set_padding_win_opts(win)
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].foldcolumn = "0"
  vim.wo[win].winhighlight = "Normal:Normal"
end

function M.open(opts)
  opts = opts or {}
  local width = opts.width or M.config.width
  local layout = opts.layout or "left" -- default: content left, padding right

  if M.state.active then return end

  local win_width = a.nvim_win_get_width(0)
  local padding = win_width - width

  if padding <= 0 then
    return
  end

  -- Save original settings
  M.state.original = {
    wrap = vim.wo.wrap,
    linebreak = vim.wo.linebreak,
    foldcolumn = vim.wo.foldcolumn,
  }

  M.state.padding_wins = {}
  M.state.padding_bufs = {}
  M.state.layout = layout

  if layout == "left" then
    -- Content left, padding right
    local buf = create_padding_buf()
    table.insert(M.state.padding_bufs, buf)

    vim.cmd("vsplit")
    vim.cmd("wincmd l")
    a.nvim_win_set_buf(0, buf)
    a.nvim_win_set_width(0, padding)
    table.insert(M.state.padding_wins, a.nvim_get_current_win())
    set_padding_win_opts(M.state.padding_wins[1])

    vim.cmd("wincmd h")

  elseif layout == "right" then
    -- Padding left, content right
    local buf = create_padding_buf()
    table.insert(M.state.padding_bufs, buf)

    vim.cmd("vsplit")
    vim.cmd("wincmd h")
    a.nvim_win_set_buf(0, buf)
    a.nvim_win_set_width(0, padding)
    table.insert(M.state.padding_wins, a.nvim_get_current_win())
    set_padding_win_opts(M.state.padding_wins[1])

    vim.cmd("wincmd l")

  elseif layout == "center" then
    -- Padding on both sides
    local left_padding = math.floor(padding / 2)
    local right_padding = padding - left_padding

    -- Create left padding
    local left_buf = create_padding_buf()
    table.insert(M.state.padding_bufs, left_buf)

    vim.cmd("vsplit")
    vim.cmd("wincmd h")
    a.nvim_win_set_buf(0, left_buf)
    a.nvim_win_set_width(0, left_padding)
    table.insert(M.state.padding_wins, a.nvim_get_current_win())
    set_padding_win_opts(M.state.padding_wins[1])

    -- Go to content window and create right padding
    vim.cmd("wincmd l")

    local right_buf = create_padding_buf()
    table.insert(M.state.padding_bufs, right_buf)

    vim.cmd("vsplit")
    vim.cmd("wincmd l")
    a.nvim_win_set_buf(0, right_buf)
    a.nvim_win_set_width(0, right_padding)
    table.insert(M.state.padding_wins, a.nvim_get_current_win())
    set_padding_win_opts(M.state.padding_wins[2])

    -- Back to content window
    vim.cmd("wincmd h")
  end

  -- Apply zen settings to main window
  vim.wo.wrap = true
  vim.wo.linebreak = true
  vim.wo.foldcolumn = "0"

  M.state.active = true

  if M.config.on_open then
    M.config.on_open()
  end
end

function M.close()
  if not M.state.active then return end

  -- Close all padding windows
  for _, win in ipairs(M.state.padding_wins) do
    if a.nvim_win_is_valid(win) then
      a.nvim_win_close(win, true)
    end
  end

  -- Restore original settings
  vim.wo.wrap = M.state.original.wrap
  vim.wo.linebreak = M.state.original.linebreak
  vim.wo.foldcolumn = M.state.original.foldcolumn

  M.state.active = false
  M.state.layout = nil
  M.state.padding_wins = {}
  M.state.padding_bufs = {}

  if M.config.on_close then
    M.config.on_close()
  end
end

function M.toggle(opts)
  if M.state.active then
    M.close()
  else
    M.open(opts)
  end
end

function M.set_layout(layout)
  local was_active = M.state.active
  if was_active then
    M.close()
  end
  M.open({ layout = layout })
end

function M.is_active()
  return M.state.active
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  M._initialized = true

  -- Register commands
  a.nvim_create_user_command("Zen", function(cmd_opts)
    local width = cmd_opts.args ~= "" and tonumber(cmd_opts.args) or nil
    M.toggle({ width = width })
  end, { nargs = "?" })

  a.nvim_create_user_command("ZenOpen", function(cmd_opts)
    local width = cmd_opts.args ~= "" and tonumber(cmd_opts.args) or nil
    M.open({ width = width })
  end, { nargs = "?" })

  a.nvim_create_user_command("ZenClose", function()
    M.close()
  end, {})
end

-- Auto-initialize with defaults if setup wasn't called
local function ensure_init()
  if not M._initialized then
    M.setup({})
  end
end

-- Wrap public functions to auto-init
local _open = M.open
M.open = function(opts)
  ensure_init()
  return _open(opts)
end

local _toggle = M.toggle
M.toggle = function(opts)
  ensure_init()
  return _toggle(opts)
end

local _set_layout = M.set_layout
M.set_layout = function(layout)
  ensure_init()
  return _set_layout(layout)
end

return M
