const lazy = {};

ChromeUtils.defineESModuleGetters(lazy, {
  PrivateBrowsingUtils: "resource://gre/modules/PrivateBrowsingUtils.sys.mjs",
  ProvidersManager: "moz-src:///browser/components/urlbar/UrlbarProvidersManager.sys.mjs",
  UrlbarQueryContext: "chrome://browser/content/urlbar/UrlbarQueryContext.mjs",
  UrlbarShared: "chrome://browser/content/urlbar/UrlbarShared.mjs",
  UrlbarUtils: "moz-src:///browser/components/urlbar/UrlbarUtils.sys.mjs",
});

const HTML_NS = "http://www.w3.org/1999/xhtml";
const LOG_PREFIX = "[vimkeys]";
const SAP_NAME = "urlbar";
const PANEL_ID = "vimkeys-omnibar";
const MAX_RESULTS = 12;
const PANEL_WIDTH = 640;
const PANEL_TOP = 72;
const DEFAULT_FAVICON = "chrome://global/skin/icons/defaultFavicon.svg";
const BLOCKED_SCHEMES = ["javascript:", "data:"];

const BOX_CSS =
  "display:flex; flex-direction:column; box-sizing:border-box; gap:8px;" +
  `width:${PANEL_WIDTH}px; max-width:90vw; padding:10px;` +
  "font:14px/1.4 system-ui, sans-serif;";
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

export class Omnibar {
  #panel = null;
  #input = null;
  #list = null;
  #results = [];
  #selected = 0;
  #context = null;
  #sources = null;
  #newTab = false;

  constructor(win) {
    this.win = win;
  }

  open({ sources = null, newTab = false, prefill = "" } = {}) {
    this.#sources = sources;
    this.#newTab = newTab;
    this.#ensurePanel();
    this.#results = [];
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

  close() {
    this.#cancel();
    if (this.#panel?.state === "open" || this.#panel?.state === "showing") {
      this.#panel.hidePopup();
    }
  }

  destroy() {
    this.#cancel();
    this.#panel?.remove();
    this.#panel = null;
    this.#input = null;
    this.#list = null;
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

    const input = doc.createElementNS(HTML_NS, "input");
    input.setAttribute("type", "text");
    input.style.cssText = INPUT_CSS;

    const list = doc.createElementNS(HTML_NS, "div");
    list.style.cssText = LIST_CSS;

    box.append(input, list);
    panel.append(box);
    (doc.getElementById("mainPopupSet") ?? doc.documentElement).append(panel);

    panel.addEventListener("popupshown", () => this.#focusInput());
    panel.addEventListener("popuphidden", () => this.#cancel());
    panel.addEventListener("keydown", (event) => this.#onKeyDown(event), true);
    input.addEventListener("input", () => this.#search(input.value));

    this.#panel = panel;
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

    const browser = this.win.gBrowser.selectedBrowser;
    const options = {
      allowAutofill: false,
      isPrivate: lazy.PrivateBrowsingUtils.isWindowPrivate(this.win),
      maxResults: MAX_RESULTS,
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

  #update(results) {
    this.#results = results.filter(isUsable).slice(0, MAX_RESULTS);
    this.#selected = Math.max(0, Math.min(this.#selected, this.#results.length - 1));
    this.#renderRows();
  }

  #renderRows() {
    const doc = this.win.document;
    this.#list.textContent = "";

    if (!this.#results.length) {
      const empty = doc.createElementNS(HTML_NS, "div");
      empty.style.cssText = EMPTY_CSS;
      empty.textContent = "no results";
      this.#list.append(empty);
      return;
    }

    this.#results.forEach((result, index) => {
      const { title, detail } = describe(result);

      const row = doc.createElementNS(HTML_NS, "div");
      row.style.cssText = ROW_CSS + (index === this.#selected ? ROW_SELECTED_CSS : "");

      const icon = doc.createElementNS(HTML_NS, "img");
      icon.style.cssText = ICON_CSS;
      icon.setAttribute("src", result.icon || DEFAULT_FAVICON);
      icon.addEventListener("error", () => {
        if (icon.getAttribute("src") !== DEFAULT_FAVICON) icon.setAttribute("src", DEFAULT_FAVICON);
      });

      const titleNode = doc.createElementNS(HTML_NS, "span");
      titleNode.style.cssText = TITLE_CSS;
      titleNode.textContent = title;

      const kindNode = doc.createElementNS(HTML_NS, "span");
      kindNode.style.cssText = KIND_CSS;
      kindNode.textContent = kindOf(result);

      const detailNode = doc.createElementNS(HTML_NS, "span");
      detailNode.style.cssText = URL_CSS;
      detailNode.textContent = detail;

      row.append(icon, titleNode, kindNode, detailNode);
      row.addEventListener("mouseover", () => this.#select(index));
      row.addEventListener("click", (event) => {
        this.#select(index);
        this.#activate(event.shiftKey);
      });
      this.#list.append(row);
    });
  }

  #select(index) {
    if (index === this.#selected || !this.#results.length) return;
    this.#selected = index;
    const rows = this.#list.children;
    for (let i = 0; i < rows.length; i++) {
      rows[i].style.cssText = ROW_CSS + (i === this.#selected ? ROW_SELECTED_CSS : "");
    }
  }

  #move(delta) {
    const count = this.#results.length;
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

    if (key === "ArrowDown" || (event.ctrlKey && key === "j") || (key === "Tab" && !event.shiftKey)) {
      event.preventDefault();
      event.stopPropagation();
      this.#move(1);
      return;
    }

    if (key === "ArrowUp" || (event.ctrlKey && key === "k") || (key === "Tab" && event.shiftKey)) {
      event.preventDefault();
      event.stopPropagation();
      this.#move(-1);
    }
  }

  #activate(invert) {
    const result = this.#results[this.#selected];
    if (!result) return;
    const newTab = invert ? !this.#newTab : this.#newTab;
    this.close();

    if (result.type === lazy.UrlbarShared.RESULT_TYPE.TAB_SWITCH && !newTab) {
      this.#switchToTab(result);
      return;
    }

    let url;
    let postData;
    try {
      ({ url, postData } = lazy.UrlbarUtils.getUrlFromResult(result));
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
