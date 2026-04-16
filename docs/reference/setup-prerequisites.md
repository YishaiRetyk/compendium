# Setup Prerequisites

`bin/init-wizard.sh` and most other `bin/*.sh` scripts require:

- **bash >= 4.0**
- **git**
- **python3 >= 3.8**

Optional but recommended:
- **PyYAML** (for richer `.wizard-answers.yaml` parsing — wizard falls back to a stdlib parser if absent)

## Installation by Platform

### macOS

```bash
brew install bash git python3
pip3 install pyyaml
```

(macOS ships with bash 3.2 by default; `brew install bash` is required.)

### Debian / Ubuntu / WSL (Debian-based)

```bash
sudo apt update && sudo apt install -y bash git python3 python3-pip
pip3 install pyyaml   # or: sudo apt install python3-yaml
```

### Arch Linux

```bash
sudo pacman -S bash git python python-yaml
```

### Fedora / RHEL

```bash
sudo dnf install bash git python3 python3-pyyaml
```

### Windows (native, no WSL)

Use Git Bash + Python from python.org. The wizard has not been tested on PowerShell or cmd.exe; WSL is the recommended path.

## Verify

```bash
bash --version | head -1   # Should report 5.x or 4.x
git --version              # Any modern version
python3 --version          # 3.8+
python3 -c "import yaml; print(yaml.__version__)"   # Optional; 5.x or 6.x
```

If any check fails, install the missing tool above. The wizard's pre-flight (`bin/init-wizard.sh`) re-runs these checks and exits 3 with a one-line-per-missing-tool message before any file I/O.
