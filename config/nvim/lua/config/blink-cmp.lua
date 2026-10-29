require("blink.cmp").setup {
  keymap = {
    preset = "default",
    ["<Tab>"] = { "select_next", "fallback" },
    ["<S-Tab>"] = { "select_prev", "fallback" },
    ["<A-k>"] = { "select_next", "fallback" },
    ["<A-j>"] = { "select_prev", "fallback" },
    ["<CR>"] = { "select_and_accept", "fallback" },
    ["<C-b>"] = { "scroll_documentation_up", "fallback" },
    ["<C-f>"] = { "scroll_documentation_down", "fallback" },
  },

  appearance = {
    nerd_font_variant = "mono",
  },

  completion = {
    menu = {
      winhighlight = "Normal:BlinkCmpMenu,FloatBorder:FloatBorder,CursorLine:BlinkCmpMenuSelection,Search:None",

      draw = {
        columns = { { "kind_icon" }, { "label", gap = 1 } },
        components = {
          label = {
            text = function(ctx)
              return require("colorful-menu").blink_components_text(ctx)
            end,
            highlight = function(ctx)
              return require("colorful-menu").blink_components_highlight(ctx)
            end,
          },
        },
      },
    },
    documentation = {
      auto_show = true,
    },
  },

  signature = {
    enabled = true,
    window = {
      show_documentation = false,
    },
  },

  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
    providers = {
      thesaurus = {
        name = "blink-cmp-words",
        module = "blink-cmp-words.thesaurus",
        opts = {
          score_offset = 0,
          definition_pointers = { "!", "&", "^" },
          similarity_pointers = { "&", "^" },
          similarity_depth = 2,
        },
      },

      dictionary = {
        name = "blink-cmp-words",
        module = "blink-cmp-words.dictionary",
        opts = {
          dictionary_search_threshold = 3,
          score_offset = 0,
          definition_pointers = { "!", "&", "^" },
        },
      },
    },
    per_filetype = {
      text = { "dictionary" },
      markdown = { "dictionary" },
    },
  },

  fuzzy = { implementation = "prefer_rust_with_warning" },

  -- cmdline = {
  --   completion = {
  --     menu = {
  --       auto_show = false,
  --     },
  --   },
  --   keymap = {
  --     ["<CR>"] = { "select_and_accept", "fallback" },
  --   },
  -- },
}
