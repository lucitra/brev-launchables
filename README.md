# Brev Launchables

Public setup scripts for [Brev](https://brev.nvidia.com) GPU instances used by Lucitra infrastructure.

## Quick Start

```bash
# 1. Connect to your Brev instance
brev shell isaac-launchable-0152de

# 2. Run setup (first time only — installs Isaac Sim, plugin, GitHub CLI auth)
curl -fsSL https://raw.githubusercontent.com/lucitra/brev-launchables/main/isaac-sim/setup.sh | bash

# 3. Run tests
curl -fsSL https://raw.githubusercontent.com/lucitra/brev-launchables/main/isaac-sim/run-tests.sh | bash
```

## Scripts

### `isaac-sim/setup.sh`

One-shot environment setup for Isaac Sim GPU runtime testing. Safe to re-run — skips steps that are already complete.

```bash
curl -fsSL https://raw.githubusercontent.com/lucitra/brev-launchables/main/isaac-sim/setup.sh | bash
```

**What it does:**

| Step | Action | Time |
|------|--------|------|
| 1 | Install system deps (Python 3.10, git, GitHub CLI) | ~30s |
| 2 | Verify GPU (nvidia-smi) | instant |
| 3 | GitHub authentication (interactive browser device flow) | ~1 min |
| 4 | Create Python 3.10 venv | ~10s |
| 5 | Install Isaac Sim 4.5.0 via pip | ~5-10 min |
| 6 | Clone lucitra-validate + install plugin | ~30s |
| 7 | Verify (PyTorch CUDA, pxr, plugin imports) | ~5s |

**Environment variables (optional overrides):**

| Variable | Default | Description |
|----------|---------|-------------|
| `ISAAC_SIM_VERSION` | `4.5.0` | Isaac Sim pip package version |
| `PLUGIN_BRANCH` | `dev` | Branch of lucitra-validate to clone |
| `VENV_DIR` | `~/isaacsim-env` | Python venv location |
| `PLUGIN_DIR` | `~/lucitra-validate` | Plugin clone location |

### `isaac-sim/run-tests.sh`

Runs test suites against the installed environment. Activates the venv automatically.

```bash
# Run all tests (unit + GPU runtime + E2E)
curl -fsSL https://raw.githubusercontent.com/lucitra/brev-launchables/main/isaac-sim/run-tests.sh | bash

# Run a specific suite
curl -fsSL https://raw.githubusercontent.com/lucitra/brev-launchables/main/isaac-sim/run-tests.sh | bash -s -- --unit
curl -fsSL https://raw.githubusercontent.com/lucitra/brev-launchables/main/isaac-sim/run-tests.sh | bash -s -- --gpu
curl -fsSL https://raw.githubusercontent.com/lucitra/brev-launchables/main/isaac-sim/run-tests.sh | bash -s -- --e2e
```

**Test suites:**

| Flag | Tests | What it covers |
|------|-------|----------------|
| `--unit` | 28 tests | Client, exporter, validator unit tests + USD smoke tests (usd-core) |
| `--gpu` | 6 checks | SimulationApp init, Replicator rendering, API connectivity |
| `--e2e` | 6 tests | Full flow against live Validate API (create dataset, validate, poll, report) |
| `--all` | All of the above | Default if no flag specified |

## Instance Management

### Current Instance

| Detail | Value |
|--------|-------|
| Name | `isaac-launchable-0152de` |
| GPU | NVIDIA L40S (46 GB VRAM) |
| Spec | 1 GPU x 16 CPUs, 128 GB RAM, 238 GB disk |
| Region | N. Virginia (AWS) |
| Cost | ~$3/hr running |
| AMI | Deep Learning Base OSS Nvidia Driver GPU AMI (Ubuntu 22.04) |
| Brev URL | `https://isaac0-6htwqyree.brevlab.com` |

### Commands

```bash
brev shell isaac-launchable-0152de  # SSH into instance
brev stop isaac-launchable-0152de   # Stop (preserves disk/setup, minimal storage cost)
brev start isaac-launchable-0152de  # Resume later (no re-setup needed)
brev ls                             # Check instance status
```

### Cost Tips

- **Stop when not in use** — you're billed ~$3/hr only while running
- **Stop vs Delete** — stopping preserves your disk so you skip setup next time. Deleting removes everything
- **Storage** — small charge for disk while stopped, far less than GPU compute
- **Re-run setup after delete** — if you delete and recreate, just curl the setup script again

## Creating a New Instance

1. Go to the [Brev deploy URL](https://brev.nvidia.com/launchable/deploy/now?launchableID=env-35JP2ywERLgqtD0b0MIeK1HnF46)
2. Select an L40S GPU instance
3. Wait for it to start, then connect and run setup:

```bash
brev shell <instance-name>
curl -fsSL https://raw.githubusercontent.com/lucitra/brev-launchables/main/isaac-sim/setup.sh | bash
```

## Requirements

- [Brev CLI](https://docs.brev.dev/docs/reference/brev-cli) (`brew install brevdev/homebrew-brev/brev`)
- Brev account with GPU credits
- GitHub account with access to `lucitra` org (for private repo clone)
