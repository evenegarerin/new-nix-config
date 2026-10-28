require("blink.cmp").setup {
  -- 'default' mirrors the builtin completion: <C-y> accepts, <C-n>/<C-p> move,
  -- <C-space> opens the menu, <C-e> dismisses.
  keymap = {
    preset = "default",
    ["<Tab>"] = { "select_next", "fallback" },
    ["<S-Tab>"] = { "select_prev", "fallback" },

    -- With the menu open this always completes: `select_and_accept` picks the
    -- first item when nothing is selected. Enter is only a newline when the
    -- menu is closed.
    ["<CR>"] = { "select_and_accept", "fallback" },

    -- NOTE: the target puts documentation scrolling on <C-U>/<C-D>. Both are
    -- already taken in insert mode by mappings.lua -- <C-u> uppercases the word
    -- under the cursor, <C-D> is forward-delete -- and blink would shadow them
    -- whenever the menu is open. <C-b>/<C-f> are free and are the conventional
    -- page-up/page-down pair.
    ["<C-b>"] = { "scroll_documentation_up", "fallback" },
    ["<C-f>"] = { "scroll_documentation_down", "fallback" },
  },

  appearance = {
    -- 'mono' for 'Nerd Font Mono', so the icons line up
    nerd_font_variant = "mono",
  },

  completion = {
    menu = {
      winhighlight = "Normal:BlinkCmpMenu,FloatBorder:FloatBorder,CursorLine:BlinkCmpMenuSelection,Search:None",

      -- colorful-menu renders the item label as highlighted code. The target
      -- only ever wires colorful-menu into nvim-cmp (config/nvim-cmp.lua:64),
      -- which is the *disabled* engine -- taken as-is the plugin loads and does
      -- nothing. This is the blink equivalent, from its own README.
      draw = {
        -- label_description is not needed: colorful-menu folds it into label
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
    -- NOTE: the target also lists "ultisnips" here with a blink.compat provider.
    -- UltiSnips needs the python3 provider, which globals.lua disables.
    -- friendly-snippets covers snippets through blink's own snippet source.
    default = { "lsp", "path", "snippets", "buffer" },
    providers = {
      -- synonyms, for prose
      thesaurus = {
        name = "blink-cmp-words",
        module = "blink-cmp-words.thesaurus",
        opts = {
          score_offset = 0,
          -- lexical relations listed under each definition: antonyms,
          -- "similar to", "also see"
          definition_pointers = { "!", "&", "^" },
          similarity_pointers = { "&", "^" },
          -- how deep to recurse for synonyms; higher is slower
          similarity_depth = 2,
        },
      },

      dictionary = {
        name = "blink-cmp-words",
        module = "blink-cmp-words.dictionary",
        opts = {
          -- characters needed before the dictionary is searched
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

  -- Rust fuzzy matcher: typo resistant and much faster than the lua fallback
  fuzzy = { implementation = "prefer_rust_with_warning" },

  cmdline = {
    completion = {
      menu = {
        auto_show = true,
      },
    },
    keymap = {
      ["<CR>"] = { "select_and_accept", "fallback" },
    },
  },
}
