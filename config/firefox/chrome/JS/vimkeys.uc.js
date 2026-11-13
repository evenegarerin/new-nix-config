// ==UserScript==
// @name           vimkeys
// @description    Vimium-style keys wherever Vimium can't run: about: pages, browser dialogs, file://, …
// @include        main
// ==/UserScript==

// Settings, key bindings, hints and scrolling live in vimkeys/core.sys.mjs.
// VimkeysActor brings them to every page Vimium can't reach (about:config,
// the new tab page, file://, …) and sends browser commands here. This script
// covers what only the browser window can do: tab, history and find commands
// (see runBrowserCommand), browser dialogs, and registering the actor.

(function () {
  "use strict";

  if (location.href !== "chrome://browser/content/browser.xhtml") return;

  const { KeyHandler, BROWSER_COMMANDS, session, eventTarget, windowOf, consume, isEditable, deepActiveElement } =
    ChromeUtils.importESModule("chrome://userscripts/content/vimkeys/core.sys.mjs");
  const { Omnibar } =
    ChromeUtils.importESModule("chrome://userscripts/content/vimkeys/omnibar.sys.mjs");

  const omnibar = new Omnibar(window);

  const HTML_NS = "http://www.w3.org/1999/xhtml";
  const BADGE_ID = "vimkeys-mode-indicator";
  const BADGE_CSS =
    "position:fixed; margin:0; inset:auto auto 14px 14px; width:max-content; height:max-content;" +
    "box-sizing:border-box; padding:3px 9px; overflow:visible; pointer-events:none;" +
    "font:bold 11px/1.4 Helvetica, Arial, sans-serif; letter-spacing:.09em; text-transform:uppercase;" +
    "color:#302505; white-space:nowrap; border:1px solid #c38a22; border-radius:4px;" +
    "background:linear-gradient(to bottom, #fff785, #ffc542); box-shadow:0 2px 6px rgba(0,0,0,.35);";

  let badge = null;
  let modeOwner = null;

  function ensureBadge() {
    if (badge?.isConnected) return badge;
    badge = document.createElementNS(HTML_NS, "div");
    badge.id = BADGE_ID;
    badge.setAttribute("popover", "manual");
    badge.style.cssText = BADGE_CSS;
    document.documentElement.append(badge);
    return badge;
  }

  function hideBadge() {
    if (!badge?.isConnected) return;
    try {
      badge.hidePopover();
    } catch {}
  }

  function clearMode() {
    modeOwner = null;
    hideBadge();
  }

  function setMode(mode, contextId) {
    if (!mode) {
      if (modeOwner !== null && modeOwner !== contextId) return;
      clearMode();
      return;
    }
    modeOwner = contextId;
    try {
      const el = ensureBadge();
      el.textContent = mode;
      el.showPopover();
    } catch (err) {
      console.error("[vimkeys]", err);
    }
  }

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
    openOmnibar: () => omnibar.open(),
    openOmnibarNewTab: () => omnibar.open({ newTab: true }),
    openOmnibarBookmarks: () => omnibar.open({ sources: "bookmarks" }),
    openOmnibarBookmarksNewTab: () => omnibar.open({ sources: "bookmarks", newTab: true }),
    openOmnibarTabs: () => omnibar.open({ sources: "tabs" }),
    editUrl: () => omnibar.open({ prefill: gBrowser.currentURI?.displaySpec ?? "" }),
    reload: (browser) => browser.reload(),
    reloadHard: (browser) =>
      browser.reloadWithFlags(
        Ci.nsIWebNavigation.LOAD_FLAGS_BYPASS_CACHE |
          Ci.nsIWebNavigation.LOAD_FLAGS_BYPASS_PROXY
      ),
    copyUrl: () => copyCurrentUrl(),
    openClipboardUrl: () => openClipboardUrl(false),
    openClipboardUrlNewTab: () => openClipboardUrl(true),
  };

  function runBrowserCommand(name, browser = gBrowser.selectedBrowser) {
    // Names can come from a page's content process, so only known ones run.
    if (!BROWSER_COMMANDS.has(name) || !Object.hasOwn(COMMANDS, name)) return;
    Promise.resolve()
      .then(() => COMMANDS[name](browser ?? gBrowser.selectedBrowser))
      .catch((err) => console.error("[vimkeys]", err));
  }

  // Used by VimkeysActorParent for keys pressed in pages.
  window.vimkeys = { runBrowserCommand, setMode };

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

  function copyCurrentUrl() {
    const url = gBrowser.currentURI?.displaySpec;
    if (!url) return;
    Cc["@mozilla.org/widget/clipboardhelper;1"]
      .getService(Ci.nsIClipboardHelper)
      .copyString(url);
  }

  function readClipboardText() {
    const xferable = Cc["@mozilla.org/widget/transferable;1"].createInstance(Ci.nsITransferable);
    xferable.init(null);
    xferable.addDataFlavor("text/plain");
    const windowContext = window.browsingContext?.currentWindowContext;
    if (windowContext) {
      Services.clipboard.getData(xferable, Ci.nsIClipboard.kGlobalClipboard, windowContext);
    } else {
      Services.clipboard.getData(xferable, Ci.nsIClipboard.kGlobalClipboard);
    }
    const data = {};
    xferable.getTransferData("text/plain", data);
    return data.value?.QueryInterface(Ci.nsISupportsString)?.data ?? "";
  }

  function openClipboardUrl(newTab) {
    let text;
    try {
      text = readClipboardText().trim();
    } catch (err) {
      console.error("[vimkeys]", err);
      return;
    }
    if (!text) return;

    let info;
    try {
      info = Services.uriFixup.getFixupURIInfo(
        text,
        Ci.nsIURIFixup.FIXUP_FLAG_FIX_SCHEME_TYPOS |
          Ci.nsIURIFixup.FIXUP_FLAG_ALLOW_KEYWORD_LOOKUP
      );
    } catch (err) {
      console.error("[vimkeys]", err);
      return;
    }

    const url = info.preferredURI?.spec;
    if (!url) return;
    const scheme = info.preferredURI.scheme;
    if (scheme === "javascript" || scheme === "data") {
      console.warn("[vimkeys] refusing to open", url);
      return;
    }

    openTrustedLinkIn(url, newTab ? "tab" : "current", {
      postData: info.postData,
      allowInheritPrincipal: false,
    });
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

  // ---- Browser dialogs -----------------------------------------------------
  // Pages, about:config included, get their keys from VimkeysActor. What's left
  // here are Firefox's own dialogs (confirmations, alerts, …): they sit on top
  // of any tab, including normal websites where Vimium can't reach them. Only f
  // is handled there; Enter, Escape and Tab keep their usual dialog behaviour.
  // Firefox shows them in a <browser class="dialogFrame"> in the browser
  // window (tab-modal and window-modal ones alike).
  const dialogHints = new KeyHandler({ hintDocument: () => null, runBrowserCommand: () => {} });

  function onKeyDown(event) {
    if (dialogHints.handleHintKey(event)) return;
    if (event.key !== "f" || event.ctrlKey || event.altKey || event.metaKey || event.isComposing) return;
    const dialogFrame = dialogFrameOf(windowOf(eventTarget(event)));
    if (!dialogFrame) return;
    const doc = dialogFrame.contentDocument;
    if (isEditable(eventTarget(event)) || isEditable(deepActiveElement(doc))) return;
    consume(event);
    if (!event.repeat) dialogHints.startHints(doc);
  }

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

  // ---- Pages Vimium can't reach --------------------------------------------
  // The actor comes to every page in a tab; on each one its child asks Firefox
  // whether Vimium's scripts run there and only takes over if they don't (see
  // VimkeysActorChild). Registered here rather than with fx-autoconfig's
  // @WindowActor header, which only allows about:-page processes.
  const ACTOR_NAME = "VimkeysActor";
  const ACTOR_DIR = "chrome://userscripts/content/vimkeys/";
  const ACTOR_OPTIONS = {
    parent: { esModuleURI: ACTOR_DIR + "VimkeysActorParent.sys.mjs" },
    child: {
      esModuleURI: ACTOR_DIR + "VimkeysActorChild.sys.mjs",
      events: { DOMContentLoaded: {} },
    },
    // No `matches`: every page. Only pages in tabs, though; not sidebars,
    // extension popups or devtools.
    messageManagerGroups: ["browsers"],
    allFrames: true, // frames are checked on their own, just like Vimium's
    // Firefox refuses actors in web and file:// processes unless they are
    // declared safe there, i.e. their parent side can't be abused by a
    // compromised page process. Ours only accepts a fixed list of command
    // names (see runBrowserCommand), so the worst a hostile page could do is
    // what you could do yourself with a key press: close a tab, switch tabs, …
    safeForUntrustedWebProcess: true,
  };

  function registerPageActor() {
    // Every browser window runs this script; only the first one registers.
    if (session.pageActorRegistered) return;
    session.pageActorRegistered = true;
    try {
      ChromeUtils.registerWindowActor(ACTOR_NAME, ACTOR_OPTIONS);
    } catch {
      // The name is taken before any window of ours registered it, most likely
      // by an old copy of this script whose @WindowActor header made
      // fx-autoconfig register it without file:// support. Replace that one.
      console.warn(`[vimkeys] '${ACTOR_NAME}' was already registered elsewhere ` +
        "(an old @WindowActor header?); replacing it with this version.");
      try {
        ChromeUtils.unregisterWindowActor(ACTOR_NAME);
        ChromeUtils.registerWindowActor(ACTOR_NAME, ACTOR_OPTIONS);
      } catch (err) {
        console.error("[vimkeys] could not register the page actor:", err);
      }
    }
  }

  // ---- Startup -------------------------------------------------------------
  function init() {
    window.addEventListener("keydown", onKeyDown, true);
    // Clicking anywhere in the window or switching tabs ends dialog hints.
    window.addEventListener("mousedown", () => dialogHints.exitHints(), true);
    gBrowser.tabContainer.addEventListener("TabSelect", () => {
      dialogHints.exitHints();
      omnibar.close();
      clearMode();
    });
    window.addEventListener("unload", () => {
      omnibar.destroy();
      badge?.remove();
    }, { once: true });
  }

  registerPageActor();

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
