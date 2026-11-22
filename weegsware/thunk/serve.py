"""thunk serve: one GPU queue, projects on disk, edit tools, a rewriter, the page."""

from __future__ import annotations

import base64
import json
import os
import re
import shutil
import signal
import socket
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.request
from dataclasses import asdict, dataclass, field
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import unquote, urlparse

import tools

HERE = Path(__file__).resolve().parent
UI = Path(os.environ.get("THUNK_UI", HERE / "ui.html"))
ROOT = Path(os.environ.get("THUNK_PROJECTS", Path.home() / "Pictures" / "thunk"))
MODELS = Path(
    os.environ.get(
        "THUNK_MODELS",
        Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share"))
        / "thunk"
        / "models",
    )
)
MANIFEST: dict[str, Any] = (
    json.loads(Path(os.environ["THUNK_MANIFEST"]).read_text())
    if os.environ.get("THUNK_MANIFEST")
    else {}
)
SD_SERVER = os.environ.get("THUNK_SD_SERVER", "sd-server")
LLAMA_SERVER = os.environ.get("THUNK_LLAMA_SERVER", "llama-server")
ESRGAN = os.environ.get("THUNK_ESRGAN", "realesrgan-ncnn-vulkan")
PORT = int(os.environ.get("THUNK_PORT", "8190"))
NAME_OK = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _.-]{0,63}$")
DEVICES = {
    "Pixel 6a": (1080, 2400),
    "Pixel 11": (1080, 2424),
    "Desktop 1440p": (2560, 1440),
    "Desktop 1080p": (1920, 1080),
}


def free_port() -> int:
    """Children sit on any free port, a fixed one can belong to another service."""
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return int(s.getsockname()[1])


SD_PORT = int(os.environ.get("THUNK_SD_PORT") or free_port())
LLM_PORT = free_port()
SD = f"http://127.0.0.1:{SD_PORT}"
LLM = f"http://127.0.0.1:{LLM_PORT}"


def model(role: str) -> Path:
    """A model file by its manifest role, as `thunk models fetch` placed it."""
    return MODELS / MANIFEST[role]["file"]


def log(msg: str) -> None:
    print(f"thunk: {msg}", file=sys.stderr, flush=True)


def call(
    base: str,
    method: str,
    path: str,
    body: dict[str, Any] | None = None,
    timeout: float = 60,
) -> Any:
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(base + path, data=data, method=method)
    req.add_header("content-type", "application/json")
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read() or b"null")


@dataclass
class Task:
    """One GPU job: a generation, an upscale, or a device finish. Run one at a time."""

    id: int
    project: str
    kind: str
    round: int
    index: int
    params: dict[str, Any]
    status: str = "queued"
    step: int = 0
    total: int = 0
    stage: str = ""
    preview: str | None = None
    sd_job: str | None = None
    print_id: int | None = None
    error: str | None = None
    cancel: bool = False


@dataclass
class Queue:
    tasks: list[Task] = field(default_factory=list)
    next_id: int = 1
    lock: threading.Lock = field(default_factory=threading.Lock)
    wake: threading.Event = field(default_factory=threading.Event)

    def add(
        self, project: str, kind: str, rnd: int, index: int, params: dict[str, Any]
    ) -> Task:
        with self.lock:
            t = Task(self.next_id, project, kind, rnd, index, params)
            self.next_id += 1
            self.tasks.append(t)
        self.wake.set()
        return t

    def snapshot(self) -> list[dict[str, Any]]:
        with self.lock:
            live = [t for t in self.tasks if t.status in ("queued", "running")]
            done = [t for t in self.tasks if t.status not in ("queued", "running")][
                -20:
            ]
            return [
                {k: v for k, v in asdict(t).items() if k != "params"}
                | {"label": t.params.get("label", "")}
                for t in done + live
            ]

    def stop(self, project: str | None, rnd: int | None) -> int:
        n = 0
        with self.lock:
            for t in self.tasks:
                if t.status not in ("queued", "running"):
                    continue
                if project is not None and t.project != project:
                    continue
                if rnd is not None and t.round != rnd:
                    continue
                t.cancel = True
                if t.status == "queued":
                    t.status = "cancelled"
                n += 1
        return n


Q = Queue()
files_lock = threading.Lock()


# ---------- projects on disk ----------


