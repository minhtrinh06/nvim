-- ┌─────────────────────────┐
-- │ Plugins outside of MINI │
-- └─────────────────────────┘
--
-- This file contains installation and configuration of plugins outside of MINI.
-- They significantly improve user experience in a way not yet possible with MINI.
-- These are mostly plugins that provide programming language specific behavior.
--
-- Use this file to install and configure other such plugins.

-- Make concise helpers for installing/adding plugins in two stages
local add = vim.pack.add
local now_if_args, later = Config.now_if_args, Config.later

-- My Plugins  ================================================================

-- Tmux Navigator
later(function()
  add({ 'https://github.com/alexghergh/nvim-tmux-navigation' })

  local nvim_tmux_nav = require('nvim-tmux-navigation')

  nvim_tmux_nav.setup {
      disable_when_zoomed = true -- defaults to false
  }

  vim.keymap.set('n', '<C-h>', nvim_tmux_nav.NvimTmuxNavigateLeft)
  vim.keymap.set('n', '<C-j>', nvim_tmux_nav.NvimTmuxNavigateDown)
  vim.keymap.set('n', '<C-k>', nvim_tmux_nav.NvimTmuxNavigateUp)
  vim.keymap.set('n', '<C-l>', nvim_tmux_nav.NvimTmuxNavigateRight)
end)

-- Milli nvim dashboard ascii gif
Config.now(function()
  add({ 'https://github.com/Amansingh-afk/milli.nvim' })
  require("milli").starter({ splash = "shader", loop = true })
end)

-- Helm filetype detection. Neovim has no built-in 'helm' filetype, and the
-- 'helm_ls' language server only attaches to it, so this plugin is what makes
-- the Helm setup actually work (it also sets 'yaml.helm-values' for values files).
later(function() add({ 'https://github.com/towolf/vim-helm' }) end)


-- Tree-sitter ================================================================

-- Tree-sitter is a tool for fast incremental parsing. It converts text into
-- a hierarchical structure (called tree) that can be used to implement advanced
-- and/or more precise actions: syntax highlighting, textobjects, indent, etc.
--
-- Tree-sitter support is built into Neovim (see `:h treesitter`). However, it
-- requires two extra pieces that don't come with Neovim directly:
-- - Language parsers: programs that convert text into trees. Some are built-in
--   (like for Lua), 'nvim-treesitter' provides many others.
--   NOTE: It requires third party software to build and install parsers.
--   See the link for more info in "Requirements" section of the MiniMax README.
-- - Query files: definitions of how to extract information from trees in
--   a useful manner (see `:h treesitter-query`). 'nvim-treesitter' also provides
--   these, while 'nvim-treesitter-textobjects' provides the ones for Neovim
--   textobjects (see `:h text-objects`, `:h MiniAi.gen_spec.treesitter()`).
--
-- Add these plugins now if file (and not 'mini.starter') is shown after startup.
--
-- Troubleshooting:
-- - Run `:checkhealth vim.treesitter nvim-treesitter` to see potential issues.
-- - In case of errors related to queries for Neovim bundled parsers (like `lua`,
--   `vimdoc`, `markdown`, etc.), manually install them via 'nvim-treesitter'
--   with `:TSInstall <language>`. Be sure to have necessary system dependencies
--   (see MiniMax README section for software requirements).
now_if_args(function()
  -- Define hook to update tree-sitter parsers after plugin is updated
  local ts_update = function() vim.cmd('TSUpdate') end
  Config.on_packchanged('nvim-treesitter', { 'update' }, ts_update, ':TSUpdate')

  add({
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/nvim-treesitter/nvim-treesitter-textobjects',
  })

  -- Define languages which will have parsers installed and auto enabled
  -- After changing this, restart Neovim once to install necessary parsers. Wait
  -- for the installation to finish before opening a file for added language(s).
  local languages = {
    -- These are already pre-installed with Neovim. Used as an example.
    'lua',
    'vimdoc',
    'markdown',
    -- Add here more languages with which you want to use tree-sitter
    -- To see available languages:
    -- - Execute `:=require('nvim-treesitter').get_available()`
    -- - Visit 'SUPPORTED_LANGUAGES.md' file at
    --   https://github.com/nvim-treesitter/nvim-treesitter/blob/main
    'go',
    'odin',
    'python',
    'c',
    'terraform',
    'godot_resource',
    'html',
    'bash',
    'css',
    'yaml',
    'prisma',
    'csv',
    'gdscript',
    'diff',
    'gitignore',
    'gitattributes',
    'gitcommit',
    'git_config',
    'git_rebase',
    'proto',
    'rust',
    'zig',
    'make',
    'llvm',
    'cpp',
    'c_sharp',
    'java',
    'jinja',
    'json',
    'jsx',
    'latex',
    -- Added for requested languages / servers below
    'markdown_inline', -- inline markup inside markdown
    'javascript',      -- Next.js / eslint / deno
    'typescript',      -- Next.js / eslint / deno
    'tsx',             -- Next.js (React) components
    'graphql',
    'dockerfile',      -- docker
    'dot',             -- graphviz / dot language server
    'hcl',             -- terraform (.tf / .hcl)
    'cmake',
    'jq',
    -- NOTE: css, html, yaml, json, prisma, proto, rust, odin, java, jinja,
    -- terraform and latex parsers are already listed above and cover the
    -- rest of the requested languages. Django/Helm/htmx/tailwind have no
    -- dedicated parser and reuse html/yaml highlighting + their LSP.
  }
  local isnt_installed = function(lang)
    return #vim.api.nvim_get_runtime_file('parser/' .. lang .. '.*', false) == 0
  end
  local to_install = vim.tbl_filter(isnt_installed, languages)
  if #to_install > 0 then require('nvim-treesitter').install(to_install) end

  -- Enable tree-sitter after opening a file for a target language
  local filetypes = {}
  for _, lang in ipairs(languages) do
    for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
      table.insert(filetypes, ft)
    end
  end
  local ts_start = function(ev) vim.treesitter.start(ev.buf) end
  Config.new_autocmd('FileType', filetypes, ts_start, 'Start tree-sitter')
end)

