// vimkeys core: everything that happens inside a page (keys, link hints,
// scrolling) plus the settings and key bindings. Shared by vimkeys.uc.js
// (about: pages, browser dialogs) and the VimkeysActor child (every page where
// Vimium can't run), so there is exactly one place to change any of it.

// ---- Settings (same meaning as Vimium's options) ---------------------------
export const SETTINGS = {
  hintChars: "sadfjklewcmpgh", // "Characters used for link hints"
  scrollStep: 60,              // "Scroll step size" in px
  smoothScroll: true,          // "Use smooth scrolling"
  // vimkeys steps aside wherever this extension (Vimium-FF) can run.
  vimiumId: "{d7742d87-e61d-4b78-b8a1-b469842139fa}",
};

// ---- Key bindings ----------------------------------------------------------
// Keys -> command names. Page commands run right here; the rest are browser
// commands that each side carries out its own way (see runBrowserCommand).
export const BINDINGS = {
  "/": "find",
  n: "findNext",
  N: "findPrevious",
  f: "linkHints",
  j: "scrollDown",
  k: "scrollUp",
  gg: "scrollToTop",
  G: "scrollToBottom",
  o: "openOmnibar",
  O: "openOmnibarNewTab",
  b: "openOmnibarBookmarks",
  B: "openOmnibarBookmarksNewTab",
  T: "openOmnibarTabs",
  t: "newTab",
  x: "closeTab",
  X: "restoreTab",
  H: "goBack",
  L: "goForward",
  J: "nextTab",     // right (Vimium default: K)
  K: "previousTab", // left  (Vimium default: J)
  "?": "showHelp",
};

const HELP = [
  ["Navigating the page", [
    ["linkHints", "Open a link in the current tab"],
    ["scrollDown", "Scroll down"],
    ["scrollUp", "Scroll up"],
    ["scrollToTop", "Scroll to the top of the page"],
    ["scrollToBottom", "Scroll to the bottom of the page"],
  ]],
  ["Using find", [
    ["find", "Enter find mode"],
    ["findNext", "Cycle forward to the next find match"],
    ["findPrevious", "Cycle backward to the previous find match"],
  ]],
  ["Navigating history", [
    ["goBack", "Go back in history"],
    ["goForward", "Go forward in history"],
  ]],
  ["Opening pages", [
    ["openOmnibar", "Open a URL, bookmark or history entry"],
    ["openOmnibarNewTab", "Open a URL, bookmark or history entry in a new tab"],
    ["openOmnibarBookmarks", "Open a bookmark"],
    ["openOmnibarBookmarksNewTab", "Open a bookmark in a new tab"],
  ]],
  ["Manipulating tabs", [
    ["newTab", "Create a new tab"],
    ["closeTab", "Close the current tab"],
    ["restoreTab", "Restore a closed tab"],
    ["nextTab", "Go one tab right"],
    ["previousTab", "Go one tab left"],
    ["openOmnibarTabs", "Search through your open tabs"],
  ]],
  ["Miscellaneous", [
    ["showHelp", "Show this help"],
  ]],
];

function keysFor(command) {
  return Object.keys(BINDINGS).filter((keys) => BINDINGS[keys] === command);
}

export const BROWSER_COMMANDS = new Set([
  "find", "findNext", "findPrevious", "newTab", "closeTab", "restoreTab",
  "goBack", "goForward", "nextTab", "previousTab",
  "openOmnibar", "openOmnibarNewTab", "openOmnibarBookmarks",
  "openOmnibarBookmarksNewTab", "openOmnibarTabs",
]);

// Commands that fire again on key auto-repeat. With smooth scrolling, a held
// j/k is handled by the scroll animation itself, like in Vimium.
const REPEATABLE = new Set(["findNext", "findPrevious", "nextTab", "previousTab"]);
if (!SETTINGS.smoothScroll) REPEATABLE.add("scrollDown").add("scrollUp");

// Every unfinished part of a multi-key binding, e.g. "g" for "gg".
const PREFIXES = new Set();
for (const keys of Object.keys(BINDINGS)) {
  for (let i = 1; i < keys.length; i++) PREFIXES.add(keys.slice(0, i));
}

function resolveKeys(keys) {
  if (Object.hasOwn(BINDINGS, keys)) return { keys, command: BINDINGS[keys] };
  if (PREFIXES.has(keys)) return { keys, prefix: true };
  return null;
}

const HTML_NS = "http://www.w3.org/1999/xhtml";
const LOG_PREFIX = "[vimkeys]";

// Per-session state shared by every browser window (a module is loaded once
// per process, while vimkeys.uc.js runs once per window).
export const session = { pageActorRegistered: false };

// ---- DOM helpers -----------------------------------------------------------
export function eventTarget(event) {
  return event.composedTarget ?? event.originalTarget ?? event.target;
}

