import {
  HELP,
  isRepeatable,
  keysFor,
  resolveKeys,
} from "chrome://userscripts/content/bindings.sys.mjs";

export const SETTINGS = {
  hintChars: "sadfjklewcmpgh",
  scrollStep: 60,
  smoothScroll: true,
};

const HTML_NS = "http://www.w3.org/1999/xhtml";
const LOG_PREFIX = "[vimkeys]";

export const session = { pageActorRegistered: false };

export function eventTarget(event) {
  return event.composedTarget ?? event.originalTarget ?? event.target;
}

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

function insertTarget(doc) {
  if (!doc) return null;
  const active = deepActiveElement(doc);
  return isEditable(active) ? active : null;
}

function focusedEditable({ target, win }) {
  if (isEditable(target)) return target;
  return insertTarget(win.document);
}

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

export class KeyHandler {
  #pending = "";
  #hints = null;
  #help = null;
  #visual = null;
  #mode = null;
  #scroller = new Scroller();

  constructor({ hintDocument, runBrowserCommand, onModeChange = null }) {
    this.hintDocument = hintDocument;
    this.runBrowserCommand = runBrowserCommand;
    this.onModeChange = onModeChange;
  }

  #setMode(mode, force = false) {
    if (mode === this.#mode && !force) return;
    this.#mode = mode;
    this.onModeChange?.(mode);
  }

  refreshMode(force = false) {
    const doc = this.hintDocument({});
    let mode = null;
    if (this.#visual) {
      mode = "visual";
    } else if (doc?.hasFocus?.() && insertTarget(doc)) {
      mode = "insert";
    }
    this.#setMode(mode, force);
  }

