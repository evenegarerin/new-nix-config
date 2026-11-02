// ==UserScript==
// @name           vimkeys
// @description    Vimium-style keys where extensions can't run: about: pages, browser dialogs, file:// pages
// @include        main
// ==/UserScript==

// Settings, key bindings, hints and scrolling live in vimkeys/core.sys.mjs.
// This script covers what only the browser window can do: tab, history and
// find commands, pages loaded in the browser process (about:config, …) and
// browser dialogs. The VimkeysActor covers file:// pages and sends its
// browser commands here (see runBrowserCommand below).

(function () {
  "use strict";

  if (location.href !== "chrome://browser/content/browser.xhtml") return;

  const { KeyHandler, BROWSER_COMMANDS, session, eventTarget, windowOf, consume, isEditable, deepActiveElement } =
    ChromeUtils.importESModule("chrome://userscripts/content/vimkeys/core.sys.mjs");

  // ---- Browser commands ----------------------------------------------------
  // `browser` is the tab's <browser> the key came from.
  const COMMANDS = {
    find: () => findBarCommand("onFindCommand"),
    findNext: () => findBarCommand("onFindAgainCommand", false),
    findPrevious: () => findBarCommand("onFindAgainCommand", true),
    newTab: () => openNewTab(),
    closeTab: (browser) => gBrowser.removeTab(tabFor(browser), { animate: true }),
    restoreTab: () => restoreTab(),
    goBack: (browser) => browser.canGoBack && browser.goBack(),
    goForward: (browser) => browser.canGoForward && browser.goForward(),
    nextTab: () => gBrowser.tabContainer.advanceSelectedTab(1, true),
    previousTab: () => gBrowser.tabContainer.advanceSelectedTab(-1, true),
  };

  function runBrowserCommand(name, browser = gBrowser.selectedBrowser) {
    // Names can come from a page's content process, so only known ones run.
    if (!BROWSER_COMMANDS.has(name) || !Object.hasOwn(COMMANDS, name)) return;
    Promise.resolve()
      .then(() => COMMANDS[name](browser ?? gBrowser.selectedBrowser))
      .catch((err) => console.error("[vimkeys]", err));
  }

  // Used by VimkeysActorParent for keys pressed in file:// pages.
  window.vimkeys = { runBrowserCommand };

  function tabFor(browser) {
    return gBrowser.getTabForBrowser(browser) ?? gBrowser.selectedTab;
  }

  async function findBarCommand(method, ...args) {
    const findBar = await gBrowser.getFindBar();
    findBar[method](...args);
  }

  // Same as Ctrl+T: respects your new-tab page setting and focuses the address bar.
  function openNewTab() {
    if (window.BrowserCommands?.openTab) {
      window.BrowserCommands.openTab();
    } else {
      window.BrowserOpenTab();
    }
  }

  function restoreTab() {
    if (window.SessionWindowUI?.undoCloseTab) {
      window.SessionWindowUI.undoCloseTab(window);
    } else if (typeof window.undoCloseTab === "function") {
      window.undoCloseTab();
    } else {
      SessionStore.undoCloseTab(window, 0);
    }
  }

  // ---- Keys ----------------------------------------------------------------
  const keys = new KeyHandler({
    hintDocument: (ctx) => topDialogFrame()?.contentDocument ?? ctx.browser.contentDocument,
    runBrowserCommand: (name, ctx) => runBrowserCommand(name, ctx.browser),
  });

  function onKeyDown(event) {
    if (keys.handleHintKey(event)) return;
    if (event.ctrlKey || event.altKey || event.metaKey || event.isComposing) return;

    // Browser dialogs (confirmations, alerts, …) sit on top of any tab, including
    // normal websites where Vimium can't reach them. Only f is handled there;
    // Enter, Escape and Tab keep their usual dialog behaviour.
    const dialogFrame = dialogFrameOf(windowOf(eventTarget(event)));
    if (dialogFrame) {
      const doc = dialogFrame.contentDocument;
      const typing = isEditable(eventTarget(event)) || isEditable(deepActiveElement(doc));
      if (event.key === "f" && !typing) {
        consume(event);
        if (!event.repeat) keys.startHints(doc);
      }
      return;
    }

    const ctx = getContext(event);
    if (ctx) keys.onKeyDown(event, ctx);
  }

  // Only act on pages loaded in the browser process. Normal websites are
  // Vimium's job and file:// pages the actor's, so nobody fights over a key.
  function getContext(event) {
    const browser = gBrowser.selectedBrowser;
    if (!browser || browser.isRemoteBrowser) return null;
    const target = eventTarget(event);
    const win = windowOf(target);
    if (!win || !isInsideBrowser(win, browser)) return null;
    return { browser, target, win, code: event.code };
  }

  function isInsideBrowser(win, browser) {
    const bc = win.browsingContext;
    if (bc && browser.browsingContext && bc.top === browser.browsingContext) return true;
    try {
      return win.top === browser.contentWindow;
    } catch {
      return false;
    }
  }

  // ---- Browser dialogs -----------------------------------------------------
  // Firefox shows its dialogs in a <browser class="dialogFrame"> in the browser
  // window (tab-modal and window-modal ones alike). Dialogs inside a page, like
  // the ones in about:preferences, are part of that page and need nothing extra.
  function isBrowserDialogFrame(frame) {
    return frame.ownerDocument === document && frame.classList?.contains("dialogFrame");
  }

  // The browser dialog a window belongs to, if any.
  function dialogFrameOf(win) {
    while (win && win !== window) {
      const frame = win.frameElement;
      if (!frame) return null;
      if (isBrowserDialogFrame(frame)) return frame;
      win = windowOf(frame);
    }
    return null;
  }

  // The dialog f should target: the focused one, else the last visible one.
  // Dialogs of background tabs are hidden, so they never count.
  function topDialogFrame() {
    const frames = [...document.querySelectorAll("browser.dialogFrame")].filter((frame) => {
      const { width, height } = frame.getBoundingClientRect();
      return width > 0 && height > 0 && frame.contentDocument?.documentElement;
    });
    if (!frames.length) return null;
    const focused = dialogFrameOf(Services.focus.focusedWindow);
    return frames.includes(focused) ? focused : frames.at(-1);
  }

  // ---- file:// pages -------------------------------------------------------
  // Registered here rather than with fx-autoconfig's @WindowActor header,
  // because that helper only allows about:-page processes and file:// pages
  // run in a process of their own. Leaving out remoteTypes lets the actor
  // follow file:// pages into whatever process Firefox puts them in.
  const ACTOR_NAME = "VimkeysActor";
  const ACTOR_DIR = "chrome://userscripts/content/VimkeysActor/";
  const ACTOR_OPTIONS = {
    parent: { esModuleURI: ACTOR_DIR + "VimkeysActorParent.sys.mjs" },
    child: {
      esModuleURI: ACTOR_DIR + "VimkeysActorChild.sys.mjs",
      events: { DOMContentLoaded: {} },
    },
    matches: ["file:///*"],
    allFrames: true, // so keys also work inside iframes of a local page
    // Firefox refuses actors in web and file:// processes unless they are
    // declared safe there, i.e. their parent side can't be abused by a
    // compromised page process. Ours only accepts a fixed list of command
    // names (see runBrowserCommand), so the worst a hostile page could do is
    // what you could do yourself with a key press: close a tab, switch tabs, …
    safeForUntrustedWebProcess: true,
  };

  function registerFileActor() {
    // Every browser window runs this script; only the first one registers.
    if (session.fileActorRegistered) return;
    session.fileActorRegistered = true;
    try {
      ChromeUtils.registerWindowActor(ACTOR_NAME, ACTOR_OPTIONS);
    } catch {
      // The name is taken before any window of ours registered it, most likely
      // by an old copy of this script whose @WindowActor header made
      // fx-autoconfig register it without file:// support. Replace that one.
      console.warn(`[vimkeys] '${ACTOR_NAME}' was already registered elsewhere ` +
        "(an old @WindowActor header?); replacing it with the file:// version.");
      try {
        ChromeUtils.unregisterWindowActor(ACTOR_NAME);
        ChromeUtils.registerWindowActor(ACTOR_NAME, ACTOR_OPTIONS);
      } catch (err) {
        console.error("[vimkeys] could not register the file:// actor:", err);
      }
    }
  }

  // ---- Startup -------------------------------------------------------------
  function init() {
    window.addEventListener("keydown", onKeyDown, true);
    window.addEventListener("keyup", (event) => keys.onKeyUp(event), true);
    window.addEventListener("blur", () => keys.onBlur());
    // Clicking anywhere in the window (toolbar included) ends hint mode.
    window.addEventListener("mousedown", () => keys.exitHints(), true);
    gBrowser.tabContainer.addEventListener("TabSelect", () => keys.stop());
  }

  registerFileActor();

  if (gBrowserInit.delayedStartupFinished) {
    init();
  } else {
    const observer = (subject) => {
      if (subject !== window) return;
      Services.obs.removeObserver(observer, "browser-delayed-startup-finished");
      init();
    };
    Services.obs.addObserver(observer, "browser-delayed-startup-finished");
  }
})();