// ownerGlobal isn't exposed on every page's nodes, so fall back to the DOM way.
export function windowOf(node) {
  if (!node) return null;
  return node.ownerGlobal ?? node.ownerDocument?.defaultView ?? node.defaultView ??
    (node.window === node ? node : null);
}

export function consume(event) {
  event.preventDefault();
  event.stopImmediatePropagation();
}

const NON_TEXT_INPUTS = new Set([
  "button", "checkbox", "color", "file", "hidden", "image", "radio", "range", "reset", "submit",
]);

export function isEditable(el) {
  if (!el || el.nodeType !== 1) return false;
  if (el.isContentEditable) return true;
  if (el.localName === "textarea" || el.localName === "select") return true;
  if (el.localName === "input") return !NON_TEXT_INPUTS.has(el.type);
  return false;
}

export function deepActiveElement(doc) {
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

// ---- Key handling ----------------------------------------------------------
// One KeyHandler per place that receives keys (a browser window, a file page).
//   hintDocument(ctx)            -> the document f puts its hints in
//   runBrowserCommand(name, ctx) -> carries out tab/find/history commands
// ctx is { win, target, code, ... }: the window the key came from, the event
// target and the physical key (for detecting key-up while scrolling).
export class KeyHandler {
  #pending = ""; // typed part of a multi-key binding, e.g. "g"
  #hints = null;
  #help = null;
  #scroller = new Scroller();

  constructor({ hintDocument, runBrowserCommand }) {
    this.hintDocument = hintDocument;
    this.runBrowserCommand = runBrowserCommand;
  }

  // Returns true if hint mode took the key.
  handleHintKey(event) {
    const hints = this.#hints;
    if (!hints) return false;
    if (!hints.alive) {
      // Its document went away, e.g. a dialog was closed some other way.
      hints.exit();
      return false;
    }
    hints.onKey(event);
    return true;
  }

  handleHelpKey(event) {
    const help = this.#help;
    if (!help) return false;
    if (!help.alive) {
      help.exit();
      return false;
    }
    help.onKey(event);
    return true;
  }

  onKeyDown(event, ctx) {
    if (this.handleHelpKey(event)) return;
    if (this.handleHintKey(event)) return;
    if (event.ctrlKey || event.altKey || event.metaKey || event.isComposing) return;

    const isEscape = event.key === "Escape";
    if (!isEscape && event.key.length !== 1) return; // Shift, arrows, F-keys, …

    // Like Vimium: "g" then "g" is gg; "g" then something else drops the "g".
    const match = isEscape
      ? null
      : resolveKeys(this.#pending + event.key) ?? (this.#pending ? resolveKeys(event.key) : null);
    const hadPending = this.#pending !== "";
    this.#pending = "";
    if (!match && !isEscape) return;

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
      this.#pending = match.keys;
      return;
    }
    if (event.repeat && !REPEATABLE.has(match.command)) return;
    Promise.resolve()
      .then(() => this.#run(match.command, ctx))
      .catch((err) => console.error(LOG_PREFIX, err));
  }

  onKeyUp(event) {
    this.#scroller.release(event.code);
  }

  // Window lost focus: key-ups may never arrive, so stop following held keys.
  onBlur() {
    this.#scroller.release();
    this.#pending = "";
  }

  // Tab switched away or page going away: stop everything.
  stop() {
    this.#scroller.stop();
    this.#pending = "";
    this.exitHints();
    this.exitHelp();
  }

  exitHints() {
    this.#hints?.exit();
  }

  startHints(doc) {
    this.exitHints();
    this.#hints = startHints(doc, () => {
      this.#hints = null;
    });
  }

  exitHelp() {
    this.#help?.exit();
  }

  startHelp(doc) {
    this.exitHelp();
    this.exitHints();
    this.#help = startHelp(doc, () => {
      this.#help = null;
    });
  }

  #run(name, ctx) {
    switch (name) {
      case "linkHints": {
        const doc = this.hintDocument(ctx);
        if (doc) this.startHints(doc);
        return undefined;
      }
      case "showHelp": {
        const doc = this.hintDocument(ctx);
        if (doc) this.startHelp(doc);
        return undefined;
      }
      case "scrollDown":
        return this.#scroller.scrollBy(ctx.win, SETTINGS.scrollStep, ctx.code);
      case "scrollUp":
        return this.#scroller.scrollBy(ctx.win, -SETTINGS.scrollStep, ctx.code);
      case "scrollToTop":
        return this.#scroller.scrollToEdge(ctx.win, "top");
      case "scrollToBottom":
        return this.#scroller.scrollToEdge(ctx.win, "bottom");
      default:
        return this.runBrowserCommand(name, ctx);
    }
  }
}

