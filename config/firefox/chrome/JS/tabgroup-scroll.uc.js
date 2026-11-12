// ==UserScript==
// @name           tabgroup-scroll
// @description    Keeps the selected tab visible inside a tab group that scrolls on its own (see userChrome.css)
// @include        main
// ==/UserScript==

/*
 * Works together with the tab-group rules in userChrome.css: the active group fills
 * the remaining sidebar space and scrolls inside its own border. CSS can't scroll a
 * container to an element, so this script keeps the selected tab, plus SCROLL_OFF
 * neighbours on each side (like vim's scrolloff), visible inside its group. If the
 * group is too short for all that context, the selected tab is centred instead.
 *
 * If a change to this file doesn't take effect after restarting Firefox,
 * fx-autoconfig is serving a cached copy: about:support → "Clear startup cache…".
 */

(function () {
  "use strict";

  const SCROLL_OFF = 3;
  const PADDING = 4;

  function revealSelectedTab() {
    const tab = gBrowser.selectedTab;
    const group = tab?.group;
    if (!group || group.collapsed || group.scrollHeight <= group.clientHeight) return;

    const tabs = group.tabs.filter(t => !t.hidden);
    const i = tabs.indexOf(tab);
    if (i < 0) return;
    const above = tabs[Math.max(0, i - SCROLL_OFF)];
    const below = tabs[Math.min(tabs.length - 1, i + SCROLL_OFF)];

    const groupRect = group.getBoundingClientRect();
    const viewTop = groupRect.top + group.clientTop + PADDING;
    const viewBottom = groupRect.top + group.clientTop + group.clientHeight - PADDING;
    const wantTop = above.getBoundingClientRect().top;
    const wantBottom = below.getBoundingClientRect().bottom;

    let delta = 0;
    if (wantBottom - wantTop > viewBottom - viewTop) {
      const r = tab.getBoundingClientRect();
      delta = (r.top + r.bottom) / 2 - (viewTop + viewBottom) / 2;
    } else if (wantTop < viewTop) {
      delta = wantTop - viewTop;
    } else if (wantBottom > viewBottom) {
      delta = wantBottom - viewBottom;
    }
    if (delta) group.scrollTop += delta;
  }

  function scheduleReveal() {
    requestAnimationFrame(() => requestAnimationFrame(revealSelectedTab));
  }

  const tabs = gBrowser.tabContainer;
  for (const type of ["TabSelect", "TabMove", "TabGrouped", "TabUngrouped", "TabGroupExpand"]) {
    tabs.addEventListener(type, scheduleReveal);
  }
  window.addEventListener("resize", scheduleReveal);
})();
