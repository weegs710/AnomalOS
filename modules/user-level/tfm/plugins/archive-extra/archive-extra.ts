// tfm's extract child runs with stdin ignored and CompressionFormat === ArchiveFormat, so neither rar nor a password is reachable through its own tables
import { spawnSync } from "node:child_process";
import { mkdtempSync, readdirSync, renameSync, rmSync, existsSync } from "node:fs";
import * as path from "node:path";

type Api = {
  cwd(): string;
  notify(message: string, title?: string): void;
  log(message: string): void;
  ui: { prompt(o: { title: string; placeholder?: string; okLabel?: string }): Promise<string | null> };
};

const PW_EXT = new Set([".7z", ".zip"]);
const ext = (p: string): string => path.extname(p).toLowerCase();

// conflicts are skipped rather than replaced because a plugin cannot push an undo batch, so a clobber here would be unrecoverable
const stagedExtract = (api: Api, tool: string, argvFor: (stage: string) => string[], label: string): void => {
  const dest = api.cwd();
  if (!existsSync(dest)) return api.notify(`${label}: destination is gone`, "archive");
  const stage = mkdtempSync(path.join(dest, ".tfm-x-"));
  try {
    const res = spawnSync(tool, argvFor(stage), { stdio: ["ignore", "ignore", "pipe"], timeout: 600_000 });
    const lines = (res.stderr?.toString() ?? "").split("\n");
    const err = lines.filter((l: string) => /^ERROR|error/i.test(l))[0] ?? "";
    // a missing binary reports status null rather than a code, and both tools exit 1 on per-entry warnings while still writing every other member
    if (res.error || (res.status !== null && res.status > 1)) {
      api.log(`${label} failed (${res.status ?? res.error}): ${err}`);
      return api.notify(err || `${label} failed: ${tool}`, "archive");
    }
    let moved = 0;
    let clashed = 0;
    for (const name of readdirSync(stage)) {
      const target = path.join(dest, name);
      if (existsSync(target)) {
        clashed++;
        continue;
      }
      renameSync(path.join(stage, name), target);
      moved++;
    }
    const tail = clashed ? `, ${clashed} skipped (already here)` : "";
    api.notify(
      moved ? `Extracted ${moved} item${moved === 1 ? "" : "s"}${tail}` : `Nothing extracted${tail}`,
      "archive",
    );
  } finally {
    rmSync(stage, { recursive: true, force: true });
  }
};

export default {
  name: "archive-extra",
  version: "1.0.0",
  description: "rar extraction and password-protected archives",
  apiVersion: 3,
  activate(api: Api) {
    return {
      fileMenu: (sel: { paths: string[] }) => {
        const rars = sel.paths.filter((p) => ext(p) === ".rar");
        const pw = sel.paths.filter((p) => PW_EXT.has(ext(p)));
        const rows: Array<{ label: string; run: (paths: string[]) => void }> = [];
        if (rars.length)
          rows.push({
            label: `Extract rar here${rars.length > 1 ? ` (${rars.length})` : ""}`,
            run: () => {
              for (const f of rars)
                stagedExtract(api, "bsdtar", (s) => ["-x", "-f", f, "-C", s, "--no-same-owner"], "rar extract");
            },
          });
        if (pw.length)
          rows.push({
            label: "Extract encrypted…",
            run: () => {
              void (async () => {
                const secret = await api.ui.prompt({ title: "Archive password", okLabel: "Extract" });
                if (!secret) return;
                for (const f of pw)
                  stagedExtract(api, "7zz", (s) => ["x", "-y", `-p${secret}`, `-o${s}`, f], "password extract");
              })();
            },
          });
        return rows;
      },
    };
  },
};
