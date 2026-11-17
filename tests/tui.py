#!/usr/bin/env python3
"""Exercise the packaged entry point against a real validated snapshot in a PTY."""
import hashlib
import json
import os
import pty
import select
import subprocess
import tempfile
import time


def digest(value):
    return hashlib.sha256((json.dumps(value, sort_keys=True, separators=(',', ':'))).encode()).hexdigest()


def read_until(fd, needle):
    output = b''
    deadline = time.monotonic() + 10
    while needle not in output and time.monotonic() < deadline:
        if select.select([fd], [], [], 0.2)[0]:
            try:
                output += os.read(fd, 65536)
            except OSError:
                break
    assert needle in output, (needle, output)
    return output


def main():
    with tempfile.TemporaryDirectory() as empty:
        master, slave = pty.openpty()
        process = subprocess.Popen([os.environ.get('ARBOR_MANAGER_CLI', 'arbor-manager'), 'tui', '--demo'], cwd=empty, stdin=slave, stdout=slave, stderr=slave, env={**os.environ, 'TERM': 'xterm'})
        os.close(slave)
        try:
            assert b'FICTIONAL DATA' in read_until(master, b'SNAPSHOT OVERVIEW')
            os.write(master, b'\t')
            read_until(master, b'atlas')
            os.write(master, b'\n')
            read_until(master, b'atlas.example')
            os.write(master, b'\t')
            read_until(master, b'atlas-identity')
            os.write(master, b'\t\t')
            read_until(master, b'DEPLOYMENT PLAN')
            os.write(master, b'rq')
            assert process.wait(timeout=10) == 0
            assert not os.listdir(empty)
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
            os.close(master)
    if os.environ.get('REAL_SNAPSHOT'):
        master, slave = pty.openpty()
        process = subprocess.Popen([os.environ['ARBOR_MANAGER_CLI'], 'tui', '--snapshot', os.environ['REAL_SNAPSHOT']], stdin=slave, stdout=slave, stderr=slave, env={**os.environ, 'TERM': 'xterm'})
        os.close(slave)
        try:
            read_until(master, b'SNAPSHOT OVERVIEW')
            os.write(master, b'q')
            assert process.wait(timeout=10) == 0
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
            os.close(master)
    data = {'format': 'arbor-manager/deployment-snapshot', 'version': 1,
            'snapshot': {'nodes': {'api': {'system': 'x86_64-linux', 'password': 'do-not-display', 'targetHost': 'api.example'}, 'worker': {}}, 'selected': ['api'], 'excluded': [], 'roots': ['api']},
            'plan': {'backend': 'direct', 'phases': [{'name': 'first', 'names': ['api']}]}}
    data['snapshotDigest'] = digest(data['snapshot'])
    data['digest'] = digest(data)
    with tempfile.TemporaryDirectory() as tmp:
        path = os.path.join(tmp, 'snapshot.json')
        with open(path, 'w') as stream:
            json.dump(data, stream)
        registry = os.path.join(tmp, 'registry.json')
        with open(registry, 'w') as stream:
            json.dump({'record-1': {'schema': 'node-identity', 'generation': 2, 'payload': {'secret': 'registry-secret'}}}, stream)
        master, slave = pty.openpty()
        process = subprocess.Popen([os.environ.get('ARBOR_MANAGER_CLI', 'arbor-manager'), 'tui', '--snapshot', path, '--registry-projection', registry], stdin=slave, stdout=slave, stderr=slave, env={**os.environ, 'TERM': 'xterm'})
        os.close(slave)
        try:
            output = read_until(master, b'SNAPSHOT OVERVIEW')
            os.write(master, b'\t')
            output += read_until(master, b'worker')
            os.write(master, b'/worker\n')
            output += read_until(master, b'Filter: worker')
            os.write(master, b'\n')
            output += read_until(master, b'SNAPSHOT RECORD')
            os.write(master, b'\x1b')
            os.write(master, b'/api\n')
            output += read_until(master, b'Filter: api')
            os.write(master, b'\n')
            output += read_until(master, b'api.example')
            assert b'do-not-display' not in output
            os.write(master, b'\t')
            output += read_until(master, b'node-identity')
            assert b'node-identity' in output and b'registry-secret' not in output
            os.write(master, b'q')
            assert process.wait(timeout=10) == 0
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
            os.close(master)
        data['snapshot']['nodes']['api']['system'] = 'tampered'
        with open(path, 'w') as stream:
            json.dump(data, stream)
        result = subprocess.run([os.environ.get('ARBOR_MANAGER_CLI', 'arbor-manager'), 'tui', '--snapshot', path], capture_output=True)
        assert result.returncode != 0


if __name__ == '__main__':
    main()
