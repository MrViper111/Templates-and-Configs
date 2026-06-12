vim.g.mapleader = " "

vim.deprecate = function() end

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.termguicolors = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.cursorline = true
vim.opt.wrap = false
vim.opt.scrolloff = 4
vim.opt.completeopt = "menu,menuone,noselect"
vim.opt.clipboard = "unnamedplus"
vim.opt.guifont = "JetBrainsMono Nerd Font:h12"
vim.opt.undofile = true

local function set_ibl_hl()
    vim.api.nvim_set_hl(0, "IblIndent", { fg = "#1e2130", nocombine = true })
end
set_ibl_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_ibl_hl })

vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
})

vim.keymap.set("n", "<leader>/", "gcc", { remap = true })
vim.keymap.set("v", "<leader>/", "gc",  { remap = true })

local uv = vim.uv or vim.loop
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not uv.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end

vim.opt.rtp:prepend(lazypath)

local function treesitter_config()
    local ok, configs = pcall(require, "nvim-treesitter.configs")
    if not ok then
        return
    end

    configs.setup({
        ensure_installed = {
            "lua",
            "python",
            "c",
            "cpp",
            "java",
            "bash",
            "vim",
            "query",
            "markdown",
            "markdown_inline",
        },
        highlight = { enable = true },
        indent = { enable = true },
    })
end

local function cmp_snippet_expand(args)
    local ok, luasnip = pcall(require, "luasnip")
    if not ok then
        return
    end
    luasnip.lsp_expand(args.body)
end

local function cmp_config()
    local ok_cmp, cmp = pcall(require, "cmp")
    if not ok_cmp then
        return
    end

    local ok_loader, loader = pcall(require, "luasnip.loaders.from_vscode")
    if ok_loader then
        loader.lazy_load()
    end

    cmp.setup({
        snippet = { expand = cmp_snippet_expand },
        mapping = cmp.mapping.preset.insert({
            ["<CR>"] = cmp.mapping.confirm({ select = true }),
            ["<Tab>"] = cmp.mapping.select_next_item(),
            ["<S-Tab>"] = cmp.mapping.select_prev_item(),
            ["<C-Space>"] = cmp.mapping.complete(),
        }),
        sources = {
            { name = "nvim_lsp" },
            { name = "luasnip" },
            { name = "buffer" },
            { name = "path" },
        },
    })
end

local function lsp_on_attach(ev)
    local opts = { buffer = ev.buf }
    vim.keymap.set("n", "gd",         vim.lsp.buf.definition,                            opts)
    vim.keymap.set("n", "K",          vim.lsp.buf.hover,                                 opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename,                                opts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action,                           opts)
    vim.keymap.set("n", "gr",         vim.lsp.buf.references,                            opts)
    vim.keymap.set("n", "<leader>e",  vim.diagnostic.open_float,                         opts)
    vim.keymap.set("n", "]d",         vim.diagnostic.goto_next,                          opts)
    vim.keymap.set("n", "[d",         vim.diagnostic.goto_prev,                          opts)
    vim.keymap.set("n", "]e",         function() vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR }) end, opts)
    vim.keymap.set("n", "[e",         function() vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR }) end, opts)
end

local function lsp_setup()
    local ok_mason, mason = pcall(require, "mason")
    if not ok_mason then
        return
    end

    local ok_bridge, mason_lspconfig = pcall(require, "mason-lspconfig")
    if not ok_bridge then
        return
    end

    local capabilities = {}
    local ok_caps, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
    if ok_caps then
        capabilities = cmp_nvim_lsp.default_capabilities()
    end

    mason.setup({})

    vim.lsp.config("*", { capabilities = capabilities })

    vim.lsp.config("lua_ls", {
        settings = {
            Lua = {
                diagnostics = { globals = { "vim" } },
            },
        },
    })

    mason_lspconfig.setup({
        ensure_installed = { "lua_ls", "pyright", "clangd", "jdtls" },
        automatic_enable = true,
    })

    vim.api.nvim_create_autocmd("LspAttach", {
        callback = lsp_on_attach,
    })
end

local function conform_config()
    local ok, conform = pcall(require, "conform")
    if not ok then
        return
    end

    conform.setup({
        formatters_by_ft = {
            python = { "black" },
            c      = { "clang-format" },
            cpp    = { "clang-format" },
            java   = { "clang-format" },
            lua    = { "stylua" },
        },
    })

    vim.keymap.set("n", "<leader>cf", function() conform.format({ lsp_format = "fallback" }) end)
end