def pdir(name: str) -> Path:
    if not NAME_OK.match(name):
        raise ValueError(f"bad project name: {name!r}")
    return ROOT / name


def load_project(name: str) -> dict[str, Any]:
    d = pdir(name)
    f = d / "project.json"
    if not f.exists():
        raise FileNotFoundError(name)
    proj = json.loads(f.read_text())
    proj["prints"] = [
        json.loads(j.read_text()) for j in sorted((d / "prints").glob("*.json"))
    ]
    proj["refs"] = sorted(p.name for p in (d / "refs").glob("*") if p.is_file())
    return proj


def save_meta(name: str, meta: dict[str, Any]) -> None:
    keep = {k: v for k, v in meta.items() if k not in ("prints", "refs")}
    (pdir(name) / "project.json").write_text(json.dumps(keep, indent=2) + "\n")


def new_project(name: str) -> dict[str, Any]:
    d = pdir(name)
    if (d / "project.json").exists():
        raise FileExistsError(name)
    for sub in ("prints", "refs", "finals"):
        (d / sub).mkdir(parents=True, exist_ok=True)
    save_meta(name, {"name": name, "created": time.time(), "rounds": []})
    return load_project(name)


def print_path(name: str, pid: int) -> Path:
    return pdir(name) / "prints" / f"{pid:04d}.png"


def print_rec(name: str, pid: int) -> dict[str, Any]:
    return json.loads(print_path(name, pid).with_suffix(".json").read_text())


def source_bytes(name: str, src: str) -> bytes:
    """src is 'print:N' or 'ref:filename'."""
    kind, _, val = src.partition(":")
    if kind == "print":
        return print_path(name, int(val)).read_bytes()
    if kind == "ref":
        return (pdir(name) / "refs" / Path(val).name).read_bytes()
    raise ValueError(f"bad image source {src!r}")


def write_print(name: str, png: bytes, rec: dict[str, Any]) -> dict[str, Any]:
    with files_lock:
        d = pdir(name) / "prints"
        ids = [int(p.stem) for p in d.glob("*.json") if p.stem.isdigit()]
        pid = max(ids, default=0) + 1
        (d / f"{pid:04d}.png").write_bytes(png)
        out = {
            "id": pid,
            "file": f"prints/{pid:04d}.png",
            "kind": "gen",
            "round": 0,
            "index": 0,
            "made": time.time(),
            "keeps": [],
            "note": "",
            "marks": [],
        } | rec
        # the IHDR chunk holds the real size, which tools and upscales change
        out["width"] = int.from_bytes(png[16:20], "big")
        out["height"] = int.from_bytes(png[20:24], "big")
        (d / f"{pid:04d}.json").write_text(json.dumps(out, indent=2) + "\n")
    return out


def derived(
    name: str,
    parent_id: int,
    png: bytes,
    tool: str,
    extra: dict[str, Any] | None = None,
) -> dict[str, Any]:
    p = print_rec(name, parent_id)
    rec = {k: p.get(k) for k in ("prompt", "said", "seed", "steps", "round")} | {
        "kind": "edit",
        "from": parent_id,
        "tool": tool,
    }
    return write_print(name, png, rec | (extra or {}))


# ---------- the GPU worker ----------


def gen_once(
    t: Task, p: dict[str, Any], init: bytes | None = None
) -> tuple[bytes, float] | None:
    """One image from sd-server with cancel and preview; None when failed or stopped."""
    body: dict[str, Any] = {
        "prompt": p["prompt"],
        "width": p["width"],
        "height": p["height"],
        "seed": p["seed"],
        "batch_count": 1,
        "sample_params": {
            "sample_steps": p.get("steps", 8),
            "guidance": {"txt_cfg": 1.0},
        },
        "vae_tiling_params": {"enabled": True},
        "preview": "proj",
    }
    if init is None and p.get("start"):
        init = source_bytes(t.project, p["start"])
    if init is not None:
        body["init_image"] = base64.b64encode(init).decode()
        body["strength"] = p["strength"]
    if p.get("mask_b64"):
        body["mask_image"] = p["mask_b64"]
    job = call(SD, "POST", "/sdcpp/v1/img_gen", body)
    t.sd_job = job["id"]
    t.preview, t.step, t.total = None, 0, 0
    asked = False
    while True:
        if t.cancel and not asked:
            call(SD, "POST", f"/sdcpp/v1/jobs/{t.sd_job}/cancel")
            asked = True
        j = call(SD, "GET", f"/sdcpp/v1/jobs/{t.sd_job}")
        prog = j.get("progress") or {}
        t.stage = prog.get("stage") or ""
        if prog.get("unit") == "steps":
            t.step, t.total = prog.get("completed") or 0, prog.get("total") or 0
        pv = j.get("preview")
        if pv and pv.get("b64_json"):
            t.preview = pv["b64_json"]
        if j["status"] == "completed":
            png = base64.b64decode(j["result"]["images"][0]["b64_json"])
            return png, round(
                ((j.get("completed") or 0) - (j.get("started") or 0)) / 1000, 1
            )
        if j["status"] in ("failed", "cancelled"):
            t.status = j["status"]
            t.error = (j.get("error") or {}).get("message")
            return None
        time.sleep(0.4)


