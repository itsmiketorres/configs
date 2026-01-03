-- -- ~/.config/nvim/init.lua
-- A solid starting Neovim configuration with relative line numbers enabled.
-- This uses Lua for modern Neovim (0.9+). Install Neovim via your package manager.
-- Assumes you have git installed for plugin management.

-- Bootstrap lazy.nvim (plugin manager) if not installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Basic editor settings
vim.opt.number = true          -- Show absolute line numbers
vim.opt.relativenumber = true  -- Show relative line numbers (key feature!)
vim.opt.expandtab = true       -- Use spaces instead of tabs
vim.opt.shiftwidth = 2         -- Indent with 2 spaces
vim.opt.tabstop = 2            -- Tab width 2 spaces
vim.opt.smartindent = true     -- Smart autoindenting
vim.opt.wrap = false           -- No line wrapping
vim.opt.cursorline = true      -- Highlight current line
vim.opt.termguicolors = true   -- Enable true colors
vim.opt.ignorecase = true      -- Case-insensitive searching
vim.opt.smartcase = true       -- Unless uppercase in search
vim.opt.clipboard = "unnamedplus" -- Use system clipboard
vim.opt.mouse = "a"            -- Enable mouse in all modes
vim.opt.splitright = true      -- Vertical splits to the right
vim.opt.splitbelow = true      -- Horizontal splits below
vim.opt.scrolloff = 8          -- Keep 8 lines visible above/below cursor
vim.opt.signcolumn = "yes"     -- Always show sign column
vim.opt.updatetime = 300       -- Faster completion (default 4000ms)
vim.opt.timeoutlen = 500       -- Time to wait for mapped sequence

-- Leader key (space is common)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Some useful keymaps
vim.keymap.set("n", "<leader>pv", ":Ex<CR>", { desc = "Open netrw file explorer" })
vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Quick save" })
vim.keymap.set("n", "<leader>q", ":q<CR>", { desc = "Quick quit" })
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode with jk" })  -- New remap added here!

-- Install and configure plugins with lazy.nvim
require("lazy").setup({
  -- Theme (tokyonight is modern and clean)
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
    config = function()
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- Treesitter for better syntax highlighting (using new main branch API)
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",  -- Required for the new API
    build = ":TSUpdate",  -- Updates/compiles parsers
    config = function()
      local ts = require("nvim-treesitter")

      -- Optional global setup (e.g., custom install dir; defaults are fine if omitted)
      ts.setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })

      -- Install parsers async (add more languages as needed)
      ts.install({ "lua", "vim", "vimdoc", "python", "javascript", "html", "css" })

      -- Auto-enable highlighting and indentation on FileType (detects lang and starts parser)
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(event)
          local lang = vim.treesitter.language.get_lang(event.match) or event.match
          local buf = event.buf

          -- Enable highlighting
          pcall(vim.treesitter.start, buf, lang)

          -- Enable indentation (experimental Treesitter-based)
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

          -- Optional: Auto-install missing parser if needed
          ts.install({ lang })
        end,
      })
    end,
  },

  -- LSP (Language Server Protocol) for autocompletion, diagnostics, etc.
  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.lsp.config('pyright', {
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
      })
      vim.lsp.enable({'pyright'})
    end,
  },

  -- Autocompletion engine
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp", -- LSP source
      "hrsh7th/cmp-buffer",   -- Buffer source
      "hrsh7th/cmp-path",     -- Path source
      "L3MON4D3/LuaSnip",     -- Snippet engine
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- File explorer (nvim-tree)
  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      require("nvim-tree").setup()
      vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
    end,
  },

  -- Fuzzy finder (telescope)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
    end,
  },

  -- Git integration (fugitive)
  { "tpope/vim-fugitive" },

  -- Commenting (Comment.nvim)
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
  },
})

-- LSP keymaps (moved to LspAttach for buffer-local scoping)
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    local opts = { buffer = ev.buf }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
  end,
})

-- Additional autocmds or functions can go here
