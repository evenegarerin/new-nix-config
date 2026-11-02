// ==UserScript==
// @name           vimkeys
// @description    Vimium-style keys for pages extensions can't touch (about:config, about:preferences, about:addons, …)
// @include        main
// ==/UserScript==

(function () {
  "use strict";

  if (location.href !== "chrome://browser/content/browser.xhtml") return;

  // ---- Settings (same meaning as Vimium's options) -------------------------
  const HINT_CHARS = "sadfjklewcmpgh"; // "Characters used for link hints"
  const SCROLL_STEP = 60;              // "Scroll step size" in px
  const SMOOTH_SCROLL = true;          // "Use smooth scrolling"

  const COMMANDS = {
    "/": () => findBarCommand("onFindCommand"),
    n: () => findBarCommand("onFindAgainCommand", false),
    N: () => findBarCommand("onFindAgainCommand", true),
    f: (ctx) => startHints(topDialogFrame()?.contentDocument ?? ctx.browser.contentDocument),
    j: (ctx) => scrollBy(ctx, SCROLL_STEP),
    k: (ctx) => scrollBy(ctx, -SCROLL_STEP),
    gg: (ctx) => scrollToEdge(ctx, "top"),
    G: (ctx) => scrollToEdge(ctx, "bottom"),
    x: () => gBrowser.removeTab(gBrowser.selectedTab, { animate: true }),
    X: () => restoreTab(),
    H: ({ browser }) => browser.canGoBack && browser.goBack(),
    L: ({ browser }) => browser.canGoForward && browser.goForward(),
    J: () => gBrowser.tabContainer.advanceSelectedTab(1, true),  // right (Vimium default: K)
    K: () => gBrowser.tabContainer.advanceSelectedTab(-1, true), // left  (Vimium default: J)
  };

  // Commands that fire again on key auto-repeat. With smooth scrolling, a held
  // j/k is handled by the scroll animation itself, like in Vimium.
  const REPEATABLE = new Set(["n", "N", "J", "K"]);
  if (!SMOOTH_SCROLL) REPEATABLE.add("j").add("k");

  // Every unfinished part of a multi-key command, e.g. "g" for "gg".
  const PREFIXES = new Set();
  for (const keys of Object.keys(COMMANDS)) {
    for (let i = 1; i < keys.length; i++) PREFIXES.add(keys.slice(0, i));
  }

  const HTML_NS = "http://www.w3.org/1999/xhtml";
  const LOG_PREFIX = "[vimkeys]";

  // ---- Key handling --------------------------------------------------------
  let pendingKeys = ""; // typed part of a multi-key command, e.g. "g"

  function resolveKeys(keys) {
    if (Object.hasOwn(COMMANDS, keys)) return { keys, command: COMMANDS[keys] };
    if (PREFIXES.has(keys)) return { keys, prefix: true };
    return null;
  }

  function onKeyDown(event) {
    if (hints) {
      hints.onKey(event);
      return;
    }
    if (event.ctrlKey || event.altKey || event.metaKey || event.isComposing) return;

    // Browser dialogs (confirmations, alerts, …) sit on top of any tab, including
    // normal websites where Vimium can't reach them. Only f is handled there;
    // Enter, Escape and Tab keep their usual dialog behaviour.
    const dialogFrame = dialogFrameOf(windowOf(eventTarget(event)));
    if (dialogFrame) {
      pendingKeys = "";
      const doc = dialogFrame.contentDocument;
      const typing = isEditable(eventTarget(event)) || isEditable(deepActiveElement(doc));
      if (event.key === "f" && !typing) {
        consume(event);
        if (!event.repeat) startHints(doc);
      }
      return;
    }

    const isEscape = event.key === "Escape";
    if (!isEscape && event.key.length !== 1) return; // Shift, arrows, F-keys, …

    // Like Vimium: "g" then "g" is gg; "g" then something else drops the "g".
    const match = isEscape
      ? null
      : resolveKeys(pendingKeys + event.key) ?? (pendingKeys ? resolveKeys(event.key) : null);
    const hadPending = pendingKeys !== "";
    pendingKeys = "";
    if (!match && !isEscape) return;

    const ctx = getContext(event);
    if (!ctx) return;

    // "Insert mode": leave typing alone, Escape leaves the field like in Vimium.
    const editable = focusedEditable(ctx);
    if (editable) {
      if (isEscape) {
        consume(event);
        editable.blur();
      }
      return;
    }
    if (isEscape) {
      if (hadPending) consume(event);
      return;
    }

    consume(event);
    if (match.prefix) {
      pendingKeys = match.keys;
      return;
    }
    if (event.repeat && !REPEATABLE.has(match.keys)) return;
    Promise.resolve()
      .then(() => match.command(ctx))
      .catch((err) => console.error(LOG_PREFIX, err));
  }

  function onKeyUp(event) {
    if (scrollAnimation && event.code === scrollAnimation.heldCode) scrollAnimation.held = false;
  }

  // Only act on pages loaded in the parent process. Everything else is
  // Vimium's job, so the two never fight over the same key.
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

  function eventTarget(event) {
    return event.composedTarget ?? event.originalTarget ?? event.target;
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

  // ownerGlobal isn't exposed on every page's nodes, so fall back to the DOM way.
  function windowOf(node) {
    if (!node) return null;
    return node.ownerGlobal ?? node.ownerDocument?.defaultView ?? node.defaultView ??
      (node.window === node ? node : null);
  }

  function consume(event) {
    event.preventDefault();
    event.stopImmediatePropagation();
  }

  const NON_TEXT_INPUTS = new Set([
    "button", "checkbox", "color", "file", "hidden", "image", "radio", "range", "reset", "submit",
  ]);

  function isEditable(el) {
    if (!el || el.nodeType !== 1) return false;
    if (el.isContentEditable) return true;
    if (el.localName === "textarea" || el.localName === "select") return true;
    if (el.localName === "input") return !NON_TEXT_INPUTS.has(el.type);
    return false;
  }

  function deepActiveElement(doc) {
    let el = doc.activeElement;
    while (el?.openOrClosedShadowRoot?.activeElement) {
      el = el.openOrClosedShadowRoot.activeElement;
    }
    return el;
  }

  function focusedEditable({ target, win }) {
    if (isEditable(target)) return target;
    const active = deepActiveElement(win.document);
    return isEditable(active) ? active : null;
  }

  // Walks the DOM including (closed) shadow roots, which about: pages use a lot.
  function* walk(root) {
    for (const el of root.querySelectorAll("*")) {
      yield el;
      const shadow = el.openOrClosedShadowRoot;
      if (shadow) yield* walk(shadow);
    }
  }

  function composedParent(el) {
    return el.assignedSlot ?? el.parentElement ?? el.getRootNode().host ?? null;
  }

  // ---- Find (/, n, N) ------------------------------------------------------
  async function findBarCommand(method, ...args) {
    const findBar = await gBrowser.getFindBar();
    findBar[method](...args);
  }

  // ---- Scrolling (j, k) ----------------------------------------------------
  function canScroll(el) {
    if (el.scrollHeight <= el.clientHeight + 1) return false;
    const { overflowY } = windowOf(el).getComputedStyle(el);
    if (el === el.ownerDocument.scrollingElement) return overflowY !== "hidden" && overflowY !== "clip";
    return overflowY === "auto" || overflowY === "scroll" || overflowY === "overlay";
  }

  // Like Vimium: scroll the container around the focused element, else the
  // page, else the largest scrollable element (many about: pages scroll an
  // inner container instead of the document).
  function findScrollable(doc) {
    const root = doc.scrollingElement ?? doc.documentElement;
    for (let el = deepActiveElement(doc); el && el !== root; el = composedParent(el)) {
      if (canScroll(el)) return el;
    }
    if (canScroll(root)) return root;

    let best = root;
    let bestArea = 0;
    for (const el of walk(doc)) {
      if (!canScroll(el)) continue;
      const { width, height } = el.getBoundingClientRect();
      if (width * height > bestArea) {
        best = el;
        bestArea = width * height;
      }
    }
    return best;
  }

  // Vimium's scroller: a key press scrolls its amount at a constant speed over
  // max(100, 20 * ln(amount)) ms (60px -> 100ms), and keeps going at that
  // speed for as long as the key stays held. Pressing again mid-scroll
  // extends it instead of restarting.
  let scrollAnimation = null;

  function scrollBy({ win, code }, amount) {
    const el = findScrollable(win.document);
    if (!SMOOTH_SCROLL) {
      el.scrollBy({ top: amount, behavior: "instant" });
      return;
    }
    animateScroll(el, amount, code);
  }

  function scrollToEdge({ win }, edge) {
    const el = findScrollable(win.document);
    const target = edge === "top" ? 0 : el.scrollHeight - el.clientHeight;
    const delta = target - el.scrollTop;
    if (Math.abs(delta) < 1) return;
    if (!SMOOTH_SCROLL) {
      el.scrollTo({ top: target, behavior: "instant" });
      return;
    }
    animateScroll(el, delta, null);
  }

  function stopScroll() {
    if (!scrollAnimation) return;
    window.cancelAnimationFrame(scrollAnimation.frame);
    scrollAnimation = null;
  }

  function animateScroll(el, amount, heldCode) {
    const direction = Math.sign(amount);
    const distance = Math.abs(amount);

    const running = scrollAnimation;
    if (running && running.el === el && running.direction === direction) {
      running.remaining += distance;
      running.heldCode = heldCode;
      running.held = heldCode !== null;
      return;
    }
    stopScroll();

    const anim = {
      el,
      direction,
      remaining: distance,
      speed: distance / Math.max(100, 20 * Math.log(distance)), // px per ms
      heldCode,
      held: heldCode !== null,
      lastTime: null,
      carry: 0, // sub-pixel remainder, so slow frames don't lose distance
      frame: 0,
    };
    scrollAnimation = anim;

    const tick = (now) => {
      if (scrollAnimation !== anim) return;
      // Cap the frame time so a stalled frame doesn't cause a jump.
      const elapsed = anim.lastTime === null ? 0 : Math.min(now - anim.lastTime, 50);
      anim.lastTime = now;

      let step = anim.speed * elapsed;
      if (!anim.held) step = Math.min(step, anim.remaining);
      anim.remaining = Math.max(0, anim.remaining - step);
      anim.carry += step;

      const finishing = !anim.held && anim.remaining === 0;
      const px = finishing ? Math.round(anim.carry) : Math.trunc(anim.carry);
      if (px) {
        anim.carry -= px;
        const before = el.scrollTop;
        el.scrollBy({ top: direction * px, behavior: "instant" });
        if (el.scrollTop === before) {
          stopScroll(); // reached the top or bottom
          return;
        }
      }

      if (anim.held || anim.remaining > 0) {
        anim.frame = window.requestAnimationFrame(tick);
      } else {
        scrollAnimation = null;
      }
    };
    anim.frame = window.requestAnimationFrame(tick);
  }

  // ---- Tabs (X) ------------------------------------------------------------
  function restoreTab() {
    if (window.SessionWindowUI?.undoCloseTab) {
      SessionWindowUI.undoCloseTab(window);
    } else if (typeof window.undoCloseTab === "function") {
      window.undoCloseTab();
    } else {
      SessionStore.undoCloseTab(window, 0);
    }
  }

  // ---- Link hints (f) ------------------------------------------------------
  let hints = null;

  const CLICKABLE = [
    "a[href]", "area[href]", "button", "select", "textarea", "summary",
    "input:not([type=hidden])", "[onclick]", "[contenteditable]:not([contenteditable=false])",
    "[tabindex]:not([tabindex='-1'])",
    "[role=button]", "[role=link]", "[role=checkbox]", "[role=radio]", "[role=switch]",
    "[role=tab]", "[role=menuitem]", "[role=option]", "[role=treeitem]",
    // XUL widgets still used on some about: pages
    "checkbox", "radio", "menulist", "toolbarbutton", "richlistitem", "label.text-link",
  ].join(",");

  const HINT_CSS =
    "position:absolute; display:block; box-sizing:border-box; margin:0; padding:1px 3px;" +
    "font:bold 11px/1.2 Helvetica, Arial, sans-serif; color:#302505; white-space:nowrap;" +
    "background:linear-gradient(to bottom, #fff785, #ffc542); border:1px solid #c38a22;" +
    "border-radius:3px; box-shadow:0 3px 7px rgba(0,0,0,.3); pointer-events:none;";
  const TYPED_CSS = "color:#d4ac3a;";

  // Vimium's scheme: prefix-free labels, short ones where possible.
  function makeLabels(count) {
    const labels = [""];
    let offset = 0;
    while (labels.length - offset < count || labels.length === 1) {
      const base = labels[offset++];
      for (const ch of HINT_CHARS) labels.push(ch + base);
    }
    return labels
      .slice(offset, offset + count)
      .sort()
      .map((label) => [...label].reverse().join(""));
  }

  function outermostHost(el) {
    let node = el;
    while (node.getRootNode().host) node = node.getRootNode().host;
    return node;
  }

  function isOccluded(el, rect) {
    const x = rect.left + rect.width / 2;
    const y = rect.top + rect.height / 2;
    const hit = el.ownerDocument.elementFromPoint(x, y);
    if (!hit) return true;
    const host = outermostHost(el);
    return !(hit === host || host.contains(hit));
  }

  function visibleRect(el) {
    const win = windowOf(el);
    if (el.checkVisibility && !el.checkVisibility({ checkVisibilityCSS: true, visibilityProperty: true })) {
      return null;
    }
    for (const rect of el.getClientRects()) {
      if (rect.width < 3 || rect.height < 3) continue;
      if (rect.bottom <= 0 || rect.right <= 0 || rect.top >= win.innerHeight || rect.left >= win.innerWidth) continue;
      if (isOccluded(el, rect)) continue;
      return rect;
    }
    return null;
  }

  function frameDocument(el) {
    try {
      return el.contentDocument ?? null;
    } catch {
      return null;
    }
  }

  function collectTargets(doc, offsetX, offsetY, out, seen) {
    for (const el of walk(doc)) {
      if (el.localName === "iframe" || el.localName === "frame" || el.localName === "browser") {
        const sub = frameDocument(el);
        const r = el.getBoundingClientRect();
        if (sub && r.width > 0 && r.height > 0) {
          collectTargets(sub, offsetX + r.left + el.clientLeft, offsetY + r.top + el.clientTop, out, seen);
        }
        continue;
      }
      if (el.disabled || !el.matches(CLICKABLE)) continue;
      const rect = visibleRect(el);
      if (!rect) continue;
      const x = offsetX + rect.left;
      const y = offsetY + rect.top;
      const key = `${Math.round(x)},${Math.round(y)},${Math.round(rect.width)},${Math.round(rect.height)}`;
      if (seen.has(key)) continue; // custom elements often wrap a same-sized inner button
      seen.add(key);
      out.push({ el, x, y });
    }
  }

  function mountOverlay(doc) {
    const container = doc.createElementNS(HTML_NS, "div");
    container.style.cssText =
      "all:initial; position:fixed; inset:0; width:100%; height:100%; margin:0; padding:0;" +
      "border:0; background:transparent; overflow:visible; pointer-events:none; z-index:2147483647;";
    doc.documentElement.append(container);
    // The top layer keeps hints above modal dialogs; harmless if unsupported.
    try {
      container.popover = "manual";
      container.showPopover();
    } catch {
      container.removeAttribute("popover");
    }
    return container;
  }

  function startHints(doc) {
    const win = doc.defaultView;
    const targets = [];
    collectTargets(doc, 0, 0, targets, new Set());
    if (!targets.length) return;

    const container = mountOverlay(doc);
    const shadow = container.attachShadow({ mode: "closed" });
    const labels = makeLabels(targets.length);

    const items = targets.map(({ el, x, y }, i) => {
      const node = doc.createElementNS(HTML_NS, "span");
      node.style.cssText = HINT_CSS +
        `left:${Math.max(0, Math.min(x, win.innerWidth - 20))}px;` +
        `top:${Math.max(0, Math.min(y, win.innerHeight - 14))}px;`;
      const typedNode = doc.createElementNS(HTML_NS, "span");
      typedNode.style.cssText = TYPED_CSS;
      const restNode = doc.createTextNode(labels[i].toUpperCase());
      node.append(typedNode, restNode);
      shadow.append(node);
      return { el, label: labels[i], node, typedNode, restNode };
    });

    let typed = "";
    const listenerOpts = { capture: true };

    const update = () => {
      for (const item of items) {
        const match = item.label.startsWith(typed);
        item.node.style.display = match ? "block" : "none";
        if (match) {
          item.typedNode.textContent = typed.toUpperCase();
          item.restNode.data = item.label.slice(typed.length).toUpperCase();
        }
      }
    };

    const exit = () => {
      if (hints !== state) return;
      hints = null;
      container.remove();
      gBrowser.tabContainer.removeEventListener("TabSelect", exit);
      window.removeEventListener("mousedown", exit, listenerOpts);
      win.removeEventListener("scroll", exit, listenerOpts);
      win.removeEventListener("pagehide", exit);
    };

    const state = {
      onKey(event) {
        if (!container.isConnected) {
          // Its document went away, e.g. the dialog was closed some other way.
          exit();
          onKeyDown(event);
          return;
        }
        if (event.ctrlKey || event.altKey || event.metaKey) {
          exit();
          return;
        }
        if (event.key === "Shift" || event.key === "CapsLock") return;
        consume(event);

        if (event.key === "Escape") {
          exit();
          return;
        }
        if (event.key === "Backspace") {
          typed = typed.slice(0, -1);
          update();
          return;
        }
        const ch = event.key.toLowerCase();
        if (ch.length !== 1 || !HINT_CHARS.includes(ch)) return;

        const matches = items.filter((item) => item.label.startsWith(typed + ch));
        if (!matches.length) return;
        typed += ch;
        if (matches.length === 1) {
          exit();
          activate(matches[0].el);
          return;
        }
        update();
      },
    };

    hints = state;
    gBrowser.tabContainer.addEventListener("TabSelect", exit);
    window.addEventListener("mousedown", exit, listenerOpts);
    win.addEventListener("scroll", exit, listenerOpts);
    win.addEventListener("pagehide", exit);
  }

  function activate(el) {
    if (el.localName === "select") {
      el.focus();
      try {
        el.showPicker();
      } catch {
        // showPicker isn't allowed everywhere; focus alone is fine
      }
      return;
    }
    if (el.localName === "menulist") {
      el.focus();
      el.open = true;
      return;
    }
    if (isEditable(el)) {
      el.focus();
      return;
    }
    el.focus?.({ preventScroll: true });
    el.click();
  }

  // ---- Startup -------------------------------------------------------------
  function init() {
    window.addEventListener("keydown", onKeyDown, true);
    window.addEventListener("keyup", onKeyUp, true);
    // Never keep scrolling if the key-up gets lost, e.g. after an Alt+Tab.
    window.addEventListener("blur", () => {
      if (scrollAnimation) scrollAnimation.held = false;
      pendingKeys = "";
    });
    gBrowser.tabContainer.addEventListener("TabSelect", () => {
      stopScroll();
      pendingKeys = "";
    });
  }

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