def run_gen(t: Task) -> None:
    p = t.params
    got = gen_once(t, p)
    if got is None:
        return
    png, secs = got
    if p.get("paste_marks"):
        # only the marked circles may change, the model's round trip touches every pixel
        png = tools.paste_spots(
            source_bytes(t.project, p["start"]), png, p["paste_marks"]
        )
    rec = {
        "kind": p.get("kind", "gen"),
        "round": t.round,
        "index": t.index,
        "prompt": p["prompt"],
        "said": p.get("said", ""),
        "seed": p["seed"],
        "steps": p.get("steps", 8),
        "start": p.get("start"),
        "strength": p.get("strength") if p.get("start") else None,
        "seconds": secs,
    } | {k: p[k] for k in ("from", "tool", "device", "box") if k in p}
    t.print_id = write_print(t.project, png, rec)["id"]
    t.status = "done"


def run_fit(t: Task) -> None:
    """A stitched guide used only as the start image, then whole-canvas redraws.

    The guide is kept for provenance and never offered as a result.
    """
    p = t.params
    src = print_path(t.project, p["from"]).read_bytes()
    canvas, mask, box = tools.fit_canvas(src, p["width"], p["height"])
    plain = tools.plain_border(src)
    if plain is not None:
        guide_png = tools.fit_plain(src, p["width"], p["height"], plain)
    else:
        t.stage = "building the starting image"
        edge = p | {
            "prompt": p["edge_prompt"],
            "strength": 1.0,
            "mask_b64": base64.b64encode(mask).decode(),
        }
        got = gen_once(t, edge, init=canvas)
        if got is None:
            return
        guide_png = got[0]
    guide = write_print(
        t.project,
        guide_png,
        {
            "kind": "guide",
            "round": t.round,
            "index": 0,
            "prompt": p.get("edge_prompt") or "",
            "seed": p["seed"],
            "from": p["from"],
            "tool": f"starting image for {p['device']}",
            "device": p["device"],
        },
    )
    t.print_id = guide["id"]
    for i, s in enumerate(p["strengths"]):
        Q.add(
            t.project,
            "gen",
            t.round,
            i + 1,
            {
                "prompt": p["prompt"],
                "width": p["width"],
                "height": p["height"],
                "seed": p["seed"],
                "start": f"print:{guide['id']}",
                "strength": s,
                "from": p["from"],
                "tool": f"refit for {p['device']}",
                "device": p["device"],
                "box": box,
                "label": f"redraw for {p['device']} at {s}",
            },
        )
    t.status = "done"


def esrgan(src: Path, t: Task) -> bytes | None:
    tmp = src.with_name(f".up-{t.id}.png")
    t.stage = "upscaling"
    r = subprocess.run(
        [ESRGAN, "-i", str(src), "-o", str(tmp), "-s", "4", "-n", "realesrgan-x4plus"],
        capture_output=True,
        text=True,
        check=False,
    )
    if r.returncode != 0 or not tmp.exists():
        t.status, t.error = "failed", (r.stderr or "upscale failed")[-400:]
        return None
    b = tmp.read_bytes()
    tmp.unlink()
    return b


def run_upscale(t: Task) -> None:
    pid = int(t.params["print"])
    b = esrgan(print_path(t.project, pid), t)
    if b is None:
        return
    t.print_id = derived(t.project, pid, b, "upscale x4")["id"]
    t.status = "done"


