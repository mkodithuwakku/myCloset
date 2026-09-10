"""Host-side launch-preparation checks; no real simulator is modified."""

import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[2]
DEVICE = "11111111-2222-3333-4444-555555555555"


class SimulatorRunTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="myCloset launch test ")
        self.addCleanup(self.temp.cleanup)
        self.folder = Path(self.temp.name)
        self.app = self.folder / "myCloset.app"
        self.app.mkdir()
        shutil.copy("/usr/bin/true", self.app / "myCloset")
        with (self.app / "Info.plist").open("wb") as stream:
            plistlib.dump({"CFBundleIdentifier": "test.myCloset.launch",
                          "CFBundleExecutable": "myCloset",
                          "CFBundlePackageType": "APPL"}, stream)
        subprocess.run(["/usr/bin/codesign", "--force", "--sign", "-", str(self.app)],
                       check=True, capture_output=True)
        self.log = self.folder / "calls"
        xcrun = self.folder / "xcrun"
        xcrun.write_text('#!/bin/bash\nprintf "%s\\n" "$*" >> "$CALL_LOG"\n'
                         'if [[ "$2" == "${FAIL_COMMAND:-}" ]]; then exit 42; fi\n')
        xcrun.chmod(0o755)
        self.env = {**os.environ, "PATH": f"{self.folder}:/usr/bin:/bin",
                    "PLATFORM_NAME": "iphonesimulator", "TARGET_DEVICE_IDENTIFIER": DEVICE,
                    "TARGET_BUILD_DIR": str(self.folder), "FULL_PRODUCT_NAME": "myCloset.app",
                    "CALL_LOG": str(self.log), "TARGET_TEMP_DIR": str(self.folder)}

    def run_prepare(self, **changes):
        return subprocess.run([str(ROOT / "scripts/prepare_simulator_run.sh")],
                              env={**self.env, **changes}, capture_output=True, text=True)

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def test_waits_then_installs_only_on_selected_device(self):
        self.assertEqual(self.run_prepare().returncode, 0)
        self.assertEqual(self.calls(), [f"simctl bootstatus {DEVICE} -b",
                                       f"simctl install {DEVICE} {self.app}"])
        self.assertIn(DEVICE, (self.folder / "myCloset-simulator-run.log").read_text())

    def test_device_build_does_not_touch_simulators(self):
        self.assertEqual(self.run_prepare(PLATFORM_NAME="iphoneos").returncode, 0)
        self.assertEqual(self.calls(), [])

    def test_missing_destination_never_falls_back_to_booted(self):
        self.assertNotEqual(self.run_prepare(TARGET_DEVICE_IDENTIFIER="").returncode, 0)
        self.assertEqual(self.calls(), [])

    def test_missing_product_does_not_touch_simulator(self):
        self.assertNotEqual(self.run_prepare(TARGET_BUILD_DIR="/missing").returncode, 0)
        self.assertEqual(self.calls(), [])

    def test_unsigned_product_is_rejected(self):
        subprocess.run(["/usr/bin/codesign", "--remove-signature", str(self.app)], check=True)
        self.assertNotEqual(self.run_prepare().returncode, 0)
        self.assertEqual(self.calls(), [])

    def test_boot_failure_prevents_installation(self):
        self.assertEqual(self.run_prepare(FAIL_COMMAND="bootstatus").returncode, 42)
        self.assertEqual(self.calls(), [f"simctl bootstatus {DEVICE} -b"])

    def test_install_failure_is_reported(self):
        self.assertEqual(self.run_prepare(FAIL_COMMAND="install").returncode, 42)

    def test_shared_run_scheme_invokes_preparation_with_app_environment(self):
        scheme = ET.parse(ROOT / "myCloset.xcodeproj/xcshareddata/xcschemes/myCloset.xcscheme")
        action = scheme.find("LaunchAction/PreActions/ExecutionAction/ActionContent")
        self.assertIsNotNone(action)
        self.assertEqual(action.attrib["scriptText"].strip(),
                         '"${SRCROOT}/scripts/prepare_simulator_run.sh"')
        self.assertEqual(action.find("EnvironmentBuildable/BuildableReference").attrib["BlueprintName"],
                         "myCloset")


if __name__ == "__main__":
    unittest.main()
