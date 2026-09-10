#!/usr/bin/env python3
"""Run XCTest on a disposable simulator, isolated from interactive Xcode runs."""

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import uuid


def main():
    runtimes = json.loads(subprocess.check_output(
        ["xcrun", "simctl", "list", "runtimes", "--json"], text=True
    ))["runtimes"]
    available = [runtime for runtime in runtimes
                 if runtime.get("isAvailable") and runtime.get("platform") == "iOS"]
    if not available:
        raise SystemExit("No available iOS Simulator runtime. Install one in Xcode Settings.")
    runtime = max(available, key=lambda item: tuple(int(n) for n in item["version"].split(".")))
    phones = [device for device in runtime["supportedDeviceTypes"]
              if device.get("productFamily") == "iPhone"]
    if not phones:
        raise SystemExit("The selected runtime has no supported iPhone simulator.")
    phone = next((device for device in phones if device["name"] == "iPhone 17 Pro"), phones[0])
    output = Path(tempfile.mkdtemp(prefix="myClosetTests-"))
    device_id = subprocess.check_output([
        "xcrun", "simctl", "create", f"myCloset Tests {uuid.uuid4().hex[:8]}",
        phone["identifier"], runtime["identifier"]
    ], text=True).strip()
    print(f"Isolated simulator: {device_id}\nTest output: {output}", flush=True)
    try:
        subprocess.run(["xcrun", "simctl", "bootstatus", device_id, "-b"], check=True)
        return subprocess.call([
            "xcodebuild", "-project", "myCloset.xcodeproj", "-scheme", "myCloset",
            "-destination", f"platform=iOS Simulator,id={device_id}",
            "-derivedDataPath", str(output / "DerivedData"),
            "-resultBundlePath", str(output / "Tests.xcresult"),
            "-parallel-testing-enabled", "NO", *sys.argv[1:], "test"
        ], cwd=Path(__file__).resolve().parent.parent)
    finally:
        # This UUID was created above; never delete/shutdown another device.
        subprocess.run(["xcrun", "simctl", "shutdown", device_id], check=False)
        subprocess.run(["xcrun", "simctl", "delete", device_id], check=False)


if __name__ == "__main__":
    sys.exit(main())
