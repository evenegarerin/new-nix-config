const lazy = {};

ChromeUtils.defineESModuleGetters(lazy, {
  PrivateBrowsingUtils: "resource://gre/modules/PrivateBrowsingUtils.sys.mjs",
  ProvidersManager: "moz-src:///browser/components/urlbar/UrlbarProvidersManager.sys.mjs",
  UrlbarQueryContext: "chrome://browser/content/urlbar/UrlbarQueryContext.mjs",
  UrlbarShared: "chrome://browser/content/urlbar/UrlbarShared.mjs",
  UrlbarUtils: "moz-src:///browser/components/urlbar/UrlbarUtils.sys.mjs",
});

const HTML_NS = "http://www.w3.org/1999/xhtml";
const LOG_PREFIX = "[omnibar]";
const SAP_NAME = "urlbar";
const PANEL_ID = "omnibar";
const MAX_RESULTS = 12;
const MENU_MAX_RESULTS = 20;
const PANEL_WIDTH = 640;
const PANEL_TOP = 72;
const DEFAULT_FAVICON = "chrome://global/skin/icons/defaultFavicon.svg";
const BLOCKED_SCHEMES = ["javascript:", "data:"];

const BOX_CSS =
  "display:flex; flex-direction:column; box-sizing:border-box; gap:8px;" +
  `width:${PANEL_WIDTH}px; max-width:90vw; padding:10px;` +
  "font:14px/1.4 system-ui, sans-serif;";
const PROMPT_CSS =
  "padding:0 2px; font-size:12px; letter-spacing:.03em; opacity:.7;";
const INPUT_CSS =
  "box-sizing:border-box; width:100%; padding:8px 10px; border-radius:6px;" +
  "border:1px solid color-mix(in srgb, currentColor 25%, transparent);" +
  "background:color-mix(in srgb, currentColor 8%, transparent);" +
  "color:inherit; font:inherit; outline:none;";
const LIST_CSS = "display:flex; flex-direction:column; gap:1px;";
const ROW_CSS =
  "display:flex; align-items:center; gap:8px; padding:5px 8px; border-radius:5px;" +
  "white-space:nowrap; overflow:hidden; cursor:default;";
const ROW_SELECTED_CSS = "background:color-mix(in srgb, currentColor 16%, transparent);";
const ICON_CSS =
  "flex:0 0 auto; width:16px; height:16px; -moz-context-properties:fill; fill:currentColor;";
const TITLE_CSS = "flex:0 1 auto; overflow:hidden; text-overflow:ellipsis;";
const KIND_CSS =
  "flex:0 0 auto; font-size:11px; text-transform:uppercase; letter-spacing:.06em; opacity:.55;";
const URL_CSS =
  "flex:1 1 auto; overflow:hidden; text-overflow:ellipsis; opacity:.6; font-size:12px;";
const EMPTY_CSS = "padding:6px 8px; opacity:.6;";

export const OMNIBAR_SOURCES = {
  bookmarks: () => [lazy.UrlbarShared.RESULT_SOURCE.BOOKMARKS],
  tabs: () => [lazy.UrlbarShared.RESULT_SOURCE.TABS],
};

function isUsable(result) {
  const types = lazy.UrlbarShared.RESULT_TYPE;
  return (
    result.type === types.TAB_SWITCH ||
    result.type === types.SEARCH ||
    result.type === types.URL ||
    result.type === types.KEYWORD ||
    result.type === types.REMOTE_TAB
  );
}

function kindOf(result) {
  const sources = lazy.UrlbarShared.RESULT_SOURCE;
  switch (result.source) {
    case sources.BOOKMARKS:
      return "bookmark";
    case sources.HISTORY:
      return "history";
    case sources.TABS:
      return "tab";
    case sources.SEARCH:
      return "search";
    default:
      return "";
  }
}