-- Language servers ===========================================================

-- Language Server Protocol (LSP) is a set of conventions that power creation of
-- language specific tools. It requires two parts:
-- - Server - program that performs language specific computations.
-- - Client - program that asks server for computations and shows results.
--
-- Here Neovim itself is a client (see `:h vim.lsp`). Language servers need to
-- be installed separately based on your OS, CLI tools, and preferences.
-- See note about 'mason.nvim' at the bottom of the file.
--
-- Neovim's team collects commonly used configurations for most language servers
-- inside 'neovim/nvim-lspconfig' plugin.
--
-- Add it now if file (and not 'mini.starter') is shown after startup.
--
-- Troubleshooting:
-- - Run `:checkhealth vim.lsp` to see potential issues.
now_if_args(function()
  add({ 'https://github.com/neovim/nvim-lspconfig' })

  -- Use `:h vim.lsp.enable()` to automatically enable language server based on
  -- the rules provided by 'nvim-lspconfig'.
  -- Use `:h vim.lsp.config()` or 'after/lsp/' directory to configure servers.
  -- Uncomment and tweak the following `vim.lsp.enable()` call to enable servers.
  vim.lsp.enable({
  -- -- For example, if `lua-language-server` is installed, use `'lua_ls'` entry
    'lua_ls',
    'pyright',
  })
end)

-- Formatting =================================================================

