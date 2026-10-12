// tfm exposes no chooser flags on its CLI, so the portal's contract has nowhere else to live
import { writeFileSync } from "node:fs";

type Api = {
  cwd(): string;
  selection(): Array<{ path: string; isDir: boolean }>;
  notify(message: string, title?: string): void;
  commands(): Array<{ id: string; run: () => void }>;
  events: { on(evt: string, cb: () => void): () => void };
};

const OUT = process.env.TFM_CHOOSER_FILE ?? "";
const CWD_OUT = process.env.TFM_CWD_FILE ?? "";
const MODE = process.env.TFM_CHOOSER_MODE ?? "file";

// the portal reads one line per selection and treats an empty file as a failure, so a cancel is simply never writing
const emit = (api: Api, paths: string[]): void => {
  if (!paths.length) return;
  writeFileSync(OUT, `${paths.join("\n")}\n`);
  api.commands().find((c) => c.id === "quit")?.run();
};

export default {
  name: "chooser",
  version: "1.0.0",
  description: "writes the portal's selection file",
  apiVersion: 3,
  activate(api: Api) {
    if (!OUT) return {};
    // save and directory modes have nothing existing to pick, so the wrapper falls back to whichever folder tfm ended in
    const off = api.events.on("quit", () => {
      if (CWD_OUT) writeFileSync(CWD_OUT, `${api.cwd()}\n`);
    });
    const pick =
      (label: string, want: "dir" | "any") =>
      (sel: { paths: string[] }) => {
        const dirs = new Set(api.selection().filter((s) => s.isDir).map((s) => s.path));
        const paths = want === "dir" ? sel.paths.filter((p) => dirs.has(p)) : sel.paths;
        if (!paths.length) return [];
        const n = paths.length > 1 ? ` (${paths.length})` : "";
        return [{ label: `${label}${n}`, run: (ps: string[]) => emit(api, want === "dir" ? paths : ps) }];
      };
    return {
      fileMenu:
        MODE === "save"
          ? undefined
          : pick(MODE === "dir" ? "Use this folder" : "Use this file", MODE === "dir" ? "dir" : "any"),
      emptyAreaMenu: (area: { cwd: string }) => [
        { label: MODE === "save" ? "Save here" : "Use current folder", run: () => emit(api, [area.cwd]) },
      ],
      commands: [
        {
          id: "chooser:use",
          title: "Use selection",
          defaultBinds: ["return"],
          run: () => {
            const sel = api.selection().map((s) => s.path);
            if (!sel.length) return api.notify("Nothing selected", "chooser");
            emit(api, sel);
          },
        },
      ],
      deactivate: () => off(),
    };
  },
};
