# Brev Launchables

Public setup scripts for [Brev](https://brev.nvidia.com) GPU instances used by Lucitra infrastructure.

## Available Scripts

### `isaac-sim/setup.sh`

One-shot environment setup for Isaac Sim GPU runtime testing.

Installs Python 3.10, Isaac Sim 4.5.0 (pip), clones the [Lucitra Validate](https://github.com/lucitra/lucitra-validate) plugin, and verifies GPU + dependencies.

```bash
curl -fsSL https://raw.githubusercontent.com/lucitra/brev-launchables/main/isaac-sim/setup.sh | bash
```

**After setup, run the GPU smoke test:**

```bash
source ~/isaacsim-env/bin/activate
export OMNI_KIT_ACCEPT_EULA=YES
cd ~/lucitra-validate/plugins/isaac-sim
python scripts/test-runtime.py
```

### Instance Management

```bash
brev stop <instance-name>    # Stop (preserves disk/setup, minimal storage cost)
brev start <instance-name>   # Resume later (no re-setup needed)
brev ls                      # Check status
```

## Requirements

- Brev instance with NVIDIA GPU (L40S recommended)
- Deep Learning Base OSS Nvidia Driver GPU AMI (Ubuntu 22.04)
- GitHub SSH key or token for private repo access (plugin clone step)