def run_finish(t: Task) -> None:
    """ESRGAN when the device is bigger than the print, then crop and resize exact."""
    pid, dev = int(t.params["print"]), t.params["device"]
    w, h = DEVICES[dev] if dev in DEVICES else tuple(t.params["size"])
    rec = print_rec(t.project, pid)
    src = print_path(t.project, pid)
    png = src.read_bytes()
    if rec["width"] < w or rec["height"] < h:
        up = esrgan(src, t)
        if up is None:
            return
        png = up
    t.stage = "finishing"
    out = derived(
        t.project, pid, tools.finish(png, w, h), f"finished for {dev}", {"device": dev}
    )
    shutil.copyfile(
        print_path(t.project, out["id"]),
        pdir(t.project) / "finals" / f"{out['id']:04d}.png",
    )
    t.print_id = out["id"]
    t.status = "done"


def worker() -> None:
    sd_ready.wait()
    while True:
        Q.wake.wait(1.0)
        Q.wake.clear()
        while True:
            with Q.lock:
                t = next((x for x in Q.tasks if x.status == "queued"), None)
                if t is not None:
                    t.status = "running"
            if t is None:
                break
            try:
                {"upscale": run_upscale, "finish": run_finish, "fit": run_fit}.get(
                    t.kind, run_gen
                )(t)
            except Exception as e:  # a failed task must not kill the queue
                t.status, t.error = "failed", f"{type(e).__name__}: {e}"
                log(f"task {t.id} failed: {t.error}")


# ---------- child servers ----------

children: list[subprocess.Popen[bytes]] = []
sd_ready = threading.Event()
sd_failed = threading.Event()
llm_ready = threading.Event()


def spawn(
    args: list[str], logname: str, env: dict[str, str] | None = None
) -> subprocess.Popen[bytes]:
    logf = open(ROOT / logname, "ab")  # noqa: SIM115
    p = subprocess.Popen(args, env=env, stdout=logf, stderr=subprocess.STDOUT)
    children.append(p)
    return p


def wait_for(
    p: subprocess.Popen[bytes],
    base: str,
    path: str,
    ok: threading.Event,
    name: str,
    failed: threading.Event | None = None,
) -> None:
    while p.poll() is None:
        try:
            call(base, "GET", path, timeout=5)
            ok.set()
            log(f"{name} ready")
            return
        except (
            urllib.error.URLError,
            ConnectionError,
            TimeoutError,
            json.JSONDecodeError,
        ):
            time.sleep(1)
    if failed is not None:
        failed.set()
    log(f"{name} exited before it was ready, see its log in {ROOT}")


