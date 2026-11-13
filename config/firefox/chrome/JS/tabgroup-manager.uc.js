// ==UserScript==
// @name           tabgroup-manager
// @description    Keeps the "const" and "let" tab groups alive, "let" last and holding every ungrouped new tab
// @include        main
// ==/UserScript==

(function () {
  "use strict";

  const { omnibarFor } =
    ChromeUtils.importESModule("chrome://userscripts/content/omnibar.sys.mjs");

  const LOG_PREFIX = "[tabgroup-manager]";
  const GROUPS = [
    { label: "const", color: "blue" },
    { label: "let", color: "gray" },
  ];
  const LAST_LABEL = "let";
  const INBOX_LABEL = "let";
  const PLACEHOLDER_URL = "about:newtab";
  const RESTORED_TOPIC = "sessionstore-windows-restored";
  const SKIP_PRIVATE = true;
  const UNNAMED_LABEL = "(unnamed)";

  const maintain =
    window.toolbar.visible &&
    !(SKIP_PRIVATE && PrivateBrowsingUtils.isWindowPrivate(window));

  let scheduled = false;
  let running = false;
  let dirty = false;
  let ready = false;
  let clearPending = false;
  const strays = new Set();

  function groupsLabelled(label) {
    return gBrowser.tabGroups.filter(
      (group) => group.label === label && group.tabs.length
    );
  }

  function mergeInto(groups) {
    const keep = groups[0];
    for (const extra of groups.slice(1)) {
      for (const tab of extra.tabs) {
        gBrowser.moveTabToExistingGroup(tab, keep);
      }
    }
    return keep;
  }

  function createGroup({ label, color }) {
    const tab = gBrowser.addTrustedTab(PLACEHOLDER_URL, { skipAnimation: true });
    const group = gBrowser.addTabGroup([tab], { label, color });
    if (!group) {
      gBrowser.removeTab(tab, { animate: false });
      console.warn(LOG_PREFIX, "could not create the group", label);
    }
    return group;
  }

  function moveToEnd(group) {
    const groups = gBrowser.tabGroups;
    const last = groups[groups.length - 1];
    if (!last || last === group) return;
    gBrowser.moveTabAfter(group, last);
  }

  function clearRestored() {
    const options = {
      animate: false,
      skipPermitUnload: true,
      skipSessionStore: true,
      closeWindowWithLastTab: false,
      suppressWarnAboutClosingWindow: true,
    };
    for (const group of groupsLabelled(INBOX_LABEL)) {
      Promise.resolve(gBrowser.removeTabGroup(group, { ...options })).catch((err) =>
        console.error(LOG_PREFIX, err)
      );
    }
    const loose = gBrowser.tabs.filter((tab) => !tab.pinned && !tab.group);
    if (loose.length) gBrowser.removeTabs(loose, { ...options });
    strays.clear();
  }

  function adoptStrays(group) {
    for (const tab of strays) {
      strays.delete(tab);
      if (!tab.isConnected || tab.closing || tab.pinned || tab.group) continue;
      try {
        gBrowser.moveTabToExistingGroup(tab, group);
      } catch (err) {
        console.error(LOG_PREFIX, err);
      }
    }
  }

  function ensure() {
    if (running) {
      dirty = true;
      return;
    }
    running = true;

    if (clearPending) {
      clearPending = false;
      try {
        clearRestored();
      } catch (err) {
        console.error(LOG_PREFIX, err);
      }
    }

    const found = new Map();
    for (const spec of GROUPS) {
      try {
        const existing = groupsLabelled(spec.label);
        const group = existing.length ? mergeInto(existing) : createGroup(spec);
        if (group) found.set(spec.label, group);
      } catch (err) {
        console.error(LOG_PREFIX, err);
      }
    }
    try {
      const lastGroup = found.get(LAST_LABEL);
      if (lastGroup) moveToEnd(lastGroup);
      const inbox = found.get(INBOX_LABEL);
      if (inbox) adoptStrays(inbox);
    } catch (err) {
      console.error(LOG_PREFIX, err);
    }

    ready = true;
    running = false;
    if (dirty) {
      dirty = false;
      schedule();
    }
  }

  function schedule() {
    if (scheduled) return;
    scheduled = true;
    Services.tm.dispatchToMainThread(() => {
      scheduled = false;
      ensure();
    });
  }

  function groupItems() {
    return gBrowser.tabGroups.map((group) => {
      const count = group.tabs.length;
      return {
        label: group.label || UNNAMED_LABEL,
        detail: `${count} ${count === 1 ? "tab" : "tabs"}`,
        kind: group.color ?? "",
        group,
      };
    });
  }

  function focusGroup(group) {
    if (!group?.isConnected) return;
    if (group.collapsed) group.collapsed = false;
    const tabs = group.tabs.filter((tab) => !tab.hidden && !tab.closing);
    if (!tabs.length || tabs.includes(gBrowser.selectedTab)) return;
    gBrowser.selectedTab = tabs.reduce(
      (best, tab) => (tab.lastAccessed > best.lastAccessed ? tab : best),
      tabs[0]
    );
  }

  async function openGroupMenu() {
    const items = groupItems();
    if (!items.length) return;
    const picked = await omnibarFor(window).select({
      prompt: "Tab groups",
      placeholder: "filter groups…",
      items,
    });
    focusGroup(picked?.group);
  }

  const extras = (window.vimkeysCommands ??= {});
  extras.tabGroupMenu = openGroupMenu;

  if (!maintain) return;

  gBrowser.tabContainer.addEventListener("TabOpen", (event) => {
    const tab = event.target;
    if (!ready || tab.pinned) return;
    strays.add(tab);
    schedule();
  });

  for (const type of [
    "TabGroupCreate",
    "TabGroupRemoved",
    "TabGroupMoved",
    "TabGroupUpdate",
    "TabUngrouped",
  ]) {
    gBrowser.tabContainer.addEventListener(type, schedule);
  }

  const restoredObserver = {
    observe() {
      clearPending = true;
      schedule();
    },
  };
  Services.obs.addObserver(restoredObserver, RESTORED_TOPIC);
  window.addEventListener(
    "unload",
    () => Services.obs.removeObserver(restoredObserver, RESTORED_TOPIC),
    { once: true }
  );

  window.addEventListener("SSWindowRestored", schedule, { once: true });
  SessionStore.promiseInitialized.then(schedule, (err) => console.error(LOG_PREFIX, err));
})();