-- Programs dedicated to text formatting (a.k.a. formatters) are very useful.
-- Neovim has built-in tools for text formatting (see `:h gq` and `:h 'formatprg'`).
-- They can be used to configure external programs, but it might become tedious.
--
-- The 'stevearc/conform.nvim' plugin is a good and maintained solution for easier
-- formatting setup.
later(function()
  add({ 'https://github.com/stevearc/conform.nvim' })

  -- See also:
  -- - `:h Conform`
  -- - `:h conform-options`
  -- - `:h conform-formatters`
  require('conform').setup({
    default_format_opts = {
      -- Allow formatting from LSP server if no dedicated formatter is available
      lsp_format = 'fallback',
    },
    -- Map of filetype -> formatters. The listed CLI tools are installed via
    -- Mason below (see "Mason tools"). `stop_after_first` picks the first tool
    -- that is available (e.g. prettierd if running, else prettier).
    -- Filetypes without an entry fall back to LSP formatting (see above), which
    -- covers odin (ols), terraform (terraformls), latex (texlab), prisma,
    -- proto (protols) and cmake (neocmakelsp).
    formatters_by_ft = {
      lua = { 'stylua' },
      sh = { 'shfmt' },
      bash = { 'shfmt' },
      rust = { 'rustfmt', lsp_format = 'fallback' },
      jq = { 'jq' },
      -- prettier family (installed via npm through Mason)
      css = { 'prettierd', 'prettier', stop_after_first = true },
      scss = { 'prettierd', 'prettier', stop_after_first = true },
      less = { 'prettierd', 'prettier', stop_after_first = true },
      html = { 'prettierd', 'prettier', stop_after_first = true },
      json = { 'prettierd', 'prettier', stop_after_first = true },
      jsonc = { 'prettierd', 'prettier', stop_after_first = true },
      yaml = { 'prettierd', 'prettier', stop_after_first = true },
      markdown = { 'prettierd', 'prettier', stop_after_first = true },
      graphql = { 'prettierd', 'prettier', stop_after_first = true },
      javascript = { 'prettierd', 'prettier', stop_after_first = true },
      javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
      typescript = { 'prettierd', 'prettier', stop_after_first = true },
      typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
    },
    -- Format on save. Falls back to LSP formatting; remove this block if you
    -- prefer to format manually (e.g. bind `require('conform').format`).
    format_on_save = { timeout_ms = 1000, lsp_format = 'fallback' },
  })
end)

-- Linting ====================================================================

-- Linters are standalone programs (not LSP servers) that report diagnostics.
-- Many languages here are already linted by their language server (e.g. the
-- 'eslint' server lints JS/TS, 'yamlls' validates YAML against schemas), so
-- 'nvim-lint' only fills the gaps with dedicated CLI linters.
--
-- The linter CLIs are installed via Mason (see "Mason tools" below). All the
-- ones chosen here ship as prebuilt binaries or npm packages, so they need no
-- Go/Python toolchain.
later(function()
  add({ 'https://github.com/mfussenegger/nvim-lint' })

  require('lint').linters_by_ft = {
    dockerfile = { 'hadolint' },
    sh = { 'shellcheck' },
    bash = { 'shellcheck' },
    markdown = { 'markdownlint' },
    terraform = { 'tflint' },
    -- NOTE: GitHub Actions and ESLint are handled by their language servers
    -- ('gh_actions_ls' and 'eslint'), so no extra linter is wired for them.
  }

  -- Trigger linting on common events. `try_lint` is a no-op for filetypes
  -- without a configured linter, so this is safe to run everywhere.
  local lint_events = { 'BufWritePost', 'BufReadPost', 'InsertLeave' }
  Config.new_autocmd(lint_events, '*', function()
    -- Only lint if the linter executable is actually installed
    require('lint').try_lint()
  end, 'Run nvim-lint')
end)

-- Mason tools ================================================================

-- 'mason-lspconfig' (below) only installs *language servers*. Formatters and
-- linters are separate CLI tools, so ensure they are installed here directly
-- through Mason's registry API (no extra plugin needed). Names are Mason
-- package names (see `:Mason` for the full list).
later(function()
  local tools = {
    'stylua',       -- Lua formatter
    'shfmt',        -- shell formatter
    'prettier',     -- css/html/json/yaml/markdown/graphql/js/ts formatter
    'prettierd',    -- faster prettier daemon (preferred when running)
    'hadolint',     -- Dockerfile linter
    'shellcheck',   -- shell linter
    'markdownlint', -- Markdown linter
    'tflint',       -- Terraform linter
  }

  local registry = require('mason-registry')
  local install = function()
    for _, name in ipairs(tools) do
      local ok, pkg = pcall(registry.get_package, name)
      if ok and not pkg:is_installed() then pkg:install() end
    end
  end
  -- Registry may need refreshing on first run before packages are resolvable
  if registry.refresh then registry.refresh(install) else install() end
end)

-- Snippets ===================================================================

