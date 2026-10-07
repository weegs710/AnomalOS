"""Feed Umbriel's effect-audio input from what is playing right now.

Taps the default sink's monitor with pw-record (read only, nothing is played),
turns each 20 ms window into one level between 0 and 1, and sends it to the
compositor 50 times a second over the effect-audio IPC connection described in
docs/user/ipc.md. It keeps sending during silence, and reconnects after a lock,
a dropped connection or a compositor restart.

usage: audio_producer.py [--socket PATH] [--target SINK_NAME] [--gain 16]
  --socket  defaults to $UMBRIEL_SOCKET
  --target  capture this sink's monitor instead of following the default sink
  --gain    level = sqrt(min(1, gain * rms)); raise it for quiet music
"""
import argparse
import json
import math
import os
import signal
import socket
import struct
import subprocess
import sys
import threading
import time

RATE = 48000
WINDOW = RATE * 20 // 1000  # 20 ms of mono f32
SEND_INTERVAL = 0.02
STALE_AFTER = 0.15  # no audio buffers for this long counts as silence


def log(msg):
    print(f'{time.strftime("%H:%M:%S")} {msg}', file=sys.stderr, flush=True)


class Meter:
    """pw-record reader thread; `level` is always the latest smoothed value"""

    def __init__(self, target, gain):
        self.target, self.gain = target, gain
        self.level, self.stamp = 0.0, 0.0
        self.stop = threading.Event()
        self.proc = None
        threading.Thread(target=self.run, daemon=True).start()

    def spawn(self):
        cmd = ['pw-record', '--raw', '--rate', str(RATE), '--channels', '1', '--format', 'f32',
               '--latency', '20ms', '-P', 'stream.capture.sink=true']
        if self.target:
            cmd += ['--target', self.target]
        cmd += ['-']
        return subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)

    def run(self):
        level = 0.0
        while not self.stop.is_set():
            self.proc = self.spawn()
            log('capture started')
            while not self.stop.is_set():
                raw = self.proc.stdout.read(WINDOW * 4)
                if len(raw) < WINDOW * 4:
                    break
                samples = struct.unpack(f'<{WINDOW}f', raw)
                rms = math.sqrt(sum(x * x for x in samples) / WINDOW)
                goal = math.sqrt(min(1.0, self.gain * rms))
                # 10 ms attack, 150 ms release at a 20 ms step
                level += (goal - level) * (1.0 if goal > level else 1 - math.exp(-20 / 150))
                self.level, self.stamp = level, time.monotonic()
            self.proc.kill()
            self.proc.wait()
            if not self.stop.is_set():
                log('capture ended, restarting in 1 s')
                time.sleep(1)

    def read(self):
        return self.level if time.monotonic() - self.stamp < STALE_AFTER else 0.0


def send(sock, level):
    sock.sendall((json.dumps({'cmd': 'effect-audio', 'version': 1, 'level': round(level, 4)}) + '\n').encode())
    reply = b''
    while not reply.endswith(b'\n'):
        chunk = sock.recv(256)
        if not chunk:
            raise EOFError('compositor closed the connection')
        reply += chunk
    return json.loads(reply)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--socket', default=os.environ.get('UMBRIEL_SOCKET'))
    ap.add_argument('--target', default='')
    ap.add_argument('--gain', type=float, default=16.0)
    args = ap.parse_args()
    if not args.socket:
        sys.exit('no socket: pass --socket or run inside an Umbriel session ($UMBRIEL_SOCKET)')
    meter = Meter(args.target, args.gain)
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    connected = False
    try:
        while True:
            try:
                sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                sock.settimeout(2)
                sock.connect(args.socket)
                reply = send(sock, meter.read())
                if reply != {'ok': True}:
                    raise ConnectionError(reply)
                if not connected:
                    log('connected')
                    connected = True
                while True:
                    time.sleep(SEND_INTERVAL)
                    reply = send(sock, meter.read())
                    if reply != {'ok': True}:
                        raise ConnectionError(reply)
            except (OSError, EOFError, ConnectionError, json.JSONDecodeError) as error:
                if connected:
                    log(f'disconnected ({error}), retrying')
                connected = False
                try:
                    sock.close()
                except OSError:
                    pass
                time.sleep(0.5)
    except KeyboardInterrupt:
        pass
    finally:
        meter.stop.set()
        if meter.proc:
            meter.proc.kill()


if __name__ == '__main__':
    main()
