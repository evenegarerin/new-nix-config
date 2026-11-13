// Receives browser commands (x, t, /, H, …) from file:// pages and hands them
// to vimkeys.uc.js in the browser window that shows the page.

const MODES = new Set(["visual", "insert"]);

export class VimkeysActorParent extends JSWindowActorParent {
  receiveMessage(message) {
    const browser = this.browsingContext.top.embedderElement;
    const win = this.browsingContext.topChromeWindow ?? browser?.ownerGlobal;
    if (!win?.vimkeys) return;

    if (message.name === "Vimkeys:mode") {
      if (browser && browser !== win.gBrowser?.selectedBrowser) return;
      const mode = message.data?.mode;
      win.vimkeys.setMode(MODES.has(mode) ? mode : null, this.browsingContext.id);
      return;
    }

    if (message.name !== "Vimkeys:command") return;
    const name = message.data?.name;
    if (typeof name !== "string") return;
    win.vimkeys.runBrowserCommand(name, browser);
  }
}
