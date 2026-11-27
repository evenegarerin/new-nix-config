import { makeLabels } from "./core.sys.mjs";

const MODES = new Set(["visual", "insert", "hints", "help"]);
const HINT_MESSAGES = new Set(["Vimkeys:hintsStart", "Vimkeys:hintsKey", "Vimkeys:hintsCancel"]);
const hintSessions = new Map();

function sendTo(context, actorName, name, data = {}) {
  try {
    context.currentWindowGlobal?.getActor(actorName).sendAsyncMessage(name, data);
  } catch {}
}

function endHintSession(topId) {
  const session = hintSessions.get(topId);
  if (!session) return;
  hintSessions.delete(topId);
  for (const context of session.contexts) sendTo(context, session.actorName, "Vimkeys:hintsEnd");
}

async function collectHints(context, actorName, action) {
  try {
    const reply = await context.currentWindowGlobal?.getActor(actorName)
      .sendQuery("Vimkeys:hintsCollect", { action });
    return reply ?? null;
  } catch {
    return null;
  }
}

async function startHintSession(actor, action) {
  const top = actor.browsingContext.top;
  endHintSession(top.id);
  const contexts = top.getAllBrowsingContextsInSubtree();
  const session = { actorName: actor.name, contexts, entries: [], typed: "", ready: false };
  hintSessions.set(top.id, session);

  const replies = await Promise.all(contexts.map((context) => collectHints(context, actor.name, action)));
  if (hintSessions.get(top.id) !== session) return;

  const byId = new Map(contexts.map((context, i) => [context.id, replies[i]]));
  const shown = (context) => {
    if (!byId.get(context.id)) return false;
    if (context === top) return true;
    const parent = context.parent;
    return !!parent && !!byId.get(parent.id)?.frames?.includes(context.id) && shown(parent);
  };

  const visible = contexts.filter((context) => byId.get(context.id)?.count && shown(context));
  const total = visible.reduce((sum, context) => sum + byId.get(context.id).count, 0);
  if (!total) {
    endHintSession(top.id);
    return;
  }

  const labels = makeLabels(total);
  let offset = 0;
  for (const context of visible) {
    const count = byId.get(context.id).count;
    const slice = labels.slice(offset, offset + count);
    offset += count;
    session.entries.push({ context, labels: slice });
    sendTo(context, actor.name, "Vimkeys:hintsShow", { labels: slice });
  }
  session.ready = true;
}

function typeHintKey(topId, key) {
  const session = hintSessions.get(topId);
  if (!session?.ready) return;
  const typed = key === "back" ? session.typed.slice(0, -1) : session.typed + key;
  const matches = session.entries.flatMap(({ context, labels }) =>
    labels.filter((label) => label.startsWith(typed)).map((label) => ({ context, label })));
  if (!matches.length) return;
  session.typed = typed;

  if (matches.length === 1) {
    const { context, label } = matches[0];
    hintSessions.delete(topId);
    for (const other of session.contexts) {
      if (other !== context) sendTo(other, session.actorName, "Vimkeys:hintsEnd");
    }
    sendTo(context, session.actorName, "Vimkeys:hintsActivate", { label });
    return;
  }
  for (const { context } of session.entries) {
    sendTo(context, session.actorName, "Vimkeys:hintsFilter", { typed });
  }
}

export class VimkeysActorParent extends JSWindowActorParent {
  receiveMessage(message) {
    if (HINT_MESSAGES.has(message.name)) {
      this.#handleHints(message);
      return;
    }

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

  #handleHints(message) {
    const topId = this.browsingContext.top.id;
    if (message.name === "Vimkeys:hintsStart") {
      startHintSession(this, message.data?.action ?? "open").catch((err) => {
        console.error("[vimkeys]", err);
        endHintSession(topId);
      });
    } else if (message.name === "Vimkeys:hintsKey") {
      const key = message.data?.key;
      if (typeof key === "string") typeHintKey(topId, key);
    } else {
      endHintSession(topId);
    }
  }
}