// ---- Scrolling -------------------------------------------------------------
function canScroll(el) {
  if (el.scrollHeight <= el.clientHeight + 1) return false;
  const { overflowY } = windowOf(el).getComputedStyle(el);
  if (el === el.ownerDocument.scrollingElement) return overflowY !== "hidden" && overflowY !== "clip";
  return overflowY === "auto" || overflowY === "scroll" || overflowY === "overlay";
}

// Like Vimium: scroll the container around the focused element, else the
// page, else the largest scrollable element (many about: pages and the PDF
// viewer scroll an inner container instead of the document).
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
// speed for as long as the key stays held. Pressing again mid-scroll extends
// it instead of restarting.
class Scroller {
  #animation = null;

  scrollBy(win, amount, heldCode) {
    const el = findScrollable(win.document);
    if (!SETTINGS.smoothScroll) {
      el.scrollBy({ top: amount, behavior: "instant" });
      return;
    }
    this.#animate(el, amount, heldCode);
  }

  scrollToEdge(win, edge) {
    const el = findScrollable(win.document);
    const target = edge === "top" ? 0 : el.scrollHeight - el.clientHeight;
    const delta = target - el.scrollTop;
    if (Math.abs(delta) < 1) return;
    if (!SETTINGS.smoothScroll) {
      el.scrollTo({ top: target, behavior: "instant" });
      return;
    }
    this.#animate(el, delta, null);
  }

  // A key went up; with no code given, treat every held key as released.
  release(code) {
    const anim = this.#animation;
    if (anim && (code === undefined || code === anim.heldCode)) anim.held = false;
  }

  stop() {
    const anim = this.#animation;
    if (!anim) return;
    anim.win.cancelAnimationFrame(anim.frame);
    this.#animation = null;
  }

  #animate(el, amount, heldCode) {
    const direction = Math.sign(amount);
    const distance = Math.abs(amount);

    const running = this.#animation;
    if (running && running.el === el && running.direction === direction) {
      running.remaining += distance;
      running.heldCode = heldCode;
      running.held = heldCode !== null;
      return;
    }
    this.stop();

    const win = windowOf(el);
    const anim = {
      el,
      win,
      direction,
      remaining: distance,
      speed: distance / Math.max(100, 20 * Math.log(distance)), // px per ms
      heldCode,
      held: heldCode !== null,
      lastTime: null,
      carry: 0, // sub-pixel remainder, so slow frames don't lose distance
      frame: 0,
    };
    this.#animation = anim;

    const tick = (now) => {
      if (this.#animation !== anim) return;
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
          this.stop(); // reached the top or bottom
          return;
        }
      }

      if (anim.held || anim.remaining > 0) {
        anim.frame = win.requestAnimationFrame(tick);
      } else {
        this.#animation = null;
      }
    };
    anim.frame = win.requestAnimationFrame(tick);
  }
}

// ---- Link hints ------------------------------------------------------------
const CLICKABLE = [
  "a[href]", "area[href]", "button", "select", "textarea", "summary",
  "input:not([type=hidden])", "[onclick]", "[contenteditable]:not([contenteditable=false])",
  "[tabindex]:not([tabindex='-1'])",
  "[role=button]", "[role=link]", "[role=checkbox]", "[role=radio]", "[role=switch]",
  "[role=tab]", "[role=menuitem]", "[role=option]", "[role=treeitem]",
  // XUL widgets still used on some about: pages and in dialogs
  "checkbox", "radio", "menulist", "toolbarbutton", "richlistitem", "label.text-link",
].join(",");

const HINT_CSS =
  "position:absolute; display:block; box-sizing:border-box; margin:0; padding:1px 3px;" +
  "font:bold 11px/1.2 Helvetica, Arial, sans-serif; color:#302505; white-space:nowrap;" +
  "background:linear-gradient(to bottom, #fff785, #ffc542); border:1px solid #c38a22;" +
  "border-radius:3px; box-shadow:0 3px 7px rgba(0,0,0,.3); pointer-events:none;";
const TYPED_CSS = "color:#d4ac3a;";

