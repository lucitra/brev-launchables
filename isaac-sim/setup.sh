#!/usr/bin/env bash
# Brev launchable setup script for Isaac Sim + Lucitra Validate plugin.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/lucitra/brev-launchables/main/isaac-sim/setup.sh | bash
#
# Tested on: Deep Learning Base OSS Nvidia Driver GPU AMI (Ubuntu 22.04)
# GPU: NVIDIA L40S (requires any RTX GPU with >=8GB VRAM)

set -euo pipefail

ISAAC_SIM_VERSION="${ISAAC_SIM_VERSION:-4.5.0}"
PLUGIN_BRANCH="${PLUGIN_BRANCH:-dev}"
PLUGIN_REPO="${PLUGIN_REPO:-lucitra/lucitra-validate}"
VENV_DIR="${VENV_DIR:-$HOME/isaacsim-env}"
PLUGIN_DIR="${PLUGIN_DIR:-$HOME/lucitra-validate}"

echo "============================================="
echo "Lucitra Validate — Isaac Sim Brev Setup"
echo "============================================="
echo "Isaac Sim version: ${ISAAC_SIM_VERSION}"
echo "Plugin branch:     ${PLUGIN_BRANCH}"
echo "Venv:              ${VENV_DIR}"
echo ""

# ── 1. System dependencies + GitHub CLI ──

echo "[1/7] Installing system dependencies..."
sudo apt-get update -qq

# Core dependencies
sudo apt-get install -y -qq python3.10 python3.10-venv python3.10-dev git > /dev/null 2>&1

# GitHub CLI (needed for private repo access)
if ! command -v gh &> /dev/null; then
    echo "       Installing GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y -qq gh > /dev/null 2>&1
fi
echo "       Done."

# ── 2. GPU check ──

echo "[2/7] Checking GPU..."
if ! nvidia-smi > /dev/null 2>&1; then
    echo "ERROR: nvidia-smi not found. Is an NVIDIA GPU available?"
    exit 1
fi
GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)
GPU_MEM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader | head -1)
echo "       GPU: ${GPU_NAME} (${GPU_MEM})"

# ── 3. GitHub authentication ──

echo "[3/7] Checking GitHub authentication..."
if gh auth status &> /dev/null; then
    echo "       Already authenticated."
elif ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "       SSH key authenticated."
else
    echo ""
    echo "       GitHub authentication required (lucitra-validate is a private repo)."
    echo "       Follow the prompts below to log in via browser:"
    echo ""
    gh auth login -h github.com -p https -w
    echo ""
    echo "       Authenticated."
fi

# ── 4. Python venv ──

echo "[4/7] Creating Python 3.10 virtual environment..."
if [ ! -d "${VENV_DIR}" ]; then
    python3.10 -m venv "${VENV_DIR}"
fi
source "${VENV_DIR}/bin/activate"
pip install --upgrade pip -q
echo "       Python: $(python --version)"

# ── 5. Isaac Sim ──

echo "[5/7] Installing Isaac Sim ${ISAAC_SIM_VERSION} (this may take several minutes)..."
pip install "isaacsim[all]==${ISAAC_SIM_VERSION}" --extra-index-url https://pypi.nvidia.com -q
export OMNI_KIT_ACCEPT_EULA=YES
echo "       Done."

# ── 6. Clone plugin + install ──

echo "[6/7] Cloning and installing lucitra-validate plugin..."
if [ -d "${PLUGIN_DIR}" ]; then
    cd "${PLUGIN_DIR}"
    git fetch origin
    git checkout "${PLUGIN_BRANCH}"
    git pull origin "${PLUGIN_BRANCH}"
else
    gh repo clone "${PLUGIN_REPO}" "${PLUGIN_DIR}" -- --branch "${PLUGIN_BRANCH}" --single-branch
fi
cd "${PLUGIN_DIR}/plugins/isaac-sim"
pip install -e ".[dev]" -q
# NOTE: Do NOT install usd-core here — Isaac Sim ships its own pxr bindings.
# Installing usd-core alongside Isaac Sim causes C++ binding conflicts
# (SdfPath vector converter error) and segfaults. The standalone usd-core
# package is only for local CPU-only testing without Isaac Sim.
echo "       Done."

# ── 7. Verify ──

echo "[7/7] Verifying installation..."
python -c "
import torch
print(f'  PyTorch:      {torch.__version__}')
print(f'  CUDA:         {torch.cuda.is_available()} ({torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"N/A\"})')
"
python -c "from omni.lucitra.validate.client import LucitraClient; print('  Plugin:       OK')"
python -c "from pxr import Usd; print('  USD (pxr):    OK')"
echo ""
echo "============================================="
echo "Setup complete!"
echo ""
echo "Activate the environment:"
echo "  source ${VENV_DIR}/bin/activate"
echo "  export OMNI_KIT_ACCEPT_EULA=YES"
echo ""
echo "Run tests:"
echo "  cd ${PLUGIN_DIR}/plugins/isaac-sim"
echo "  python -m pytest tests/ -v                    # Unit + USD smoke (28 tests)"
echo "  python scripts/test-runtime.py                # Isaac Sim GPU runtime test"
echo "  python -m pytest tests/test_e2e.py -v -m e2e  # E2E against live API"
echo "============================================="
