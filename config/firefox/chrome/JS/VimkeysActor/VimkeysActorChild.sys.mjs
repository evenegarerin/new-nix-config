// Runs inside file:// pages (in their content process). Page commands (hints,
// scrolling) run right here via the shared core; browser commands (x, t, /, …)
// go to VimkeysActorParent, which hands them to vimkeys.uc.js.

import { KeyHandler, eventTarget, windowOf } from "chrome://userscripts/content/vimkeys/core.sys.mjs";

export class VimkeysActorChild extends JSWindowActorChild {
  #keys = null;

  // fx-autoconfig delivers DOMContentLoaded; that's when we start listening.
  handleEvent(event) {
    if (event.type !== "DOMContentLoaded" || this.#keys) return;
    const win = this.contentWindow;
    if (!win) return;

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
