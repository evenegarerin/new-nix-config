import {
  KeyHandler, collectHintTargets, eventTarget, readHintKey, showHints, visibleFrameIds, windowOf,
} from "./core.sys.mjs";

export class VimkeysActorChild extends JSWindowActorChild {
  #keys = null;
  #modeRefreshScheduled = false;
  #pendingHints = null;
  #overlay = null;
  #remoteHints = null;

  handleEvent() {
    this.#attach();
  }

  receiveMessage(message) {
    switch (message.name) {
      case "Vimkeys:attach":
        this.#attach();
        break;
      case "Vimkeys:resetPending":
        this.#keys?.resetPending();
        break;
      case "Vimkeys:stop":
        this.#keys?.stop();
        break;
      case "Vimkeys:hintsCollect":
        return this.#collectHints(message.data?.action);
      case "Vimkeys:hintsShow":
        this.#showHints(message.data?.labels ?? []);
        break;
      case "Vimkeys:hintsFilter":
        this.#overlay?.filter(message.data?.typed ?? "");
        break;
      case "Vimkeys:hintsActivate": {
        const overlay = this.#overlay;
        this.#overlay = null;
        this.#remoteHints?.finish();
        overlay?.activate(message.data?.label);
        break;
      }
      case "Vimkeys:hintsEnd":
        this.#closeOverlay();
        this.#remoteHints?.finish();
        break;
    }
    return undefined;
  }

  #send(name, data = {}) {
    try {
      this.sendAsyncMessage(name, data);
    } catch {}
  }

  #collectHints(action) {
    this.#closeOverlay();
    this.#pendingHints = null;
    const doc = this.document;
    if (!doc?.documentElement || doc.hidden || !this.#shouldTakeOver()) return null;
    const targets = collectHintTargets(doc, action, false);
    this.#pendingHints = { targets, action };
    return { count: targets.length, frames: visibleFrameIds(doc) };
  }

  #showHints(labels) {
    const pending = this.#pendingHints;
    this.#pendingHints = null;
    if (!pending || !labels.length || labels.length !== pending.targets.length) return;
    const overlay = showHints(this.document, pending.targets, labels, pending.action, () => {
      if (this.#overlay !== overlay) return;
      this.#overlay = null;
      this.#send("Vimkeys:hintsCancel");
    });
    this.#overlay = overlay;
  }

  #closeOverlay() {
    const overlay = this.#overlay;
    this.#overlay = null;
    overlay?.exit();
  }

  #startFrameHints(action, onExit) {
    this.#remoteHints?.finish();
    let done = false;
    const end = (cancel) => {
      if (done) return;
      done = true;
      if (this.#remoteHints === hints) this.#remoteHints = null;
      if (cancel) this.#send("Vimkeys:hintsCancel");
      onExit();
    };
    const hints = {
      get alive() {
        return !done;
      },
      exit: () => end(true),
      finish: () => end(false),
      onKey: (event) => {
        const key = readHintKey(event);
        if (key === "cancel") {
          end(true);
        } else if (key) {
          this.#send("Vimkeys:hintsKey", { key });
        }
      },
    };
    this.#remoteHints = hints;
    this.#send("Vimkeys:hintsStart", { action });
    return hints;
  }

  #attach() {
    if (this.#keys) return;
    const win = this.contentWindow;
    if (!win || !this.#shouldTakeOver()) return;

    this.#keys = new KeyHandler({
      hintDocument: () => this.document,
      runBrowserCommand: (name) => this.sendAsyncMessage("Vimkeys:command", { name }),
      onModeChange: (mode) => this.#reportMode(mode),
      frameHints: (action, onExit) => this.#startFrameHints(action, onExit),
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
    this.#closeOverlay();
    this.#pendingHints = null;
    this.#remoteHints?.finish();
    this.#keys?.stop();
    this.#keys = null;
  }
}
