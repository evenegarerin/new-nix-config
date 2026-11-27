// ==UserScript==
// @name           vimkeys
// @description    Vimium-style keys everywhere: pages, about: pages, browser dialogs, file://, …
// @include        main
// ==/UserScript==

(function () {
  "use strict";

  if (location.href !== "chrome://browser/content/browser.xhtml") return;

  const {
    KeyHandler, SETTINGS, session, eventTarget, windowOf, consume, isEditable, deepActiveElement,
  } = ChromeUtils.importESModule("chrome://userscripts/content/vimkeys/core.sys.mjs");
  const { BROWSER_COMMANDS, WINDOW_KEYS, isRepeatable, resolveKeys } =
    ChromeUtils.importESModule("chrome://userscripts/content/bindings.sys.mjs");
  const { omnibarFor } =
    ChromeUtils.importESModule("chrome://userscripts/content/omnibar.sys.mjs");

  const omnibar = omnibarFor(window);

  const HTML_NS = "http://www.w3.org/1999/xhtml";
  const BADGE_ID = "vimkeys-mode-indicator";
  const BADGE_CSS =
    "position:fixed; margin:0; width:max-content; height:max-content;" +
    "box-sizing:border-box; padding:3px 9px; overflow:visible; pointer-events:none;" +
    "font:bold 11px/1.4 Helvetica, Arial, sans-serif; letter-spacing:.09em; text-transform:uppercase;" +
    "white-space:nowrap; border-radius:4px; box-shadow:0 2px 6px rgba(0,0,0,.35);";
  const BADGE_GAP = 14;
  const CONTENT_BOX_ID = "tabbrowser-tabbox";
  const MODE_STYLES = {
    insert: { text: "#1d2a07", border: "#6f941f", top: "#c8ea72", bottom: "#9acd32" },
    visual: { text: "#35173a", border: "#a05ea8", top: "#efc4ef", bottom: "#dda0dd" },
  };

  let badge = null;
  let modeOwner = null;
  let pageMode = null;

  function ensureBadge() {
    if (badge?.isConnected) return badge;
    badge = document.createElementNS(HTML_NS, "div");
    badge.id = BADGE_ID;
    badge.setAttribute("popover", "manual");
    document.documentElement.append(badge);
    return badge;
  }

  function contentBox() {
    const rect = document.getElementById(CONTENT_BOX_ID)?.getBoundingClientRect();
    return rect?.width && rect?.height ? rect : null;
  }

  function badgeCss(mode) {
    const style = MODE_STYLES[mode];
    const rect = contentBox();
    const left = Math.round((rect?.left ?? 0) + BADGE_GAP);
    const viewport = document.documentElement.clientHeight;
    const bottom = Math.round(rect ? viewport - rect.bottom + BADGE_GAP : BADGE_GAP);
    return (
      BADGE_CSS +
      `inset:auto auto ${Math.max(bottom, 0)}px ${Math.max(left, 0)}px;` +
      `color:${style.text}; border:1px solid ${style.border};` +
      `background:linear-gradient(to bottom, ${style.top}, ${style.bottom});`
    );
  }

  function hideBadge() {
    if (!badge?.isConnected) return;
    try {
      badge.hidePopover();
    } catch {}
  }

  function clearMode() {
    modeOwner = null;
    pageMode = null;
    hideBadge();
  }

  function setMode(mode, contextId) {
    if (!mode) {
      if (modeOwner !== null && modeOwner !== contextId) return;
      clearMode();
      return;
    }
    modeOwner = contextId;
    pageMode = mode;
    if (!MODE_STYLES[mode]) {
      hideBadge();
      return;
    }
    try {
      const el = ensureBadge();
      el.textContent = mode;
      el.style.cssText = badgeCss(mode);
      el.showPopover();
    } catch (err) {
      console.error("[vimkeys]", err);
    }
  }

  const COMMANDS = {
    find: () => findBarCommand("onFindCommand"),
    findNext: () => findBarCommand("onFindAgainCommand", false),
    findPrevious: () => findBarCommand("onFindAgainCommand", true),
    newTab: () => openNewTab(),
    closeTab: (browser) => closeTab(tabFor(browser)),
    restoreTab: () => restoreTab(),
    splitView: () => BrowserCommands.addTabSplitView(),
    goBack: (browser) => browser.canGoBack && browser.goBack(),
    goForward: (browser) => browser.canGoForward && browser.goForward(),
    nextTab: () => cycleTabs(1),
    previousTab: () => cycleTabs(-1),
    openOmnibar: () => omnibar.open(),
    openOmnibarNewTab: () => omnibar.open({ newTab: true }),
    openOmnibarBookmarks: () => omnibar.open({ sources: "bookmarks", selectFirst: true }),
    openOmnibarBookmarksNewTab: () =>
      omnibar.open({ sources: "bookmarks", newTab: true, selectFirst: true }),
    openOmnibarTabs: () => omnibar.open({ sources: "tabs", selectFirst: true }),
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

  function commandFor(name) {
    if (!BROWSER_COMMANDS.has(name)) return null;
    if (Object.hasOwn(COMMANDS, name)) return COMMANDS[name];
    const extras = window.vimkeysCommands;
    if (extras && Object.hasOwn(extras, name) && typeof extras[name] === "function") {
      return extras[name];
    }
    return null;
  }

  function runBrowserCommand(name, browser = gBrowser.selectedBrowser) {
    const command = commandFor(name);
    if (!command) return;
    let target = browser;
    if (name !== "nextTab" && name !== "previousTab" && commitCycle()) {
      target = gBrowser.selectedBrowser;
    }
    Promise.resolve()
      .then(() => command(target ?? gBrowser.selectedBrowser))
      .catch((err) => console.error("[vimkeys]", err));
  }

  window.vimkeys = { runBrowserCommand, setMode };

  function peerTabs(tab) {
    if (tab.group) return tab.group.tabs;
    return gBrowser.tabs.filter((other) => !other.group && other.pinned === tab.pinned);
  }

  const CYCLE_ID = "vimkeys-tab-cycle";
  const CYCLE_GAP = 56;
  const CYCLE_SETTLE_MS = 150;
  const CYCLE_CSS =
    "position:fixed; margin:0; width:max-content; max-width:min(520px, 60vw);" +
    "height:max-content; box-sizing:border-box; padding:7px 13px; overflow:hidden;" +
    "pointer-events:none; display:flex; align-items:center; gap:9px;" +
    "font:13px/1.4 Helvetica, Arial, sans-serif; white-space:nowrap;" +
    "border-radius:9px; box-shadow:0 4px 14px rgba(0,0,0,.45);" +
    "color:light-dark(#15141a, #fbfbfe);" +
    "background:light-dark(rgb(249, 249, 251), rgb(43, 42, 51));" +
    "border:1px solid light-dark(rgba(0, 0, 0, .18), rgba(255, 255, 255, .2));";
  const CYCLE_FAVICON = "chrome://global/skin/icons/defaultFavicon.svg";

  let cycleOverlay = null;
  let cycleTarget = null;
  let cycleSteps = 0;
  let cycleTimer = null;

  function tabReady(tab) {
    if (!tab || tab.hasAttribute("pending") || tab.hasAttribute("busy")) return false;
    return !!tab.linkedBrowser?.browsingContext?.currentWindowGlobal;
  }

  function ensureCycleOverlay() {
    if (cycleOverlay?.isConnected) return cycleOverlay;
    cycleOverlay = document.createElementNS(HTML_NS, "div");
    cycleOverlay.id = CYCLE_ID;
    cycleOverlay.setAttribute("popover", "manual");
    document.documentElement.append(cycleOverlay);
    return cycleOverlay;
  }

  function cycleCss() {
    const rect = contentBox();
    const viewport = document.documentElement.clientHeight;
    const centerX = Math.round(rect ? rect.left + rect.width / 2 : window.innerWidth / 2);
    const bottom = Math.round(rect ? viewport - rect.bottom + CYCLE_GAP : CYCLE_GAP);
    return (
      CYCLE_CSS +
      `inset:auto auto ${Math.max(bottom, 0)}px ${Math.max(centerX, 0)}px;` +
      "transform:translateX(-50%);"
    );
  }

  function showCyclePreview(tab) {
    const el = ensureCycleOverlay();
    el.textContent = "";

    const icon = document.createElementNS(HTML_NS, "img");
    icon.style.cssText = "width:16px; height:16px; flex:0 0 auto; border-radius:3px;";
    icon.addEventListener("error", () => { icon.src = CYCLE_FAVICON; }, { once: true });
    icon.src = gBrowser.getIcon(tab) || CYCLE_FAVICON;

    const title = document.createElementNS(HTML_NS, "span");
    title.style.cssText = "overflow:hidden; text-overflow:ellipsis;";
    title.textContent = tab.label || tab.linkedBrowser?.currentURI?.displaySpec || "";

    const count = document.createElementNS(HTML_NS, "span");
    count.style.cssText = "flex:0 0 auto; opacity:.55; font-variant-numeric:tabular-nums;";
    count.textContent = cycleSteps > 0 ? `+${cycleSteps}` : String(cycleSteps);

    el.append(icon, title, count);
    el.style.cssText = cycleCss();
    try {
      el.showPopover();
    } catch {}
  }

  function hideCyclePreview() {
    if (!cycleOverlay?.isConnected) return;
    try {
      cycleOverlay.hidePopover();
    } catch {}
  }

  function cancelCycle() {
    if (cycleTimer) {
      clearTimeout(cycleTimer);
      cycleTimer = null;
    }
    cycleTarget = null;
    cycleSteps = 0;
    hideCyclePreview();
  }

  function commitCycle() {
    const target = cycleTarget;
    cancelCycle();
    if (!target?.isConnected || target.closing) return false;
    if (target === gBrowser.selectedTab) return false;
    gBrowser.selectedTab = target;
    return true;
  }

  function cycleTabs(delta) {
    const base = cycleTarget?.isConnected ? cycleTarget : gBrowser.selectedTab;
    if (!base) return;
    const tabs = peerTabs(base).filter((tab) => !tab.hidden && !tab.closing);
    const index = tabs.indexOf(base);
    if (index < 0 || tabs.length < 2) return;
    const next = tabs[(index + delta + tabs.length) % tabs.length];

    if (!cycleTarget && tabReady(next)) {
      cycleSteps = 0;
      gBrowser.selectedTab = next;
      return;
    }

    cycleTarget = next;
    cycleSteps += delta;
    if (Math.abs(cycleSteps) >= 2) showCyclePreview(next);
    if (cycleTimer) clearTimeout(cycleTimer);
    cycleTimer = setTimeout(commitCycle, CYCLE_SETTLE_MS);
  }

  function tabFor(browser) {
    return gBrowser.getTabForBrowser(browser) ?? gBrowser.selectedTab;
  }

  function closeTab(tab) {
    const partner = tab.splitview?.tabs.find((other) => other !== tab && !other.closing);
    if (partner) gBrowser.setSuccessor(tab, partner);
    gBrowser.removeTab(tab, { animate: true });
  }

  async function findBarCommand(method, ...args) {
    const findBar = await gBrowser.getFindBar();
    findBar[method](...args);
  }

  function openNewTab() {
    if (typeof gBrowser.addAdjacentNewTab === "function") {
      gBrowser.addAdjacentNewTab(gBrowser.selectedTab);
    } else if (window.BrowserCommands?.openTab) {
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
      relatedToCurrent: newTab,
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

  const dialogHints = new KeyHandler({ hintDocument: () => null, runBrowserCommand: () => {} });

  function findBarAccepting(event) {
    if (event.key !== "Enter" || event.ctrlKey || event.altKey || event.metaKey) return null;
    if (event.isComposing) return null;
    const target = eventTarget(event);
    if (!target?.classList?.contains("findbar-textbox")) return null;
    const findBar = target.closest("findbar");
    if (!findBar || findBar.hidden || findBar.findMode !== findBar.FIND_NORMAL) return null;
    return findBar;
  }

  let windowPending = "";

  function windowKeyCommand(event) {
    const browser = gBrowser.selectedBrowser;
    const pageKey =
      !event.ctrlKey && !event.altKey && !event.metaKey && !event.isComposing &&
      !pageMode && browser?.isRemoteBrowser && eventTarget(event) === browser;
    if (!pageKey) {
      windowPending = "";
      return null;
    }
    if (event.key.length !== 1) return null;

    const match =
      resolveKeys(windowPending + event.key) ??
      (windowPending ? resolveKeys(event.key) : null);
    windowPending = "";
    if (!match) return null;
    if (match.prefix) {
      windowPending = match.keys;
      return null;
    }
    return WINDOW_KEYS.has(match.keys) ? match.command : null;
  }

  function resetPagePending(browser) {
    const contexts = browser?.browsingContext?.getAllBrowsingContextsInSubtree() ?? [];
    for (const context of contexts) {
      try {
        context.currentWindowGlobal?.getActor(ACTOR_NAME).sendAsyncMessage("Vimkeys:resetPending", {});
      } catch {}
    }
  }

  function onKeyDown(event) {
    if (dialogHints.handleHintKey(event)) return;

    const findBar = findBarAccepting(event);
    if (findBar) {
      consume(event);
      findBar.close();
      return;
    }

    const command = windowKeyCommand(event);
    if (command) {
      consume(event);
      const browser = gBrowser.selectedBrowser;
      resetPagePending(browser);
      if (!event.repeat || isRepeatable(command, SETTINGS.smoothScroll)) {
        runBrowserCommand(command, browser);
      }
      return;
    }
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

  function dialogFrameOf(win) {
    while (win && win !== window) {
      const frame = win.frameElement;
      if (!frame) return null;
      if (isBrowserDialogFrame(frame)) return frame;
      win = windowOf(frame);
    }
    return null;
  }

  const ACTOR_NAME = "VimkeysActor";
  const ACTOR_DIR = "chrome://userscripts/content/vimkeys/";
  const ACTOR_OPTIONS = {
    parent: { esModuleURI: ACTOR_DIR + "VimkeysActorParent.sys.mjs" },
    child: {
      esModuleURI: ACTOR_DIR + "VimkeysActorChild.sys.mjs",
      events: { DOMDocElementInserted: {}, DOMContentLoaded: {}, pageshow: {} },
    },
    messageManagerGroups: ["browsers"],
    allFrames: true,
    safeForUntrustedWebProcess: true,
  };

  function registerPageActor() {
    if (session.pageActorRegistered) return;
    session.pageActorRegistered = true;
    try {
      ChromeUtils.registerWindowActor(ACTOR_NAME, ACTOR_OPTIONS);
    } catch {
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

  function attachPageActor(browser) {
    const global = browser?.browsingContext?.currentWindowGlobal;
    if (!global) return;
    try {
      global.getActor(ACTOR_NAME).sendAsyncMessage("Vimkeys:attach", {});
    } catch (err) {
      console.error("[vimkeys] could not reach the page actor:", err);
    }
  }

  const progressListener = {
    QueryInterface: ChromeUtils.generateQI([
      "nsIWebProgressListener",
      "nsISupportsWeakReference",
    ]),
    onLocationChange(browser, webProgress) {
      if (webProgress?.isTopLevel) attachPageActor(browser);
    },
    onStateChange(browser, webProgress, request, flags) {
      if (!webProgress?.isTopLevel) return;
      if (flags & Ci.nsIWebProgressListener.STATE_STOP) attachPageActor(browser);
    },
  };

  function focusSplitAfterSwitch() {
    if (!gBrowser.selectedTab.splitview) return;
    const active = document.activeElement;
    if (active && active !== document.body && active !== document.documentElement) return;
    gBrowser.selectedBrowser.focus();
  }

  function init() {
    window.addEventListener("keydown", onKeyDown, true);
    gBrowser.addEventListener("TabSwitchDone", focusSplitAfterSwitch);
    gBrowser.addTabsProgressListener(progressListener);
    window.addEventListener(
      "unload",
      () => gBrowser.removeTabsProgressListener(progressListener),
      { once: true }
    );
    window.addEventListener("mousedown", () => dialogHints.exitHints(), true);
    gBrowser.tabContainer.addEventListener("TabSelect", () => {
      dialogHints.exitHints();
      windowPending = "";
      omnibar.close();
      clearMode();
      cancelCycle();
    });
    window.addEventListener(
      "unload",
      () => {
        cancelCycle();
        badge?.remove();
        cycleOverlay?.remove();
      },
      { once: true }
    );
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
