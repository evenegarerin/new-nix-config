export const BINDINGS = {
  "/": "find",
  n: "findNext",
  N: "findPrevious",
  f: "linkHints",
  F: "linkHintsNewTab",
  v: "visualMode",
  j: "scrollDown",
  k: "scrollUp",
  gg: "scrollToTop",
  G: "scrollToBottom",
  o: "openOmnibar",
  O: "openOmnibarNewTab",
  b: "openOmnibarBookmarks",
  B: "openOmnibarBookmarksNewTab",
  T: "openOmnibarTabs",
  m: "tabGroupMenu",
  M: "tabGroupToggle",
  ge: "editUrl",
  r: "reload",
  R: "reloadHard",
  y: "linkHintsCopy",
  Y: "copyUrl",
  p: "openClipboardUrl",
  P: "openClipboardUrlNewTab",
  t: "newTab",
  x: "closeTab",
  X: "restoreTab",
  V: "splitView",
  H: "goBack",
  L: "goForward",
  J: "nextTab",
  K: "previousTab",
  "?": "showHelp",
};

export const HELP = [
  ["Navigating the page", [
    ["linkHints", "Open a link in the current tab"],
    ["linkHintsNewTab", "Open a link in a new tab"],
    ["linkHintsCopy", "Copy a link's URL to the clipboard"],
    ["visualMode", "Enter visual mode (hjkl selects, y copies, v or Escape exits)"],
    ["reload", "Reload the page"],
    ["reloadHard", "Reload the page, ignoring the cache"],
    ["copyUrl", "Copy the current URL to the clipboard"],
    ["openClipboardUrl", "Open the clipboard's URL in the current tab"],
    ["openClipboardUrlNewTab", "Open the clipboard's URL in a new tab"],
    ["scrollDown", "Scroll down"],
    ["scrollUp", "Scroll up"],
    ["scrollToTop", "Scroll to the top of the page"],
    ["scrollToBottom", "Scroll to the bottom of the page"],
  ]],
  ["Using find", [
    ["find", "Enter find mode (Enter accepts the match, Escape cancels)"],
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
    ["editUrl", "Edit the current URL"],
  ]],
  ["Manipulating tabs", [
    ["newTab", "Create a new tab"],
    ["closeTab", "Close the current tab"],
    ["restoreTab", "Restore a closed tab"],
    ["splitView", "Open a vertical split next to the current tab"],
    ["nextTab", "Go one tab right inside the current group"],
    ["previousTab", "Go one tab left inside the current group"],
    ["openOmnibarTabs", "Search through your open tabs"],
    ["tabGroupMenu", "Switch to a tab group"],
    ["tabGroupToggle", "Move the current tab between the const and let groups"],
  ]],
  ["Miscellaneous", [
    ["showHelp", "Show this help"],
  ]],
];

export function keysFor(command) {
  return Object.keys(BINDINGS).filter((keys) => BINDINGS[keys] === command);
}

export const BROWSER_COMMANDS = new Set([
  "find", "findNext", "findPrevious", "newTab", "closeTab", "restoreTab",
  "goBack", "goForward", "nextTab", "previousTab",
  "openOmnibar", "openOmnibarNewTab", "openOmnibarBookmarks",
  "openOmnibarBookmarksNewTab", "openOmnibarTabs",
  "editUrl", "reload", "reloadHard", "copyUrl",
  "openClipboardUrl", "openClipboardUrlNewTab", "tabGroupMenu", "tabGroupToggle",
  "splitView",
]);

export const WINDOW_KEYS = new Set([
  "p", "P", "J", "K", "o", "O", "b", "B", "ge", "t", "x", "T", "m", "V",
]);

const REPEATABLE = new Set(["findNext", "findPrevious", "nextTab", "previousTab"]);
const SCROLL_REPEATABLE = new Set(["scrollDown", "scrollUp"]);

export function isRepeatable(command, smoothScroll) {
  if (REPEATABLE.has(command)) return true;
  return !smoothScroll && SCROLL_REPEATABLE.has(command);
}

const PREFIXES = new Set();
for (const keys of Object.keys(BINDINGS)) {
  for (let i = 1; i < keys.length; i++) PREFIXES.add(keys.slice(0, i));
}

export function resolveKeys(keys) {
  if (Object.hasOwn(BINDINGS, keys)) return { keys, command: BINDINGS[keys] };
  if (PREFIXES.has(keys)) return { keys, prefix: true };
  return null;
}

export const SEARCH_ENGINES = `
go: https://www.google.com/search?q=%s Google
yt: https://www.youtube.com/results?search_query=%s Youtube
gm: https://www.google.com/maps?q=%s Google maps

nix: https://search.nixos.org/packages?query=%s
home: https://home-manager-options.extranix.com/?query=%s&release=release-25.11
`;

const ENGINE_PROTOCOL = /^[a-z][a-z0-9.+-]*:/i;
const ENGINE_BLOCKED = /^(javascript|data):/i;

export function parseSearchEngines(text) {
  const engines = new Map();
  for (const raw of String(text).replace(/\\\n/g, "").split("\n")) {
    const line = raw.trim();
    if (!line || line[0] === "#" || line[0] === '"') continue;
    const tokens = line.split(/\s+/);
    if (tokens.length < 2 || !tokens[0].includes(":")) continue;
    const keyword = tokens[0].split(":")[0];
    const url = tokens[1];
    if (!keyword || !ENGINE_PROTOCOL.test(url) || ENGINE_BLOCKED.test(url)) continue;
    const description = tokens.length > 2 ? tokens.slice(2).join(" ") : `search (${keyword})`;
    engines.set(keyword, { keyword, url, description });
  }
  return engines;
}

export function buildSearchUrl(terms, template) {
  let url = template;
  if (!url.includes("%s") && !url.includes("%S")) url += "%s";
  url = url.replaceAll("%S", terms);
  const encoded = terms.split(/\s+/).map(encodeURIComponent).join("%20");
  return url.replaceAll("%s", encoded);
}
