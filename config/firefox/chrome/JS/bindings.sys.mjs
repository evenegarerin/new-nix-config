// ---- Key bindings ----------------------------------------------------------
// Keys -> command names. Page commands run right here; the rest are browser
// commands that each side carries out its own way (see runBrowserCommand).
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
  ge: "editUrl",
  r: "reload",
  R: "reloadHard",
  yy: "copyUrl",
  p: "openClipboardUrl",
  P: "openClipboardUrlNewTab",
  t: "newTab",
  x: "closeTab",
  X: "restoreTab",
  H: "goBack",
  L: "goForward",
  J: "nextTab",     // right (Vimium default: K)
  K: "previousTab", // left  (Vimium default: J)
  "?": "showHelp",
};

export const HELP = [
  ["Navigating the page", [
    ["linkHints", "Open a link in the current tab"],
    ["linkHintsNewTab", "Open a link in a new tab"],
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
    ["editUrl", "Edit the current URL"],
  ]],
  ["Manipulating tabs", [
    ["newTab", "Create a new tab"],
    ["closeTab", "Close the current tab"],
    ["restoreTab", "Restore a closed tab"],
    ["nextTab", "Go one tab right inside the current group"],
    ["previousTab", "Go one tab left inside the current group"],
    ["openOmnibarTabs", "Search through your open tabs"],
    ["tabGroupMenu", "Switch to a tab group"],
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
  "openClipboardUrl", "openClipboardUrlNewTab", "tabGroupMenu",
]);

// Commands that fire again on key auto-repeat. With smooth scrolling, a held
// j/k is handled by the scroll animation itself, like in Vimium.
const REPEATABLE = new Set(["findNext", "findPrevious", "nextTab", "previousTab"]);
const SCROLL_REPEATABLE = new Set(["scrollDown", "scrollUp"]);

export function isRepeatable(command, smoothScroll) {
  if (REPEATABLE.has(command)) return true;
  return !smoothScroll && SCROLL_REPEATABLE.has(command);
}

// Every unfinished part of a multi-key binding, e.g. "g" for "gg".
const PREFIXES = new Set();
for (const keys of Object.keys(BINDINGS)) {
  for (let i = 1; i < keys.length; i++) PREFIXES.add(keys.slice(0, i));
}

export function resolveKeys(keys) {
  if (Object.hasOwn(BINDINGS, keys)) return { keys, command: BINDINGS[keys] };
  if (PREFIXES.has(keys)) return { keys, prefix: true };
  return null;
}
