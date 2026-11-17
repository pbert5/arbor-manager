#!/usr/bin/env python3
"""Drive the installed CLI through a sized PTY and assert the rendered screens."""
import contextlib
import fcntl
import hashlib
import json
import os
from pathlib import Path
import pty
import select
import struct
import subprocess
import tempfile
import termios
import time

import pyte

CLI = os.environ.get("ARBOR_MANAGER_CLI", "arbor-manager")


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


@contextlib.contextmanager
def terminal(directory, *args, width=110):
    master, slave = pty.openpty()
    height = 27
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", height, width, 0, 0))
    process = subprocess.Popen([CLI, "tui", *args], cwd=directory, stdin=slave, stdout=slave,
                               stderr=slave, env={**os.environ, "TERM": "xterm-256color"})
    os.close(slave)
    screen = pyte.Screen(width, height)
    stream = pyte.ByteStream(screen)
    output = bytearray()

    def expect(*fragments, keys=b""):
        if keys:
            os.write(master, keys)
        deadline = time.monotonic() + 8
        while time.monotonic() < deadline:
            if select.select([master], [], [], 0.1)[0]:
                chunk = os.read(master, 65536)
                output.extend(chunk)
                stream.feed(chunk)
            display = "\n".join(screen.display)
            if all(f in display for f in fragments):
                return display
        raise AssertionError((fragments, display))

    try:
        yield expect
        os.write(master, b"q")
        assert process.wait(timeout=8) == 0
        assert b"do-not-display" not in output
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
        os.close(master)


def main():
    with tempfile.TemporaryDirectory() as tmp:
        with terminal(tmp, "--demo") as show:
            show("FICTIONAL DATA", "SNAPSHOT OVERVIEW", "5 selected")
            show("NODE INVENTORY", "atlas", keys=b"\n")
            show("SNAPSHOT RECORD", "atlas.example", keys=b"\n")
            show("RELATIONSHIP EXPLORER", "FOCUS   atlas", "NODE PREVIEW", keys=b"g")
            show("FOCUS   cedar", "birch", "moss", keys=b"\n")
            show("Registry projection", "standby", "Peer", keys=b"s")
            show("FIND NODE", "isle", keys=b"n")
            show("Filter: isle", keys=b"/isle\n")
            show("FOCUS   isle", "No incident links", keys=b"\n")
            show("FOCUS   cedar", keys=b"\x1b")
            show("ENDPOINT OBSERVATIONS", "Accepted records", "Observed records", keys=b"e")
            show("REGISTRY PROJECTION", "atlas-identity", keys=b"3")
            show("Filter: standby", "No matching", keys=b"/standby\n")
            show("atlas-identity", keys=b"\x1b")
            show("RECORD METADATA", "Generation", keys=b"\n")
            show("DEPLOYMENT PLAN", "2 batches", keys=b"5")
            show("PHASE MEMBERS", "Batch 2", "moss", keys=b"j\n")
            show("DEPLOYMENT PLAN", keys=b"r")
        assert not os.listdir(tmp)

        if os.environ.get("REAL_SNAPSHOT"):
            with terminal(tmp, "--snapshot", os.environ["REAL_SNAPSHOT"], "--tab", "network") as show:
                show("FOCUS   edge", "No incident links")

        nodes = {"api": {"system": "x86_64-linux", "targetHost": "api.example",
                         "password": "do-not-display", "parents": ["gateway", "relay"]},
                 "gateway": {"children": ["api", "other"]}, "relay": {}, "other": {}}
        snapshot = {"nodes": nodes, "selected": ["api"], "excluded": [], "roots": ["api"]}
        data = {"format": "arbor-manager/deployment-snapshot", "version": 1,
                "snapshot": snapshot, "snapshotDigest": digest(snapshot),
                "plan": {"backend": "direct", "phases": [{"name": "first", "names": ["api"]}]}}
        data["digest"] = digest(data)
        path = Path(tmp) / "snapshot.json"
        path.write_text(json.dumps(data))
        projection = {"p1": {"schema": "relationship", "generation": 1, "payload": {
            "from": "relay", "to": "api", "kind": "parent", "status": "standby", "secret": "do-not-display"}},
                      "p2": {"schema": "relationship", "payload": {"from": "other", "to": "api", "status": "active"}},
                      "isolated": {"schema": "node-identity", "payload": {"identity": "offline"}}}
        registry = Path(tmp) / "registry.json"
        registry.write_text(json.dumps(projection))
        with terminal(tmp, "--snapshot", str(path), "--registry-projection", str(registry),
                      "--tab", "network", width=65) as show:
            view = show("FOCUS   api", "gateway", "relay", "Parent")
            assert view.count("declared") == 3  # heading plus two unique links
            show("FOCUS   gateway", "other", "Child", keys=b"\n")
            show("FOCUS   api", keys=b"\x1b")
            show("Registry projection", "standby", "Peer", keys=b"s")
            show("FIND NODE", "offline", keys=b"/\n")
            show("ENDPOINT OBSERVATIONS", "No network socket", keys=b"e")
            show("NODE INVENTORY", keys=b"2")
            show("Filter: api", keys=b"/api\n")
            show("SNAPSHOT RECORD", "api.example", keys=b"\n")
            show("REGISTRY PROJECTION", "p1", keys=b"\t")
            show("RECORD METADATA", "standby", "relay", keys=b"\n")
        nodes["api"]["system"] = "tampered"
        path.write_text(json.dumps(data))
        result = subprocess.run([CLI, "tui", "--snapshot", str(path)], capture_output=True)
        assert result.returncode != 0


if __name__ == "__main__":
    main()
