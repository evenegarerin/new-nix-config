// Comes to every page in a tab. Page commands (hints, scrolling) run right
// here via the shared core; browser commands (x, t, /, …) go to
// VimkeysActorParent, which hands them to vimkeys.uc.js.

import { KeyHandler, eventTarget, windowOf } from "./core.sys.mjs";

export class VimkeysActorChild extends JSWindowActorChild {
  #keys = null;
  #modeRefreshScheduled = false;

  handleEvent() {
    this.#attach();
  }

  receiveMessage(message) {
    if (message.name === "Vimkeys:attach") this.#attach();
  }

  #attach() {
    if (this.#keys) return;
    const win = this.contentWindow;
    if (!win || !this.#shouldTakeOver()) return;

    this.#keys = new KeyHandler({
      hintDocument: () => this.document,
      runBrowserCommand: (name) => this.sendAsyncMessage("Vimkeys:command", { name }),
      onModeChange: (mode) => this.#reportMode(mode),
    });

    win.addEventListener("keydown", (e) => this.#onKeyDown(e), true);
    win.addEventListener("keyup", (e) => this.#keys?.onKeyUp(e), true);
    win.addEventListener("blur", () => this.#keys?.onBlur());
    win.addEventListener("pagehide", () => this.#keys?.stop());
    win.addEventListener("focusin", () => this.#scheduleModeRefresh(), true);
    win.addEventListener("focusout", () => this.#scheduleModeRefresh(), true);
    this.document.addEventListener("visibilitychange", () => {
      if (this.document?.hidden) {
        this.#keys?.stop();
      } else {
        this.#keys?.refreshMode(true);
      }
    });

    this.#keys.refreshMode();
  }

  #reportMode(mode) {
    try {
      this.sendAsyncMessage("Vimkeys:mode", { mode });
    } catch {}
  }

  #scheduleModeRefresh() {
    if (this.#modeRefreshScheduled) return;
    this.#modeRefreshScheduled = true;
    Services.tm.dispatchToMainThread(() => {
      this.#modeRefreshScheduled = false;
      this.#keys?.refreshMode();
    });
  }

  #shouldTakeOver() {
    // Other extensions' frames sit inside pages (pickers, popups, panels):
    // leave them alone. A whole extension page in its own tab (e.g. uBlock's
    // dashboard) is fine.
    if (this.document.nodePrincipal.addonId) return !this.browsingContext.parent;
    return true;
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