def start_children(rewriter: bool) -> None:
    env = os.environ.copy()
    if os.environ.get("THUNK_GPU", "rocm") == "rocm":
        # gfx1032 has no kernels of its own; 10.3.0 maps it onto gfx1030
        env.setdefault("HSA_OVERRIDE_GFX_VERSION", "10.3.0")
        env.setdefault("HIP_VISIBLE_DEVICES", "0")
    sd = spawn(
        [
            SD_SERVER,
            "--listen-ip",
            "127.0.0.1",
            "--listen-port",
            str(SD_PORT),
            "--diffusion-model",
            str(model("diffusion")),
            "--vae",
            str(model("vae")),
            "--llm",
            str(model("llm")),
            "--offload-to-cpu",
            "--vae-tiling",
        ],
        ".sd-server.log",
        env,
    )
    log(f"sd-server pid {sd.pid} loading the image model on port {SD_PORT}")
    threading.Thread(
        target=wait_for,
        args=(sd, SD, "/sdcpp/v1/capabilities", sd_ready, "image model", sd_failed),
        daemon=True,
    ).start()
    if not rewriter:
        return
    threads = max(4, (os.cpu_count() or 8) // 2)
    weights = ["-m", str(model("llm"))]
    if VISION:
        weights = [
            "-m",
            str(model("rewriter")),
            "--mmproj",
            str(model("rewriter_vision")),
        ]
    llm = spawn(
        [
            LLAMA_SERVER,
            *weights,
            "--host",
            "127.0.0.1",
            "--port",
            str(LLM_PORT),
            "-t",
            str(threads),
            "-c",
            "8192",
            "-np",
            "1",
            "--no-warmup",
        ],
        ".rewriter.log",
    )
    kind = "with vision" if VISION else "no vision"
    log(f"rewriter pid {llm.pid} ({weights[1]}, {kind}, cpu) on port {LLM_PORT}")
    threading.Thread(
        target=wait_for,
        args=(llm, LLM, "/v1/models", llm_ready, "rewriter"),
        daemon=True,
    ).start()


def stop_all(*_: Any) -> None:
    for p in children:
        if p.poll() is None:
            p.terminate()
    for p in children:
        try:
            p.wait(10)
        except subprocess.TimeoutExpired:
            p.kill()
    os._exit(0)


# ---------- the rewriter ----------

RULES = (HERE / "rules.md").read_text() if (HERE / "rules.md").exists() else ""
# without the vision files the image model's own text encoder rewrites, blind
VISION = all(
    r in MANIFEST and model(r).exists() for r in ("rewriter", "rewriter_vision")
)


def rewrite(name: str, b: dict[str, Any]) -> dict[str, Any]:
    if not llm_ready.is_set():
        raise ValueError("the rewriter is still loading")
    proj = load_project(name)
    said = str(b.get("said", "")).strip() or "(nothing new)"
    lines = [f"What they want, in their words:\n{said}"]
    prev = str(b.get("prompt", "")).strip()
    if prev:
        lines.append(f"The prompt that made the last round:\n{prev}")
    rnd = b.get("round")
    images: list[dict[str, Any]] = []
    if rnd is not None:
        prints = sorted(
            (
                p
                for p in proj["prints"]
                if p.get("round") == rnd and p.get("kind") == "gen"
            ),
            key=lambda p: p["index"],
        )
        fb = []
        for p in prints:
            bits = []
            if p.get("keeps"):
                bits.append("keep its " + ", ".join(p["keeps"]))
            if p.get("note"):
                bits.append(f"note: {p['note']}")
            for mk in p.get("marks") or []:
                x, y = mk["x"], mk["y"]
                where = "left" if x < 0.4 else "right" if x > 0.6 else "centre"
                where += " " + ("top" if y < 0.4 else "bottom" if y > 0.6 else "middle")
                bits.append(f"something wrong at the {where}: {mk.get('note', '')}")
            if bits:
                fb.append(f"Print {p['index']}: " + "; ".join(bits))
                if VISION and b.get("look"):
                    images.append({"type": "text", "text": f"Print {p['index']}:"})
                    images.append(
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": tools.small_jpeg(
                                    print_path(name, p["id"]).read_bytes()
                                )
                            },
                        }
                    )
        if fb:
            lines.append("Their feedback on the last round's prints:\n" + "\n".join(fb))
    content: Any = "\n\n".join(lines)
    if VISION and rnd is not None and images:
        content = [
            {
                "type": "text",
                "text": content
                + "\n\nHere are the prints they gave feedback on. Look at them: keep"
                " what they liked as you see it in the picture, and describe it"
                " concretely.",
            },
            *images,
        ]
    msgs = [{"role": "system", "content": RULES}, {"role": "user", "content": content}]
    r = call(
        LLM,
        "POST",
        "/v1/chat/completions",
        {
            "messages": msgs,
            "temperature": 0.3,
            "max_tokens": 400,
            "chat_template_kwargs": {"enable_thinking": False},
        },
        timeout=300,
    )
    text = r["choices"][0]["message"]["content"].strip().strip('"')
    return {"prompt": text}


# ---------- http ----------