function prettyUrl(url) {
  if (!url) return "";
  return url.replace(/^https?:\/\//, "").replace(/\/$/, "");
}

function describe(result) {
  const payload = result.payload;
  if (result.type === lazy.UrlbarShared.RESULT_TYPE.SEARCH) {
    const query = payload.suggestion ?? payload.query ?? "";
    return { title: query, detail: payload.engine ? `search with ${payload.engine}` : "" };
  }
  return { title: payload.title || prettyUrl(payload.url), detail: prettyUrl(payload.url) };
}

function entryFromResult(result) {
  const { title, detail } = describe(result);
  return {
    title,
    detail,
    kind: kindOf(result),
    icon: result.icon || DEFAULT_FAVICON,
    result,
  };
}

function entryFromItem(item, index) {
  const object = item !== null && typeof item === "object";
  const title = String((object ? item.label ?? item.title ?? item.value : item) ?? "");
  const detail = object ? String(item.detail ?? item.description ?? "") : "";
  return {
    title,
    detail,
    kind: object ? String(item.kind ?? "") : "",
    icon: object && item.icon ? String(item.icon) : null,
    item,
    index,
    titleLower: title.toLowerCase(),
    haystack: `${title}\n${detail}`.toLowerCase(),
  };
}

function isMotion(event, letter) {
  return (event.ctrlKey || event.altKey) && event.key === letter;
}

function scoreEntry(entry, query, tokens) {
  if (!tokens.length) return 0;
  for (const token of tokens) {
    if (!entry.haystack.includes(token)) return -1;
  }
  if (entry.titleLower.startsWith(query)) return 0;
  if (entry.titleLower.includes(query)) return 1;
  return 2;
}

export class Omnibar {
  #panel = null;
  #prompt = null;
  #input = null;
  #list = null;
  #entries = [];
  #items = [];
  #selected = 0;
  #context = null;
  #sources = null;
  #newTab = false;
  #mode = "urlbar";
  #maxResults = MAX_RESULTS;
  #emptyText = "no results";
  #resolve = null;
  #choice = null;

  constructor(win) {
    this.win = win;
  }

  open({ sources = null, newTab = false, prefill = "" } = {}) {
    this.#settle();
    this.#mode = "urlbar";
    this.#sources = sources;
    this.#newTab = newTab;
    this.#items = [];
    this.#maxResults = MAX_RESULTS;
    this.#emptyText = "no results";
    try {
      this.#show({ prompt: "", placeholder: "", prefill });
    } catch (err) {
      console.error(LOG_PREFIX, err);
    }
  }

  select({
    items = [],
    prompt = "",
    placeholder = "",
    prefill = "",
    maxResults = MENU_MAX_RESULTS,
  } = {}) {
    this.#settle();
    this.#mode = "menu";
    this.#sources = null;
    this.#newTab = false;
    this.#items = Array.from(items, entryFromItem);
    this.#maxResults = Math.max(1, maxResults);
    this.#emptyText = "no matches";

    const chosen = new Promise((resolve) => {
      this.#resolve = resolve;
    });
    try {
      this.#show({ prompt, placeholder, prefill });
    } catch (err) {
      console.error(LOG_PREFIX, err);
      this.#settle();
    }
    return chosen;
  }

  close() {
    this.#cancel();
    if (this.#panel?.state === "open" || this.#panel?.state === "showing") {
      this.#panel.hidePopup();
      return;
    }
    this.#settle();
  }

  destroy() {
    this.#cancel();
    this.#settle();
    this.#panel?.remove();
    this.#panel = null;
    this.#prompt = null;
    this.#input = null;
    this.#list = null;
  }

  #show({ prompt, placeholder, prefill }) {
    this.#ensurePanel();
    this.#entries = [];
    this.#selected = 0;
    this.#prompt.textContent = prompt;
    this.#prompt.style.display = prompt ? "block" : "none";
    this.#input.setAttribute("placeholder", placeholder);
    this.#input.value = prefill;
    this.#renderRows();

    if (this.#panel.state === "open" || this.#panel.state === "showing") {
      this.#focusInput();
      this.#search(prefill);
      return;
    }

    const anchor = this.win.document.getElementById("browser") ?? this.win.gBrowser.selectedBrowser;
    const available = anchor.getBoundingClientRect().width;
    const x = Math.max(0, Math.round((available - Math.min(PANEL_WIDTH, available)) / 2));
    this.#panel.openPopup(anchor, "overlap", x, PANEL_TOP, false, false);
    this.#search(prefill);
  }

  #focusInput() {
    this.#input.focus();
    const end = this.#input.value.length;
    this.#input.setSelectionRange(end, end);
  }

  #settle() {
    const resolve = this.#resolve;
    const choice = this.#choice;
    this.#resolve = null;
    this.#choice = null;
    resolve?.(choice ?? null);
  }

  #ensurePanel() {
    if (this.#panel?.isConnected) return;
    const doc = this.win.document;

    const panel = doc.createXULElement("panel");
    panel.id = PANEL_ID;
    panel.setAttribute("noautofocus", "false");
    panel.setAttribute("consumeoutsideclicks", "true");
    panel.setAttribute("rolluponmousewheel", "true");
    panel.setAttribute("level", "parent");
    panel.style.setProperty("--panel-padding", "0");

    const box = doc.createElementNS(HTML_NS, "div");
    box.style.cssText = BOX_CSS;

    const prompt = doc.createElementNS(HTML_NS, "div");
    prompt.style.cssText = PROMPT_CSS;
    prompt.style.display = "none";

    const input = doc.createElementNS(HTML_NS, "input");
    input.setAttribute("type", "text");
    input.style.cssText = INPUT_CSS;

    const list = doc.createElementNS(HTML_NS, "div");
    list.style.cssText = LIST_CSS;

    box.append(prompt, input, list);
    panel.append(box);
    (doc.getElementById("mainPopupSet") ?? doc.documentElement).append(panel);

    panel.addEventListener("popupshown", () => this.#focusInput());
    panel.addEventListener("popuphidden", () => {
      this.#cancel();
      this.#settle();
    });
    panel.addEventListener("keydown", (event) => this.#onKeyDown(event), true);
    input.addEventListener("input", () => this.#search(input.value));

    this.#panel = panel;
    this.#prompt = prompt;
    this.#input = input;
    this.#list = list;
  }

  #cancel() {
    if (!this.#context) return;
    try {
      lazy.ProvidersManager.getInstanceForSap(SAP_NAME).cancelQuery(this.#context);
    } catch (err) {
      console.error(LOG_PREFIX, err);
    }
    this.#context = null;
  }

  #search(value) {
    this.#cancel();
    this.#selected = 0;

    if (this.#mode === "menu") {
      this.#filter(value);
      return;
    }

    const browser = this.win.gBrowser.selectedBrowser;
    const options = {
      allowAutofill: false,
      isPrivate: lazy.PrivateBrowsingUtils.isWindowPrivate(this.win),
      maxResults: this.#maxResults,
      sapName: SAP_NAME,
      searchString: value,
      userContextId: parseInt(browser.getAttribute("usercontextid") || 0, 10),
    };
    const sources = this.#sources && OMNIBAR_SOURCES[this.#sources]?.();
    if (sources) options.sources = sources;
    const currentPage = this.win.gBrowser.currentURI?.spec;
    if (currentPage) options.currentPage = currentPage;

    let context;
    try {
      context = new lazy.UrlbarQueryContext(options);
    } catch (err) {
      console.error(LOG_PREFIX, err);
      return;
    }
    this.#context = context;

    let received = false;
    const controller = {
      receiveResults: (ctx) => {
        if (this.#context !== context) return;
        received = true;
        this.#update(ctx.results ?? []);
      },
    };

    lazy.ProvidersManager.getInstanceForSap(SAP_NAME)
      .startQuery(context, controller)
      .then(() => {
        if (this.#context === context && !received) this.#update([]);
      })
      .catch((err) => console.error(LOG_PREFIX, err));
  }

  #filter(value) {
    const query = value.trim().toLowerCase();
    const tokens = query.split(/\s+/).filter(Boolean);
    const matched = [];
    for (const entry of this.#items) {
      const score = scoreEntry(entry, query, tokens);
      if (score >= 0) matched.push({ entry, score });
    }
    matched.sort((a, b) => a.score - b.score || a.entry.index - b.entry.index);
    this.#entries = matched.slice(0, this.#maxResults).map((match) => match.entry);
    this.#renderRows();
  }

  #update(results) {
    this.#entries = results.filter(isUsable).slice(0, this.#maxResults).map(entryFromResult);
    this.#selected = Math.max(0, Math.min(this.#selected, this.#entries.length - 1));
    this.#renderRows();
  }

  #renderRows() {
    const doc = this.win.document;
    this.#list.textContent = "";

    if (!this.#entries.length) {
      const empty = doc.createElementNS(HTML_NS, "div");
      empty.style.cssText = EMPTY_CSS;
      empty.textContent = this.#emptyText;
      this.#list.append(empty);
      return;
    }

    this.#entries.forEach((entry, index) => {
      const row = doc.createElementNS(HTML_NS, "div");
      row.style.cssText = ROW_CSS + (index === this.#selected ? ROW_SELECTED_CSS : "");

      if (entry.icon) {
        const icon = doc.createElementNS(HTML_NS, "img");
        icon.style.cssText = ICON_CSS;
        icon.setAttribute("src", entry.icon);
        icon.addEventListener("error", () => {
          if (icon.getAttribute("src") !== DEFAULT_FAVICON) icon.setAttribute("src", DEFAULT_FAVICON);
        });
        row.append(icon);
      }

      const titleNode = doc.createElementNS(HTML_NS, "span");
      titleNode.style.cssText = TITLE_CSS;
      titleNode.textContent = entry.title;

      const kindNode = doc.createElementNS(HTML_NS, "span");
      kindNode.style.cssText = KIND_CSS;
      kindNode.textContent = entry.kind;

      const detailNode = doc.createElementNS(HTML_NS, "span");
      detailNode.style.cssText = URL_CSS;
      detailNode.textContent = entry.detail;

      row.append(titleNode, kindNode, detailNode);
      row.addEventListener("mouseover", () => this.#select(index));
      row.addEventListener("click", (event) => {
        this.#select(index);
        this.#activate(event.shiftKey);
      });
      this.#list.append(row);
    });
  }

  #select(index) {
    if (index === this.#selected || !this.#entries.length) return;
    this.#selected = index;
    const rows = this.#list.children;
    for (let i = 0; i < rows.length; i++) {
      rows[i].style.cssText = ROW_CSS + (i === this.#selected ? ROW_SELECTED_CSS : "");
    }
  }

  #move(delta) {
    const count = this.#entries.length;
    if (!count) return;
    this.#select((this.#selected + delta + count) % count);
  }

  #onKeyDown(event) {
    const key = event.key;

    if (key === "Escape") {
      event.preventDefault();
      event.stopPropagation();
      this.close();
      return;
    }

    if (key === "Enter") {
      event.preventDefault();
      event.stopPropagation();
      this.#activate(event.shiftKey);
      return;
    }

    if (key === "ArrowDown" || isMotion(event, "j") || (key === "Tab" && !event.shiftKey)) {
      event.preventDefault();
      event.stopPropagation();
      this.#move(1);
      return;
    }

    if (key === "ArrowUp" || isMotion(event, "k") || (key === "Tab" && event.shiftKey)) {
      event.preventDefault();
      event.stopPropagation();
      this.#move(-1);
    }
  }

  #activate(invert) {
    const entry = this.#entries[this.#selected];
    if (!entry) return;

    if (this.#mode === "menu") {
      this.#choice = entry.item;
      this.close();
      return;
    }

    const newTab = invert ? !this.#newTab : this.#newTab;
    this.close();

    if (entry.result.type === lazy.UrlbarShared.RESULT_TYPE.TAB_SWITCH && !newTab) {
      this.#switchToTab(entry.result);
      return;
    }

    let url;
    let postData;
    try {
      ({ url, postData } = lazy.UrlbarUtils.getUrlFromResult(entry.result));
    } catch (err) {
      console.error(LOG_PREFIX, err);
      return;
    }
    if (!url) return;

    const lower = url.toLowerCase();
    if (BLOCKED_SCHEMES.some((scheme) => lower.startsWith(scheme))) {
      console.warn(LOG_PREFIX, "refusing to open", url);
      return;
    }

    this.win.openTrustedLinkIn(url, newTab ? "tab" : "current", {
      postData,
      allowInheritPrincipal: false,
    });
  }

  #switchToTab(result) {
    const userContextId = result.payload.userContext?.id;
    const switched = this.win.switchToTabHavingURI(
      Services.io.newURI(result.payload.url),
      true,
      {},
      lazy.UrlbarShared.isNonPrivateUserContextId(userContextId) ? userContextId ?? null : null
    );
    if (!switched) {
      console.warn(LOG_PREFIX, "no open tab for", result.payload.url);
    }
  }
}

const instances = new WeakMap();

export function omnibarFor(win) {
  let instance = instances.get(win);
  if (instance) return instance;

  instance = new Omnibar(win);
  instances.set(win, instance);
  win.omnibar = instance;
  win.addEventListener(
    "unload",
    () => {
      instances.delete(win);
      instance.destroy();
    },
    { once: true }
  );
  return instance;
}
