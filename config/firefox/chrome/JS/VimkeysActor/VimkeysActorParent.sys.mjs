// Receives browser commands (x, t, /, H, …) from file:// pages and hands them
// to vimkeys.uc.js in the browser window that shows the page.

export class VimkeysActorParent extends JSWindowActorParent {
  receiveMessage(message) {
    if (message.name !== "Vimkeys:command") return;
    const name = message.data?.name;
    if (typeof name !== "string") return;

    const browser = this.browsingContext.top.embedderElement;
    const win = this.browsingContext.topChromeWindow ?? browser?.ownerGlobal;
    win?.vimkeys?.runBrowserCommand(name, browser);
  }
}