class H(BaseHTTPRequestHandler):
    def log_message(self, format: str, *args: Any) -> None:  # noqa: A002
        pass

    def send_json(self, obj: Any, code: int = 200) -> None:
        b = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(b)))
        self.send_header("cache-control", "no-store")
        self.end_headers()
        self.wfile.write(b)

    def body(self) -> dict[str, Any]:
        n = int(self.headers.get("content-length") or 0)
        return json.loads(self.rfile.read(n) or b"{}") if n else {}

    def do_GET(self) -> None:  # noqa: N802
        path = unquote(urlparse(self.path).path)
        try:
            if path == "/":
                b = UI.read_bytes()
                self.send_response(200)
                self.send_header("content-type", "text/html; charset=utf-8")
                self.send_header("cache-control", "no-store")
                self.end_headers()
                self.wfile.write(b)
            elif path == "/app.js":
                b = (HERE / "app.js").read_bytes()
                self.send_response(200)
                self.send_header("content-type", "text/javascript; charset=utf-8")
                self.send_header("cache-control", "no-store")
                self.end_headers()
                self.wfile.write(b)
            elif path == "/api/state":
                self.send_json(
                    {
                        "ready": sd_ready.is_set(),
                        "failed": sd_failed.is_set(),
                        "rewriter": llm_ready.is_set(),
                        "vision": VISION,
                        "queue": Q.snapshot(),
                        "root": str(ROOT),
                        "devices": DEVICES,
                    }
                )
            elif path == "/api/fonts":
                self.send_json(tools.fonts())
            elif path == "/api/projects":
                names = sorted(
                    (p.parent.name for p in ROOT.glob("*/project.json")),
                    key=lambda n: -(ROOT / n / "project.json").stat().st_mtime,
                )
                self.send_json(names)
            elif path.startswith("/api/p/"):
                self.send_json(load_project(path.split("/")[3]))
            elif path.startswith("/files/"):
                _, _, name, *rest = path.split("/")
                f = (pdir(name) / "/".join(rest)).resolve()
                if not f.is_relative_to(pdir(name).resolve()) or not f.is_file():
                    self.send_json({"error": "not found"}, 404)
                    return
                b = f.read_bytes()
                self.send_response(200)
                ext = f.suffix.lower().lstrip(".")
                self.send_header(
                    "content-type", f"image/{ {'jpg': 'jpeg'}.get(ext, ext) }"
                )
                self.send_header("content-length", str(len(b)))
                self.send_header("cache-control", "max-age=3600")
                self.end_headers()
                self.wfile.write(b)
            else:
                self.send_json({"error": "not found"}, 404)
        except FileNotFoundError as e:
            self.send_json({"error": f"not found: {e}"}, 404)
        except (ValueError, OSError) as e:
            self.send_json({"error": str(e)}, 400)

    def do_POST(self) -> None:  # noqa: N802
        path = unquote(urlparse(self.path).path)
        parts = path.split("/")
        try:
            b = self.body()
            if path == "/api/projects":
                self.send_json(new_project(str(b.get("name", "")).strip()))
            elif path == "/api/stop":
                self.send_json({"stopped": Q.stop(b.get("project"), b.get("round"))})
            elif len(parts) >= 5 and parts[1] == "api" and parts[2] == "p":
                self.project_action(parts[3], parts[4], parts[5:], b)
            else:
                self.send_json({"error": "not found"}, 404)
        except FileExistsError as e:
            self.send_json({"error": f"a project called {e} already exists"}, 409)
        except FileNotFoundError as e:
            self.send_json({"error": f"not found: {e}"}, 404)
        except (ValueError, KeyError, OSError, urllib.error.URLError) as e:
            self.send_json({"error": str(e)}, 400)

    def project_action(
        self, name: str, action: str, rest: list[str], b: dict[str, Any]
    ) -> None:
        meta = load_project(name)
        if action == "round":
            self.send_json(make_round(name, meta, b))
        elif action == "print":
            f = print_path(name, int(rest[0])).with_suffix(".json")
            rec = json.loads(f.read_text())
            for k in ("keeps", "note", "marks"):
                if k in b:
                    rec[k] = b[k]
            f.write_text(json.dumps(rec, indent=2) + "\n")
            self.send_json(rec)
        elif action == "ref":
            fname = Path(str(b["name"])).name or "ref.png"
            (pdir(name) / "refs" / fname).write_bytes(
                base64.b64decode(str(b["data"]).split(",", 1)[-1])
            )
            self.send_json({"ref": fname})
        elif action == "final":
            pid = int(b["print"])
            dst = pdir(name) / "finals" / f"{pid:04d}.png"
            shutil.copyfile(print_path(name, pid), dst)
            self.send_json({"final": str(dst)})
        elif action == "rewrite":
            self.send_json(rewrite(name, b))
        elif action == "similar":
            a, c = (
                print_path(name, int(b["a"])).read_bytes(),
                print_path(name, int(b["b"])).read_bytes(),
            )
            self.send_json(
                {
                    "ssim": tools.similarity(
                        a, c, print_rec(name, int(b["b"])).get("box")
                    )
                }
            )
        elif action == "tool":
            self.send_json(run_tool(name, meta, b))
        else:
            self.send_json({"error": "unknown action"}, 404)