local function illuminate_config()
    local ok, illuminate = pcall(require, "illuminate")
    if not ok then
        return
    end

    illuminate.configure({
        delay = 120,
        under_cursor = true,
        min_count_to_highlight = 2,
    })

    local function set_illuminate_hl()
        vim.api.nvim_set_hl(0, "IlluminatedWordText",  { bg = "#272b3d" })
        vim.api.nvim_set_hl(0, "IlluminatedWordRead",  { bg = "#272b3d" })
        vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { bg = "#2d2639" })
    end
    set_illuminate_hl()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = set_illuminate_hl })
end

local function harpoon_init()
    local ok, harpoon = pcall(require, "harpoon")
    if not ok then
        return
    end
    harpoon:setup({})
end

local function harpoon_add()
    local ok, harpoon = pcall(require, "harpoon")
    if not ok then
        return
    end
    harpoon:list():append()
end

local function harpoon_toggle_menu()
    local ok, harpoon = pcall(require, "harpoon")
    if not ok then
        return
    end
    harpoon.ui:toggle_quick_menu(harpoon:list())
end

local function harpoon_select_1()
    local ok, harpoon = pcall(require, "harpoon")
    if not ok then
        return
    end
    harpoon:list():select(1)
end

local function harpoon_select_2()
    local ok, harpoon = pcall(require, "harpoon")
    if not ok then
        return
    end
    harpoon:list():select(2)
end

local function harpoon_select_3()
    local ok, harpoon = pcall(require, "harpoon")
    if not ok then
        return
    end
    harpoon:list():select(3)
end

local function harpoon_select_4()
    local ok, harpoon = pcall(require, "harpoon")
    if not ok then
        return
    end
    harpoon:list():select(4)
end

local function which_key_config()
    local ok, wk = pcall(require, "which-key")
    if not ok then
        return
    end

    wk.setup({
        delay = 300,
        icons = { mappings = true },
    })

    wk.add({
        { "<leader>f",  group = "Find (Telescope)" },
        { "<leader>ff", desc = "Find files" },
        { "<leader>fg", desc = "Live grep" },
        { "<leader>fb", desc = "Buffers" },
        { "<leader>fh", desc = "Help tags" },

        { "<leader>x",  group = "Diagnostics (Trouble)" },
        { "<leader>xx", desc = "Project diagnostics" },
        { "<leader>xb", desc = "Buffer diagnostics" },

        { "<leader>a",  desc = "Harpoon: add file" },
        { "<leader>h",  desc = "Harpoon: menu" },
        { "<leader>1",  desc = "Harpoon: file 1" },
        { "<leader>2",  desc = "Harpoon: file 2" },
        { "<leader>3",  desc = "Harpoon: file 3" },
        { "<leader>4",  desc = "Harpoon: file 4" },

        { "<leader>u",  desc = "Undotree toggle" },
        { "<leader>e",  desc = "Diagnostic float" },
        { "<leader>rn", desc = "LSP: rename" },
        { "<leader>ca", desc = "LSP: code action" },
        { "<leader>cf", desc = "Format buffer" },
        { "<leader>/",  desc = "Toggle comment" },
        { "-",          desc = "Oil: file explorer" },
    })
end

local function catppuccin_config()
    local ok, catppuccin = pcall(require, "catppuccin")
    if not ok then
        return
    end
    catppuccin.setup({
        flavour = "macchiato",
        color_overrides = {
            macchiato = {
                base   = "#13161f",
                mantle = "#0e1119",
                crust  = "#090c14",
            },
        },
        integrations = {
            lualine        = true,
            treesitter     = true,
            gitsigns       = true,
            trouble        = true,
            mason          = true,
            telescope      = { enabled = true },
            illuminate     = { enabled = true },
            which_key      = true,
            native_lsp     = { enabled = true },
        },
    })
end

