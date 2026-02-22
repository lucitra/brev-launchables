#!/usr/bin/env bash
# Run Isaac Sim GPU smoke tests on a Brev instance.
#
# Usage (after setup.sh has completed):
#   curl -fsSL https://raw.githubusercontent.com/lucitra/brev-launchables/main/isaac-sim/run-tests.sh | bash
#
# Or run specific test suites:
#   curl ... | bash -s -- --unit          # Unit + USD smoke only
#   curl ... | bash -s -- --gpu           # GPU runtime smoke test only
#   curl ... | bash -s -- --e2e           # E2E against live API only
#   curl ... | bash -s -- --all           # All tests (default)

set -euo pipefail

VENV_DIR="${VENV_DIR:-$HOME/isaacsim-env}"
PLUGIN_DIR="${PLUGIN_DIR:-$HOME/lucitra-validate/plugins/isaac-sim}"
TEST_SUITE="${1:---all}"

# Activate environment
source "${VENV_DIR}/bin/activate"
export OMNI_KIT_ACCEPT_EULA=YES

cd "${PLUGIN_DIR}"

echo "============================================="
echo "Lucitra Validate — Isaac Sim Test Runner"
echo "============================================="
echo "Suite: ${TEST_SUITE}"
echo "Dir:   ${PLUGIN_DIR}"
echo ""

run_unit() {
    echo "── Unit + USD Smoke Tests ──"
    python -m pytest tests/test_client.py tests/test_exporter.py tests/test_validator.py tests/test_usd_smoke.py -v
    echo ""
}

run_gpu() {
    echo "── GPU Runtime Smoke Test ──"
    # isaacsim launcher sets up Kit runtime paths required by SimulationApp/pxr
    isaacsim python scripts/test-runtime.py
    echo ""
}

run_e2e() {
    echo "── E2E Tests (Live API) ──"
    python -m pytest tests/test_e2e.py -v -m e2e
    echo ""
}

case "${TEST_SUITE}" in
    --unit)  run_unit ;;
    --gpu)   run_gpu ;;
    --e2e)   run_e2e ;;
    --all)   run_unit; run_gpu; run_e2e ;;
    *)
        echo "Unknown suite: ${TEST_SUITE}"
        echo "Options: --unit, --gpu, --e2e, --all"
        exit 1
        ;;
esac

echo "============================================="
echo "Tests complete."
echo "============================================="