def make_round(name: str, meta: dict[str, Any], b: dict[str, Any]) -> dict[str, Any]:
    prompt = str(b.get("prompt", "")).strip()
    if not prompt:
        raise ValueError("the prompt is empty")
    count = max(1, min(8, int(b.get("count", 4))))
    width, height = int(b.get("width", 768)), int(b.get("height", 768))
    if width % 16 or height % 16:
        raise ValueError("width and height must be multiples of 16")
    seed = b.get("seed")
    seed = int(seed) if seed not in (None, "") else int.from_bytes(os.urandom(3), "big")
    starts: list[str | None] = list(
        b.get("starts") or ([b["start"]] if b.get("start") else [])
    ) or [None]
    start = starts[0]
    strengths: list[float | None] = (
        [float(s) for s in (b.get("strengths") or [0.75])] if start else [None]
    )
    rnd = len(meta["rounds"]) + 1
    meta["rounds"].append(
        {
            "n": rnd,
            "said": b.get("said", ""),
            "prompt": prompt,
            "start": start,
            "starts": [x for x in starts if x],
            "strengths": strengths if start else [],
            "count": count,
            "seed": seed,
            "width": width,
            "height": height,
            "made": time.time(),
            "kind": b.get("round_kind", "round"),
        }
    )
    save_meta(name, meta)
    idx = 0
    for st in starts:
        for s in strengths if st else [None]:
            for i in range(count):
                idx += 1
                params = {
                    "prompt": prompt,
                    "said": b.get("said", ""),
                    "width": width,
                    "height": height,
                    "seed": seed + i,
                    "steps": int(b.get("steps", 8)),
                    "start": st,
                    "strength": s,
                    "label": f"round {rnd}",
                } | {k: b[k] for k in ("from", "tool", "device") if k in b}
                Q.add(name, "gen", rnd, idx, params)
    return {"round": rnd, "prints": idx, "seed": seed}


