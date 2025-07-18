-- lua/plugins/markdown.lua
-- Complete Markdown configuration with preview

return {
  -- Markdown preview with multiple backends
  {
    "iamcco/markdown-preview.nvim",
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    ft = "markdown",
    config = function()
      vim.g.mkdp_filetypes = { "markdown" }
      vim.g.mkdp_theme = "dark"
      vim.g.mkdp_auto_start = false
      vim.g.mkdp_auto_close = true
      vim.g.mkdp_refresh_slow = false
      vim.g.mkdp_command_for_global = false
      vim.g.mkdp_open_to_the_world = false
      vim.g.mkdp_open_ip = ""
      vim.g.mkdp_echo_preview_url = false
      vim.g.mkdp_browserfunc = ""
      vim.g.mkdp_preview_options = {
        mkit = {},
        katex = {},
        uml = {},
        maid = {},
        disable_sync_scroll = false,
        sync_scroll_type = "middle",
        hide_yaml_meta = true,
        sequence_diagrams = {},
        flowchart_diagrams = {},
        content_editable = false,
        disable_filename = false,
        toc = {},
      }
      vim.g.mkdp_markdown_css = ""
      vim.g.mkdp_highlight_css = ""
      vim.g.mkdp_port = ""
      vim.g.mkdp_page_title = "「${name}」"
    end,
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreview<cr>", desc = "Markdown preview" },
      { "<leader>ms", "<cmd>MarkdownPreviewStop<cr>", desc = "Stop preview" },
      { "<leader>mt", "<cmd>MarkdownPreviewToggle<cr>", desc = "Toggle preview" },
    },
  },

  -- Alternative Markdown preview with glow
  {
    "ellisonleao/glow.nvim",
    config = function()
      require("glow").setup({
        style = "dark",
        width = 120,
        height = 80,
        width_ratio = 0.7,
        height_ratio = 0.7,
        border = "single",
        pager = false,
        pager_cmd = "less",
        env = {
          GLOW_STYLE = "dark",
          GLOW_WIDTH = 120,
        },
      })
    end,
    keys = {
      { "<leader>mg", "<cmd>Glow<cr>", desc = "Glow preview" },
      { "<leader>mb", "<cmd>Glow!<cr>", desc = "Glow preview (buffer)" },
    },
  },

  -- Markdown LSP and formatting
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        marksman = {
          settings = {
            markdown = {
              validate = {
                enabled = true,
                referenceLinks = { enabled = true },
                fragmentLinks = { enabled = true },
                fileLinks = { enabled = true },
                unusedLinkDefinitions = { enabled = true },
                duplicateLinkDefinitions = { enabled = true },
                unusedReferences = { enabled = true },
                duplicateReferences = { enabled = true },
              },
              suggest = {
                paths = { enabled = true },
                references = { enabled = true },
                definitions = { enabled = true },
                workspaceSymbols = { enabled = true },
              },
            },
          },
        },
      },
    },
  },

  -- Markdown table of contents
  {
    "mzlogin/vim-markdown-toc",
    ft = "markdown",
    keys = {
      { "<leader>mtc", "<cmd>GenTocGFM<cr>", desc = "Generate TOC" },
      { "<leader>mtr", "<cmd>UpdateToc<cr>", desc = "Update TOC" },
      { "<leader>mtd", "<cmd>RemoveToc<cr>", desc = "Remove TOC" },
    },
  },

  -- Markdown folding
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "markdown",
        "markdown_inline",
      },
    },
  },

  -- Markdown snippets
  {
    "rafamadriz/friendly-snippets",
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load({
        include = { "markdown" },
      })
    end,
  },

  -- Markdown formatting with Prettier
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        markdown = { "prettier" },
      },
    },
  },

  -- Markdown image support
  {
    "3rd/image.nvim",
    opts = function()
      -- Detect available backends
      local backends = {}
      if vim.fn.executable("ueberzug") == 1 then
        table.insert(backends, "ueberzug")
      end
      if vim.fn.executable("kitten") == 1 then
        table.insert(backends, "kitty")
      end
      if vim.fn.executable("wezterm") == 1 then
        table.insert(backends, "wezterm")
      end
      local backend = backends[1] or "none"
      return {
        backend = backend,
        integrations = {
          markdown = {
            enabled = true,
            clear_in_insert_mode = false,
            download_remote_images = true,
            only_render_image_at_cursor = false,
            filetypes = { "markdown" },
          },
        },
        max_width = nil,
        max_height = nil,
        max_width_window_percentage = nil,
        max_height_window_percentage = 50,
      }
    end,
  },

  -- Markdown link handling
  {
    "ruifm/gitlinker.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    config = function()
      require("gitlinker").setup({
        opts = {
          callbacks = {
            ["github.com"] = require("gitlinker.hosts").get_github_type_url,
            ["gitlab.com"] = require("gitlinker.hosts").get_gitlab_type_url,
            ["bitbucket.org"] = require("gitlinker.hosts").get_bitbucket_type_url,
          },
        },
      })
    end,
    keys = {
      { "<leader>ml", "<cmd>GitLinker<cr>", desc = "Copy git link" },
    },
  },

  -- Markdown task list
  {
    "folke/twilight.nvim",
    opts = {
      dimming = {
        alpha = 0.25,
        inactive = false,
      },
      context = 10,
      treesitter = true,
      expand = {
        "function",
        "method",
        "table",
        "if_statement",
      },
    },
  },

  -- Markdown keymaps
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      -- Markdown specific keymaps
      { "<leader>mm", "<cmd>Telescope find_files search_dirs={\"docs\",\"*.md\"}<cr>", desc = "Find markdown files" },
      { "<leader>mh", "<cmd>Telescope live_grep search_dirs={\"docs\",\"*.md\"}<cr>", desc = "Search in markdown" },
    },
  },

  -- Markdown auto-completion
  {
    "hrsh7th/nvim-cmp",
    opts = function()
      local cmp = require("cmp")
      return {
        sources = {
          { name = "nvim_lsp", priority = 800 },
          { name = "luasnip", priority = 750 },
          { name = "buffer", priority = 500 },
          { name = "path", priority = 250 },
        },
      }
    end,
  },
} 