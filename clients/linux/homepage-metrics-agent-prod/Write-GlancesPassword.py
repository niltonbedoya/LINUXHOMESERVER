"""Crea un hash de contraseña Glances desde un secreto recibido por stdin."""
from __future__ import annotations
import pathlib
import sys
from glances.password import GlancesPassword

if len(sys.argv) != 3:
    raise SystemExit('usage: Write-GlancesPassword.py PASSWORD_DIR USERNAME')
password = sys.stdin.read().rstrip('\r\n')
if len(password) != 43:
    raise SystemExit('password must be a 43-character Base64URL value')
directory = pathlib.Path(sys.argv[1]).resolve(); username = sys.argv[2]
directory.mkdir(parents=True, exist_ok=True)
manager = GlancesPassword(username=username); manager.password_dir = str(directory)
manager.password_filename = f'{username}.pwd'; manager.password_file = str(directory / manager.password_filename)
manager.save_password(manager.hash_password(manager.get_hash(password)))