def run_tool(name: str, meta: dict[str, Any], b: dict[str, Any]) -> dict[str, Any]:
    tool = b["tool"]
    pid = int(b["print"])
    src = print_path(name, pid).read_bytes()
    rec = print_rec(name, pid)
    if tool == "cutout":
        if b.get("method") == "dark":
            out = tools.cutout_dark(
                src, float(b.get("strength", 1.0)), float(b.get("glow", 1.0))
            )
            return {"print": derived(name, pid, out, "cut out, dark background")}
        out = tools.cutout(
            src,
            float(b.get("tolerance", 18)),
            rec["marks"] if b.get("clear_marks") else [],
        )
        return {"print": derived(name, pid, out, "cut out")}
    if tool == "icons":
        sizes = [int(x) for x in b.get("sizes") or [16, 32, 48, 64, 128, 256, 512]]
        files = tools.icon_set(src, sizes, float(b.get("pad", 0.04)))
        d = pdir(name) / "finals" / f"icons-{pid:04d}"
        d.mkdir(parents=True, exist_ok=True)
        for fn, data in files.items():
            (d / fn).write_bytes(data)
        z = shutil.make_archive(str(d), "zip", root_dir=d)
        rel = f"finals/icons-{pid:04d}"
        lo = tools.load(src)[:, :, 3].min()
        return {
            "icons": {
                "dir": str(d),
                "zip": z,
                "transparent": bool(lo < 255),
                "files": [
                    f"{rel}/{fn}" for fn in sorted(files, key=lambda f: (len(f), f))
                ],
            }
        }
    if tool == "fill":
        if not rec["marks"]:
            raise ValueError("mark the spots first")
        return {
            "print": derived(
                name,
                pid,
                tools.fill_spots(src, rec["marks"]),
                "spots filled",
                {"marks": []},
            )
        }
    if tool == "redraw":
        if not rec["marks"]:
            raise ValueError("mark the spots first")
        mask = tools.spots_mask_png(rec["width"], rec["height"], rec["marks"])
        rnd = len(meta["rounds"]) + 1
        meta["rounds"].append(
            {
                "n": rnd,
                "said": "",
                "prompt": rec.get("prompt", ""),
                "start": f"print:{pid}",
                "strengths": [float(b.get("strength", 0.9))],
                "count": int(b.get("count", 2)),
                "seed": rec.get("seed"),
                "width": rec["width"],
                "height": rec["height"],
                "made": time.time(),
                "kind": "redraw spots",
            }
        )
        save_meta(name, meta)
        base_seed = int(rec.get("seed") or 0)
        for i in range(int(b.get("count", 2))):
            Q.add(
                name,
                "gen",
                rnd,
                i + 1,
                {
                    "prompt": str(b.get("prompt") or rec.get("prompt") or ""),
                    "width": rec["width"],
                    "height": rec["height"],
                    "seed": base_seed + 100 + i,
                    "start": f"print:{pid}",
                    "strength": float(b.get("strength", 0.9)),
                    "mask_b64": base64.b64encode(mask).decode(),
                    "from": pid,
                    "tool": "spots redrawn",
                    "label": f"redraw spots on print {pid}",
                    "paste_marks": rec["marks"],
                },
            )
        return {"round": rnd}
    if tool == "swap":
        donor = print_path(name, int(b["donor"])).read_bytes()
        out, proof = tools.swap(src, donor, b["src"], b["dst"])
        return {
            "print": derived(
                name, pid, out, f"swap from print {b['donor']}", {"proof": proof}
            ),
            "proof": proof,
        }
    if tool == "text":
        return {
            "print": derived(name, pid, tools.text(src, b), f"text: {b['text'][:30]}")
        }
    if tool == "fit":
        dev = str(b["device"])
        dw, dh = DEVICES[dev] if dev in DEVICES else (int(b["w"]), int(b["h"]))
        gw, gh = tools.gen_size(dw, dh)
        shape = (
            "Tall vertical phone wallpaper" if dh > dw else "Wide landscape wallpaper"
        )
        edge_prompt = str(b.get("edge_prompt") or "").strip()
        # the original's exact words reproduce its look
        framing = (
            f"{shape} composition"
            + (f": {edge_prompt.rstrip('.')}" if edge_prompt else "")
            + ". One continuous scene. "
        )
        prompt = framing + (rec.get("prompt") or "")
        strengths = [float(x) for x in (b.get("strengths") or [0.65, 0.75])]
        if tools.plain_border(src) is None and not edge_prompt:
            raise ValueError(
                "say what goes in the new space first: what's above, below and"
                " beside the picture"
            )
        rnd = len(meta["rounds"]) + 1
        meta["rounds"].append(
            {
                "n": rnd,
                "said": f"fit print {pid} to {dev}",
                "prompt": prompt,
                "start": None,
                "strengths": strengths,
                "count": 1,
                "seed": rec.get("seed"),
                "width": gw,
                "height": gh,
                "made": time.time(),
                "kind": f"fit to {dev}",
                "from": pid,
            }
        )
        save_meta(name, meta)
        Q.add(
            name,
            "fit",
            rnd,
            0,
            {
                "prompt": prompt,
                "width": gw,
                "height": gh,
                "seed": int(rec.get("seed") or 0),
                "from": pid,
                "device": dev,
                "strengths": strengths,
                "edge_prompt": edge_prompt,
                "label": f"fit to {dev}, new edges first",
            },
        )
        return {"round": rnd, "prints": len(strengths)}
    if tool == "finish":
        t = Q.add(
            name,
            "finish",
            rec.get("round", 0),
            0,
            {
                "print": pid,
                "device": b["device"],
                "size": b.get("size"),
                "label": f"finish for {b['device']}",
            },
        )
        return {"task": t.id}
    if tool == "upscale":
        t = Q.add(
            name,
            "upscale",
            rec.get("round", 0),
            0,
            {"print": pid, "label": "upscale 4x"},
        )
        return {"task": t.id}
    raise ValueError(f"unknown tool {tool}")


def main() -> None:
    ROOT.mkdir(parents=True, exist_ok=True)
    signal.signal(signal.SIGTERM, stop_all)
    signal.signal(signal.SIGINT, stop_all)
    start_children(rewriter=os.environ.get("THUNK_NO_REWRITER") is None)
    threading.Thread(target=worker, daemon=True).start()
    srv = ThreadingHTTPServer(("127.0.0.1", PORT), H)
    log(f"page at http://127.0.0.1:{PORT}  projects in {ROOT}")
    srv.serve_forever()


if __name__ == "__main__":
    main()
