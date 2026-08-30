#!/usr/bin/env python3
"""Synthetic test runner for GitHub Actions CI and local testing.

Validates that all Python test scripts correctly accept valid configurations
and reject corrupt or tampered payloads.
"""

from __future__ import annotations

import json
import pathlib
import subprocess
import sys
import unittest
import urllib.parse
import yaml

PROJECT_ROOT = pathlib.Path(__file__).resolve().parents[3]
HOMEPAGE_DIR = PROJECT_ROOT / "services/homepage"
TESTS_DIR = HOMEPAGE_DIR / "tests"


class CISyntheticTests(unittest.TestCase):
    def setUp(self) -> None:
        # Load and parse services.yaml to generate Homepage API services representation
        services_yaml_path = HOMEPAGE_DIR / "config/services.yaml"
        with open(services_yaml_path, encoding="utf-8") as f:
            data = yaml.safe_load(f)

        def group(name, entries):
            services, groups = [], []
            for entry in entries:
                for child_name, props in entry.items():
                    if isinstance(props, list):
                        groups.append(group(child_name, props))
                    else:
                        service = {"name": child_name}; service.update(props); services.append(service)
            return {"name": name, "services": services, "groups": groups}
        self.api_services = [group(name, entries) for item in data for name, entries in item.items()]

        self.valid_services_payload = json.dumps(self.api_services, ensure_ascii=False)

    def run_script(self, script_name: str, stdin_data: str | None = None, args: list[str] | None = None) -> subprocess.CompletedProcess[str]:
        cmd = [sys.executable, str(TESTS_DIR / script_name)]
        if args:
            cmd.extend(args)
        return subprocess.run(
            cmd,
            input=stdin_data,
            text=True,
            capture_output=True,
        )

    def test_launcher_catalog_validate(self) -> None:
        proc = self.run_script("launcher_catalog_validate.py")
        self.assertEqual(proc.returncode, 0, f"Error in launcher_catalog_validate: {proc.stderr}")
        self.assertIn("Catálogo estático del lanzador: OK", proc.stdout)

    def test_windows_metrics_agent_validate(self) -> None:
        proc = self.run_script("windows_metrics_agent_validate.py")
        self.assertEqual(proc.returncode, 0, f"Error in windows_metrics_agent_validate: {proc.stderr}")
        self.assertIn("Agente Windows de métricas: validación estática OK", proc.stdout)

    def test_phase4_validate_success(self) -> None:
        proc = self.run_script("phase4_validate.py", stdin_data=self.valid_services_payload)
        self.assertEqual(proc.returncode, 0, f"Error in phase4_validate: {proc.stderr}")
        self.assertIn("Configuración runtime de herramientas y Administración: OK", proc.stdout)

    def test_phase4_validate_failure_on_corrupt_data(self) -> None:
        # Test failure on missing groups or corrupt data
        proc = self.run_script("phase4_validate.py", stdin_data="[]")
        self.assertNotEqual(proc.returncode, 0)

    def test_production_validate_success(self) -> None:
        proc = self.run_script("production_validate.py", stdin_data=self.valid_services_payload)
        self.assertEqual(proc.returncode, 0, f"Error in production_validate: {proc.stderr}")
        self.assertIn("Configuración runtime de PRODUCCIÓN: OK", proc.stdout)

    def test_production_validate_failure_on_bad_domain(self) -> None:
        # Inject incorrect domain into PROD
        corrupted = json.loads(self.valid_services_payload)
        def corrupt(groups):
            for group in groups:
                for srv in group.get("services", []):
                    if srv.get("name") == "Tickets PROD": srv["href"] = "https://service-ab-electronics.com/"
                corrupt(group.get("groups", []))
        corrupt(corrupted)
        proc = self.run_script("production_validate.py", stdin_data=json.dumps(corrupted))
        self.assertNotEqual(proc.returncode, 0)

    def test_development_accesses_are_absent(self) -> None:
        proc = self.run_script("development_validate.py", stdin_data=self.valid_services_payload)
        self.assertEqual(proc.returncode, 0, f"Error in development_validate: {proc.stderr}")
        self.assertIn("Configuración runtime sin accesos DEV: OK", proc.stdout)

    def test_development_validate_failure_when_dev_reappears(self) -> None:
        # Reintroduce an access card removed by the user.
        corrupted = json.loads(self.valid_services_payload)
        corrupted.append({"name": "🧪 DESARROLLO / DEV", "services": []})
        proc = self.run_script("development_validate.py", stdin_data=json.dumps(corrupted))
        self.assertNotEqual(proc.returncode, 0)

    def test_tailscale_validate_success(self) -> None:
        mock_tailscale = {
            "TCP": {
                "443": {"HTTPS": True},
                "8443": {"HTTPS": True},
                "10000": {"HTTPS": True},
            },
            "Web": {
                "macmini-server.tailf553c4.ts.net:443": {
                    "Handlers": {"/": {"Proxy": "http://127.0.0.1:18789"}}
                },
                "macmini-server.tailf553c4.ts.net:8443": {
                    "Handlers": {"/": {"Proxy": "http://127.0.0.1:5678"}}
                },
                "macmini-server.tailf553c4.ts.net:10000": {
                    "Handlers": {"/": {"Proxy": "http://127.0.0.1:3000"}}
                },
            },
        }
        payload = json.dumps(mock_tailscale)
        for mode in ("legacy", "published"):
            proc = self.run_script("tailscale_validate.py", stdin_data=payload, args=[mode])
            self.assertEqual(proc.returncode, 0, f"Error in tailscale_validate ({mode}): {proc.stderr}")
            self.assertIn(f"Configuración Tailscale ({mode}): OK", proc.stdout)

    def test_tailscale_validate_failure_on_wrong_proxy(self) -> None:
        mock_tailscale = {
            "TCP": {"443": {"HTTPS": True}, "8443": {"HTTPS": True}, "10000": {"HTTPS": True}},
            "Web": {
                "macmini-server.tailf553c4.ts.net:443": {
                    "Handlers": {"/": {"Proxy": "http://127.0.0.1:9999"}}
                }
            },
        }
        proc = self.run_script("tailscale_validate.py", stdin_data=json.dumps(mock_tailscale), args=["published"])
        self.assertNotEqual(proc.returncode, 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