  handleHintKey(event) {
    const hints = this.#hints;
    if (!hints) return false;
    if (!hints.alive) {
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

  handleVisualKey(event) {
    const visual = this.#visual;
    if (!visual) return false;
    if (!visual.alive) {
      visual.exit();
      return false;
    }
    visual.onKey(event);
    return true;
  }

  onKeyDown(event, ctx) {
    if (this.handleHelpKey(event)) return;
    if (this.handleHintKey(event)) return;
    if (this.handleVisualKey(event)) return;
    if (event.ctrlKey || event.altKey || event.metaKey || event.isComposing) return;

    const isEscape = event.key === "Escape";
    if (!isEscape && event.key.length !== 1) return;

    const match = isEscape
      ? null
      : resolveKeys(this.#pending + event.key) ?? (this.#pending ? resolveKeys(event.key) : null);
    const hadPending = this.#pending !== "";
    this.#pending = "";
    if (!match && !isEscape) return;

    const editable = focusedEditable(ctx);
    if (editable) {
      if (isEscape) {
        consume(event);
        editable.blur();
        this.refreshMode();
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
    if (event.repeat && !isRepeatable(match.command, SETTINGS.smoothScroll)) return;
    Promise.resolve()
      .then(() => this.#run(match.command, ctx))
      .catch((err) => console.error(LOG_PREFIX, err));
  }

  onKeyUp(event) {
    this.#scroller.release(event.code);
  }

  onBlur() {
    this.#scroller.release();
    this.#pending = "";
  }

  stop() {
    this.#scroller.stop();
    this.#pending = "";
    this.exitHints();
    this.exitHelp();
    this.exitVisual();
    this.#setMode(null);
  }

  exitHints() {
    this.#hints?.exit();
  }

  startHints(doc, newTab = false) {
    this.exitHints();
    this.#hints = startHints(doc, () => {
      this.#hints = null;
    }, newTab);
  }

  exitHelp() {
    this.#help?.exit();
  }

  exitVisual() {
    this.#visual?.exit();
  }

  startVisual(doc) {
    this.exitVisual();
    this.#visual = startVisual(doc, () => {
      this.#visual = null;
      this.refreshMode();
    });
    this.refreshMode();
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
      case "linkHintsNewTab": {
        const doc = this.hintDocument(ctx);
        if (doc) this.startHints(doc, true);
        return undefined;
      }
      case "visualMode": {
        const doc = this.hintDocument(ctx);
        if (doc) this.startVisual(doc);
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

function canScroll(el) {
  if (el.scrollHeight <= el.clientHeight + 1) return false;
  const { overflowY } = windowOf(el).getComputedStyle(el);
  if (el === el.ownerDocument.scrollingElement) return overflowY !== "hidden" && overflowY !== "clip";
  return overflowY === "auto" || overflowY === "scroll" || overflowY === "overlay";
}

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
      speed: distance / Math.max(100, 20 * Math.log(distance)),
      heldCode,
      held: heldCode !== null,
      lastTime: null,
      carry: 0,
      frame: 0,
    };
    this.#animation = anim;

    const tick = (now) => {
      if (this.#animation !== anim) return;
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
          this.stop();
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

const CLICKABLE = [
  "a[href]", "area[href]", "button", "select", "textarea", "summary",
  "input:not([type=hidden])", "[onclick]", "[contenteditable]:not([contenteditable=false])",
  "[tabindex]:not([tabindex='-1'])",
  "[role=button]", "[role=link]", "[role=checkbox]", "[role=radio]", "[role=switch]",
  "[role=tab]", "[role=menuitem]", "[role=option]", "[role=treeitem]",
  "checkbox", "radio", "menulist", "toolbarbutton", "richlistitem", "label.text-link",
].join(",");

const HINT_CSS =
  "position:absolute; display:block; box-sizing:border-box; margin:0; padding:1px 3px;" +
  "font:bold 11px/1.2 Helvetica, Arial, sans-serif; color:#302505; white-space:nowrap;" +
  "background:linear-gradient(to bottom, #fff785, #ffc542); border:1px solid #c38a22;" +
  "border-radius:3px; box-shadow:0 3px 7px rgba(0,0,0,.3); pointer-events:none;";
const TYPED_CSS = "color:#d4ac3a;";

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
    if (seen.has(key)) continue;
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
  try {
    container.popover = "manual";
    container.showPopover();
  } catch {
    container.removeAttribute("popover");
  }
  return container;
}

function linkHrefOf(el) {
  if (el.localName !== "a" && el.localName !== "area") return null;
  const attr = el.getAttribute("href");
  if (!attr || attr.startsWith("#")) return null;
  return el.href || null;
}

function activate(el, newTab) {
  if (newTab && linkHrefOf(el)) {
    const win = windowOf(el);
    el.dispatchEvent(new win.MouseEvent("click", {
      bubbles: true,
      cancelable: true,
      view: win,
      ctrlKey: true,
    }));
    return;
  }
  if (el.localName === "select") {
    el.focus();
    try {
      el.showPicker();
    } catch {
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

function startHints(doc, onExit, newTab = false) {
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
        activate(matches[0].el, newTab);
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

const SHOW_TEXT = 0x4;
const MIN_ANCHOR_TEXT = 50;

const VISUAL_MOVEMENTS = {
  h: ["backward", "character"],
  l: ["forward", "character"],
  k: ["backward", "line"],
  j: ["forward", "line"],
};

const VISUAL_IGNORED_KEYS = new Set(["Shift", "Control", "Alt", "Meta", "CapsLock"]);

function firstTextAnchor(doc) {
  const root = doc.body ?? doc.documentElement;
  if (!root) return null;
  const walker = doc.createTreeWalker(root, SHOW_TEXT);
  let fallback = null;
  for (let node = walker.nextNode(); node; node = walker.nextNode()) {
    const text = node.data;
    const trimmed = text.trim();
    if (!trimmed) continue;
    const element = node.parentElement;
    if (!element || isEditable(element) || !visibleRect(element)) continue;
    const range = doc.createRange();
    const offset = text.length - text.replace(/^\s+/, "").length;
    range.setStart(node, offset);
    range.setEnd(node, offset);
    if (trimmed.length >= MIN_ANCHOR_TEXT) return range;
    fallback ??= range;
  }
  return fallback;
}

function collapseSelection(selection) {
  try {
    selection.removeAllRanges();
  } catch (err) {
    console.error(LOG_PREFIX, err);
  }
}

function copySelection(selection) {
  let text;
  try {
    text = selection.toString();
  } catch (err) {
    console.error(LOG_PREFIX, err);
    return;
  }
  if (!text) return;
  try {
    Cc["@mozilla.org/widget/clipboardhelper;1"]
      .getService(Ci.nsIClipboardHelper)
      .copyString(text);
  } catch (err) {
    console.error(LOG_PREFIX, err);
  }
}

function startVisual(doc, onExit) {
  const win = doc.defaultView;
  const selection = win?.getSelection();
  if (!selection) return null;

  if (!selection.rangeCount || selection.isCollapsed) {
    const range = firstTextAnchor(doc);
    if (!range) return null;
    selection.removeAllRanges();
    selection.addRange(range);
  }

  let done = false;

  const onVisibility = () => {
    if (doc.hidden) exit();
  };

  function exit() {
    if (done) return;
    done = true;
    win.removeEventListener("pagehide", exit);
    doc.removeEventListener("visibilitychange", onVisibility);
    onExit();
  }

  win.addEventListener("pagehide", exit);
  doc.addEventListener("visibilitychange", onVisibility);

  return {
    get alive() {
      return !done;
    },
    exit,
    onKey(event) {
      if (VISUAL_IGNORED_KEYS.has(event.key)) return;
      if (event.ctrlKey || event.altKey || event.metaKey) {
        exit();
        return;
      }
      consume(event);

      const key = event.key;
      if (key === "Escape" || key === "v") {
        collapseSelection(selection);
        exit();
        return;
      }
      if (key === "y") {
        copySelection(selection);
        collapseSelection(selection);
        exit();
        return;
      }

      const movement = VISUAL_MOVEMENTS[key];
      if (!movement) return;
      try {
        selection.modify("extend", movement[0], movement[1]);
      } catch (err) {
        console.error(LOG_PREFIX, err);
      }
    },
  };
}
