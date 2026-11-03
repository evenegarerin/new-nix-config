// Comes to every page in a tab, but only takes over where Vimium can't run
// (see shouldTakeOver). Page commands (hints, scrolling) run right here via
// the shared core; browser commands (x, t, /, …) go to VimkeysActorParent,
// which hands them to vimkeys.uc.js.

import { KeyHandler, SETTINGS, eventTarget, windowOf } from "./core.sys.mjs";

// Asks Firefox the same question it asks before injecting Vimium's content
// scripts into this page or frame. That covers everything Firefox blocks
// (about: and other privileged pages, restricted Mozilla sites, private
// windows Vimium isn't allowed in, missing site permissions) and a disabled
// or uninstalled Vimium. Vimium's own exclusion rules are not visible here.
function vimiumRunsIn(windowGlobal) {
  const policy = WebExtensionPolicy.getByID(SETTINGS.vimiumId);
  if (!policy?.active) return false;
  return policy.contentScripts.some((script) => script.matchesWindowGlobal(windowGlobal));
}

export class VimkeysActorChild extends JSWindowActorChild {
  #keys = null;

  // The actor is created on DOMContentLoaded; that's when we decide.
  handleEvent(event) {
    if (event.type !== "DOMContentLoaded" || this.#keys) return;
    const win = this.contentWindow;
    if (!win || !this.#shouldTakeOver()) return;

    this.#keys = new KeyHandler({
      hintDocument: () => this.document,
      runBrowserCommand: (name) => this.sendAsyncMessage("Vimkeys:command", { name }),
    });

    win.addEventListener("keydown", (e) => this.#onKeyDown(e), true);
    win.addEventListener("keyup", (e) => this.#keys?.onKeyUp(e), true);
    win.addEventListener("blur", () => this.#keys?.onBlur());
    win.addEventListener("pagehide", () => this.#keys?.stop());
    this.document.addEventListener("visibilitychange", () => {
      if (this.document?.hidden) this.#keys?.stop();
    });
  }

  #shouldTakeOver() {
    const addonId = this.document.nodePrincipal.addonId;
    if (addonId) {
      // Vimium's own UI (Vomnibar, HUD, help) and other extensions' frames sit
      // inside pages: leave them alone, or Escape would stop closing the
      // Vomnibar. A whole extension page in its own tab (e.g. uBlock's
      // dashboard) is fine, as long as it isn't Vimium's.
      return addonId !== SETTINGS.vimiumId && !this.browsingContext.parent;
    }
    return !vimiumRunsIn(this.manager);
  }

  #onKeyDown(event) {
    const keys = this.#keys;
    if (!keys) return;
    const target = eventTarget(event);
    const win = windowOf(target) ?? this.contentWindow;
    keys.onKeyDown(event, { target, win, code: event.code });
  }

  didDestroy() {
    this.#keys?.stop();
    this.#keys = null;
  }
}
