import os
import json

def load_colors():
    default_colors = {
        "mPrimary": "#c4c0ff",
        "mOnPrimary": "#2a2377",
        "mSecondary": "#c7c4dc",
        "mOnSecondary": "#302e42",
        "mTertiary": "#ebb9d0",
        "mOnTertiary": "#472638",
        "mError": "#ffb4ab",
        "mOnError": "#690005",
        "mSurface": "#131316",
        "mOnSurface": "#e5e1e6",
        "mSurfaceVariant": "#201f23",
        "mOnSurfaceVariant": "#c8c5d0",
        "mOutline": "#47464f",
        "mShadow": "#000000",
        "mHover": "#ebb9d0",
        "mOnHover": "472638",
    }

    # try loading custom colors here

    return default_colors

colors = load_colors()

c.content.prefers_reduced_motion = True
c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.policy.images = "never"
c.colors.webpage.darkmode.policy.page = "smart"

c.hints.mode = "letter"
c.hints.chars = "asdfghjklqwertzuiopyxcvbnm"
c.hints.uppercase = True
c.hints.auto_follow = "unique-match"
c.hints.padding = {"top": 4, "bottom": 4, "left": 4, "right": 4}

c.url.searchengines = {
    "DEFAULT": "https://google.com/search?q={}",
    "yt": "https://youtube.com/results?search_query={}",
    "nix": "https://search.nixos.org/options?channel=25.11&query={}",
    "home": "https://home-manager-options.extranix.com/?query={}&release=release-25.11",
}

c.url.default_page = "https://en.wikipedia.org/wiki/Special:Random"
c.url.start_pages = [ "https://en.wikipedia.org/wiki/Special:Random" ]

c.completion.delay = 0
c.completion.min_chars = 1

c.completion.quick = True

c.completion.open_categories = ["bookmarks"]

c.content.autoplay = False
c.content.canvas_reading = False
c.content.geolocation = True
c.content.headers.referer = "same-domain"
c.content.blocking.enabled = True
c.content.blocking.method = "auto"
c.content.javascript.enabled = True
c.content.notifications.enabled = False

c.tabs.last_close = 'blank'

c.spellcheck.languages = []

c.auto_save.session = False
c.session.default_name = None

config.bind('<Return>', 'command-accept', mode='command')

config.bind("<Alt-1>", "tab-focus 1")
config.bind("<Alt-2>", "tab-focus 2")
config.bind("<Alt-3>", "tab-focus 3")
config.bind("<Alt-4>", "tab-focus 4")
config.bind("<Alt-5>", "tab-focus 5")
config.bind("<Alt-6>", "tab-focus 6")
config.bind("<Alt-7>", "tab-focus 7")
config.bind("<Alt-8>", "tab-focus 8")
config.bind("<Alt-9>", "tab-focus 9")
config.bind("<Alt-0>", "tab-focus 10")

config.bind("<Alt-j>", "tab-prev")
config.bind("<Alt-k>", "tab-next")

config.bind("<q>", "tab-close")

config.bind("h", "scroll left")
config.bind("j", "scroll down")
config.bind("k", "scroll up")
config.bind("l", "scroll right")

config.bind('<Escape>', 'mode-leave', mode='hint')
config.bind('<Escape>', 'mode-leave', mode='insert')
config.bind('<Escape>', 'mode-leave', mode='prompt')
config.bind('<Escape>', 'mode-leave', mode='register')
config.bind('<Escape>', 'mode-leave', mode='yesno')

config.bind('<Up>', 'completion-item-focus --history prev', mode='command')
config.bind('<Down>', 'completion-item-focus --history next', mode='command')

config.bind('<back>', 'back')

config.bind('<Tab>', 'completion-item-focus --history next', mode='command')

config.bind('<F5>', 'reload')

config.bind("f", "hint")
config.bind("o", "cmd-set-text -s :open")
config.bind("t", "cmd-set-text -s :open -t")

config.bind('yy', 'yank')

config.bind('u', 'undo')
