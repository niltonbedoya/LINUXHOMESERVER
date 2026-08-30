"""Create a Glances password file from a secret received through stdin."""

from __future__ import annotations

import pathlib
import sys

from glances.password import GlancesPassword


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: Write-GlancesPassword.py PASSWORD_DIR USERNAME", file=sys.stderr)
        return 2

    password_dir = pathlib.Path(sys.argv[1]).resolve()
    username = sys.argv[2]
    clear_password = sys.stdin.read().rstrip("\r\n")
    if len(clear_password) != 43:
        print("password must be a 43-character Base64URL value", file=sys.stderr)
        return 3

    password_dir.mkdir(parents=True, exist_ok=True)
    manager = GlancesPassword(username=username)
    manager.password_dir = str(password_dir)
    manager.password_filename = f"{username}.pwd"
    manager.password_file = str(password_dir / manager.password_filename)
    manager.save_password(manager.hash_password(manager.get_hash(clear_password)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