-- Although 'mini.snippets' provides functionality to manage snippet files, it
-- deliberately doesn't come with those.
--
-- The 'rafamadriz/friendly-snippets' is currently the largest collection of
-- snippet files. They are organized in 'snippets/' directory (mostly) per language.
-- 'mini.snippets' is designed to work with it as seamlessly as possible.
-- See `:h MiniSnippets.gen_loader.from_lang()`.
later(function() add({ 'https://github.com/rafamadriz/friendly-snippets' }) end)

-- Honorable mentions =========================================================

-- 'mason-org/mason.nvim' (a.k.a. "Mason") is a great tool (package manager) for
-- installing external language servers, formatters, and linters. It provides
-- a unified interface for installing, updating, and deleting such programs.
--
-- The caveat is that these programs will be set up to be mostly used inside Neovim.
-- If you need them to work elsewhere, consider using other package managers.
--
-- You can use it like so:

Config.now(function()
  add({ 'https://github.com/mason-org/mason.nvim' })
  require('mason').setup({
    ui = {
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗"
      }
    }
  })
end)

Config.now(function()
  add({ 'https://github.com/mason-org/mason-lspconfig.nvim'})
  require('mason-lspconfig').setup({
    -- Language servers Mason downloads automatically. Names are the
    -- 'nvim-lspconfig' server names (see `:h lspconfig-all`). With
    -- `automatic_enable = true` below, each installed server is enabled via
    -- the native `vim.lsp.enable()` and picks up any 'after/lsp/<name>.lua'.
    ensure_installed = {
      -- Existing
      "lua_ls",       -- Lua
      "pyright",      -- Python

      -- Web / frontend
      "cssls",        -- CSS
      "html",         -- HTML
      "ts_ls",        -- TypeScript / JavaScript / Next.js (React)
      "eslint",       -- ESLint (vscode-eslint-language-server)
      "tailwindcss",  -- Tailwind CSS
      "htmx",         -- htmx
      "graphql",      -- GraphQL
      "denols",       -- Deno (activates only in deno.json projects)
      "emmet_language_server", -- handy for html/jsx (optional, remove if unwanted)

      -- Templating
      "djlsp",        -- Django templates
      "jinja_lsp",    -- Jinja

      -- Systems / general languages
      "ols",          -- Odin
      "rust_analyzer",-- Rust
      "jdtls",        -- Java (needs a JDK 17+ on PATH to run)
      "neocmake",     -- CMake (neocmakelsp; Rust binary — cmake-language-server
                      -- needs Python <3.14 which isn't satisfiable here)
      "protols",      -- Protocol Buffers (built with cargo)
      "texlab",       -- LaTeX

      -- Infra / DevOps
      "dockerls",                        -- Dockerfile
      "docker_compose_language_service", -- Docker Compose
      "helm_ls",                         -- Helm charts
      "terraformls",                     -- Terraform
      "azure_pipelines_ls",              -- Azure Pipelines
      "gh_actions_ls",                   -- GitHub Actions workflows

      -- Data / config
      "jsonls",       -- JSON
      "yamlls",       -- YAML
      -- "jqls",      -- jq LSP needs Go on PATH. Re-add after `mise use -g go`.
                      -- Meanwhile jq gets tree-sitter highlighting + `jq` formatter.
      "prismals",     -- Prisma
      "dotls",        -- Graphviz DOT language server
      "marksman",     -- Markdown
    },

    -- Automatically enable servers via Neovim 0.11/0.12+ native vim.lsp.enable()
    automatic_enable = true,
  })
end)

-- Beautiful, usable, well maintained color schemes outside of 'mini.nvim' and
-- have full support of its highlight groups. Use if you don't like 'miniwinter'
-- enabled in 'plugin/30_mini.lua' or other suggested 'mini.hues' based ones.
Config.now(function()
 -- Install only those that you need
 add({
   -- 'https://github.com/sainnhe/everforest',
   -- 'https://github.com/Shatur/neovim-ayu',
   'https://github.com/ellisonleao/gruvbox.nvim',
 })
--
  -- Keep terminal transparency by not painting the background
  require('gruvbox').setup({ transparent_mode = true })
  -- Enable only one
  vim.cmd('color gruvbox')
end)