// Vimium's scheme: prefix-free labels, short ones where possible.
export function makeLabels(count) {
  const labels = [""];
  let offset = 0;
  while (labels.length - offset < count || labels.length === 1) {
    const base = labels[offset++];
    for (const ch of SETTINGS.hintChars) labels.push(ch + base);
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

// Shows hints in doc. Returns null if there is nothing to click. onExit runs
// once, however hint mode ends.
function startHints(doc, onExit) {
  const win = doc.defaultView;
  const targets = [];
  collectTargets(doc, 0, 0, targets, new Set());
  if (!targets.length) return null;

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
  let done = false;
  const capture = { capture: true };

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

  const onVisibility = () => {
    if (doc.hidden) exit();
  };

  function exit() {
    if (done) return;
    done = true;
    container.remove();
    win.removeEventListener("mousedown", exit, capture);
    win.removeEventListener("scroll", exit, capture);
    win.removeEventListener("pagehide", exit);
    doc.removeEventListener("visibilitychange", onVisibility);
    onExit();
  }

  win.addEventListener("mousedown", exit, capture);
  win.addEventListener("scroll", exit, capture);
  win.addEventListener("pagehide", exit);
  doc.addEventListener("visibilitychange", onVisibility);

  return {
    get alive() {
      return !done && container.isConnected;
    },
    exit,
    onKey(event) {
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
      if (ch.length !== 1 || !SETTINGS.hintChars.includes(ch)) return;

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
}

const HELP_BACKDROP_CSS =
  "position:absolute; inset:0; display:flex; align-items:center; justify-content:center;" +
  "background:rgba(0,0,0,.45);";
const HELP_PANEL_CSS =
  "box-sizing:border-box; max-width:min(640px, 92vw); max-height:84vh; overflow:auto;" +
  "margin:0; padding:18px 22px; border:1px solid #c38a22; border-radius:8px;" +
  "background:linear-gradient(to bottom, #fffdf3, #fff6d9); color:#302505;" +
  "font:13px/1.5 Helvetica, Arial, sans-serif; box-shadow:0 8px 28px rgba(0,0,0,.45);";
const HELP_TITLE_CSS = "margin:0 0 4px; font-weight:bold; font-size:15px;";
const HELP_GRID_CSS =
  "display:grid; grid-template-columns:max-content 1fr; gap:3px 14px; align-items:baseline;";
const HELP_GROUP_CSS =
  "grid-column:1 / -1; margin:12px 0 2px; font-weight:bold; font-size:11px;" +
  "text-transform:uppercase; letter-spacing:.08em; color:#8a6a1f;";
const HELP_KEY_CSS =
  "justify-self:end; font-family:ui-monospace, Menlo, Consolas, monospace;" +
  "font-weight:bold; white-space:nowrap; color:#7a4f00;";
const HELP_DESC_CSS = "color:#302505;";

const HELP_IGNORED_KEYS = new Set(["Shift", "Control", "Alt", "Meta", "CapsLock"]);

function startHelp(doc, onExit) {
  const win = doc.defaultView;
  const container = mountOverlay(doc);
  const shadow = container.attachShadow({ mode: "closed" });

  const backdrop = doc.createElementNS(HTML_NS, "div");
  backdrop.style.cssText = HELP_BACKDROP_CSS;
  const panel = doc.createElementNS(HTML_NS, "div");
  panel.style.cssText = HELP_PANEL_CSS;

  const title = doc.createElementNS(HTML_NS, "div");
  title.style.cssText = HELP_TITLE_CSS;
  title.textContent = "vimkeys";
  panel.append(title);

  const grid = doc.createElementNS(HTML_NS, "div");
  grid.style.cssText = HELP_GRID_CSS;
  for (const [group, commands] of HELP) {
    const rows = commands
      .map(([command, description]) => [keysFor(command), description])
      .filter(([keys]) => keys.length);
    if (!rows.length) continue;

    const heading = doc.createElementNS(HTML_NS, "div");
    heading.style.cssText = HELP_GROUP_CSS;
    heading.textContent = group;
    grid.append(heading);

    for (const [keys, description] of rows) {
      const keyCell = doc.createElementNS(HTML_NS, "div");
      keyCell.style.cssText = HELP_KEY_CSS;
      keyCell.textContent = keys.join(", ");
      const descCell = doc.createElementNS(HTML_NS, "div");
      descCell.style.cssText = HELP_DESC_CSS;
      descCell.textContent = description;
      grid.append(keyCell, descCell);
    }
  }
  panel.append(grid);
  backdrop.append(panel);
  shadow.append(backdrop);

  let done = false;
  const capture = { capture: true };

  const onVisibility = () => {
    if (doc.hidden) exit();
  };

  function exit() {
    if (done) return;
    done = true;
    container.remove();
    win.removeEventListener("mousedown", exit, capture);
    win.removeEventListener("pagehide", exit);
    doc.removeEventListener("visibilitychange", onVisibility);
    onExit();
  }

  win.addEventListener("mousedown", exit, capture);
  win.addEventListener("pagehide", exit);
  doc.addEventListener("visibilitychange", onVisibility);

  return {
    get alive() {
      return !done && container.isConnected;
    },
    exit,
    onKey(event) {
      if (HELP_IGNORED_KEYS.has(event.key)) return;
      if (!event.ctrlKey && !event.altKey && !event.metaKey) consume(event);
      exit();
    },
  };
}