require("lazy").setup({
    { "catppuccin/nvim", name = "catppuccin", priority = 1000, config = catppuccin_config },

    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate", event = { "BufReadPost", "BufNewFile" }, config = treesitter_config },

    { "nvim-tree/nvim-web-devicons", lazy = false },

    { "nvim-lualine/lualine.nvim", dependencies = { "nvim-tree/nvim-web-devicons" }, lazy = true },

    { "nvim-lua/plenary.nvim", lazy = true },

    {
        "nvim-telescope/telescope.nvim",
        cmd = "Telescope",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope-fzf-native.nvim",
        },
        config = function()
            require("telescope").setup({})
            if vim.fn.executable("make") == 1 then
                require("telescope").load_extension("fzf")
            end
        end,
    },

    {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        lazy = true,
        cond = function() return vim.fn.executable("make") == 1 end,
    },

    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            on_attach = function()
                local ok, scrollbar = pcall(require, "scrollbar.handlers.gitsigns")
                if ok then
                    scrollbar.setup()
                end
            end,
        },
    },

    { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },

    {
        "williamboman/mason.nvim",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = {
            "williamboman/mason-lspconfig.nvim",
            "neovim/nvim-lspconfig",
        },
        config = lsp_setup,
    },

    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "rafamadriz/friendly-snippets",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
        },
        config = cmp_config,
    },

    { "ThePrimeagen/harpoon", branch = "harpoon2", keys = { "<leader>a", "<leader>h", "<leader>1", "<leader>2", "<leader>3", "<leader>4" }, dependencies = { "nvim-lua/plenary.nvim" }, config = harpoon_init },

    { "mbbill/undotree", keys = { { "<leader>u", "<cmd>UndotreeToggle<CR>" } } },

    { "stevearc/conform.nvim", event = { "BufReadPost" }, config = conform_config },

    { "RRethy/vim-illuminate", event = { "BufReadPost", "BufNewFile" }, config = illuminate_config },

    { "kylechui/nvim-surround", event = "VeryLazy", opts = {} },

    { "lukas-reineke/indent-blankline.nvim", event = { "BufReadPost", "BufNewFile" }, main = "ibl", opts = { indent = { highlight = "IblIndent" } } },

    {
        "folke/trouble.nvim",
        cmd = "Trouble",
        keys = {
            { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>" },
            { "<leader>xb", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>" },
        },
        opts = {},
    },

    { "folke/which-key.nvim", event = "VeryLazy", config = which_key_config },

    {
        "norcalli/nvim-colorizer.lua",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            require("colorizer").setup({ "*" }, {
                RGB      = true,
                RRGGBB   = true,
                names    = false,
                RRGGBBAA = true,
            })
        end,
    },

    {
        "petertriho/nvim-scrollbar",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            show_in_active_only = true,
            handlers = {
                gitsigns   = true,
                diagnostic = true,
            },
            marks = {
                Error = { text = { "─" } },
                Warn  = { text = { "─" } },
                Info  = { text = { "─" } },
                Hint  = { text = { "─" } },
            },
        },
    },

    {
        "stevearc/oil.nvim",
        keys = {
            { "-", function() require("oil").open_float() end },
        },
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            default_file_explorer = true,
            columns = { "icon" },
            float = {
                padding    = 2,
                max_width  = 60,
                max_height = 30,
                border     = "rounded",
            },
            win_options = {
                winblend      = 10,
                signcolumn    = "no",
                cursorlineopt = "line",
            },
        },
    },
})

vim.cmd.colorscheme("catppuccin")

require("lualine").setup({
    options = {
        theme = (function()
            local C = require("catppuccin.palettes").get_palette("macchiato")
            return {
                normal   = { a = { bg = C.blue,    fg = C.mantle, gui = "bold" }, b = { bg = C.surface0, fg = C.blue    }, c = { bg = C.mantle, fg = C.text } },
                insert   = { a = { bg = C.green,   fg = C.mantle, gui = "bold" }, b = { bg = C.surface0, fg = C.green   }, c = { bg = C.mantle, fg = C.text } },
                visual   = { a = { bg = C.mauve,   fg = C.mantle, gui = "bold" }, b = { bg = C.surface0, fg = C.mauve   }, c = { bg = C.mantle, fg = C.text } },
                replace  = { a = { bg = C.red,     fg = C.mantle, gui = "bold" }, b = { bg = C.surface0, fg = C.red     }, c = { bg = C.mantle, fg = C.text } },
                command  = { a = { bg = C.peach,   fg = C.mantle, gui = "bold" }, b = { bg = C.surface0, fg = C.peach   }, c = { bg = C.mantle, fg = C.text } },
                inactive = { a = { bg = C.mantle,  fg = C.blue                 }, b = { bg = C.mantle,  fg = C.surface1 }, c = { bg = C.mantle, fg = C.overlay0 } },
            }
        end)(),
        section_separators = "",
        component_separators = "",
    },
    sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff" },
        lualine_c = { "filename" },
        lualine_x = { { "diagnostics", sources = { "nvim_lsp" } } },
        lualine_y = { "filetype" },
        lualine_z = { "location" },
    },
})

vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<CR>")
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<CR>")
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<CR>")
vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<CR>")

vim.keymap.set("n", "<leader>a", harpoon_add)
vim.keymap.set("n", "<leader>h", harpoon_toggle_menu)
vim.keymap.set("n", "<leader>1", harpoon_select_1)
vim.keymap.set("n", "<leader>2", harpoon_select_2)
vim.keymap.set("n", "<leader>3", harpoon_select_3)
vim.keymap.set("n", "<leader>4", harpoon_select_4)
