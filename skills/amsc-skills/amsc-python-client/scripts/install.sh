#!/usr/bin/env bash
# Install amsc-client and dependencies into a virtualenv.
# Supports: uv (preferred), python3 venv + pip. Never installs into system Python.
#
# Dependency-confusion hardening: the GitLab package registries forward unknown names to
# public PyPI, so index ordering cannot protect the AmSC packages. They are instead
# installed from direct wheel URLs carrying a #sha256= fragment.
# All other dependencies resolve from PyPI.
#
# Version choice: amsc-client 0.5.0 + amsc-api-autogen 0.5.5. Do not bump past 0.5.x
# until a verified install source is documented for newer releases. The globus extra pulls
# in globus-sdk; iri-api-autogen is not used by the skill scripts and is not installed.
set -euo pipefail

# Lowest Python supported by the pinned wheels (amsc-api-autogen 0.5.5 needs >=3.11).
PY_MIN_MAJOR=3
PY_MIN_MINOR=11

GITLAB="https://gitlab.com/api/v4/projects"
AMSC_CLIENT_WHEEL="amsc_client-0.5.0-py3-none-any.whl"
AMSC_CLIENT_SHA="adab9776469899c8e81abf75536c5ea93b6a17742cf5de169449d6a2663e8858"
AMSC_API_WHEEL="amsc_api_autogen-0.5.5-py3-none-any.whl"
AMSC_API_SHA="deab7954f3ca4dc370c3bdb751571e935256bb36a99bcf171d1af8fc32ed6a11"

REQUIREMENTS=(
  "amsc-client[globus] @ $GITLAB/77567162/packages/pypi/files/$AMSC_CLIENT_SHA/$AMSC_CLIENT_WHEEL#sha256=$AMSC_CLIENT_SHA"
  "amsc-api-autogen @ $GITLAB/76368190/packages/pypi/files/$AMSC_API_SHA/$AMSC_API_WHEEL#sha256=$AMSC_API_SHA"
)

# Fail unless the given interpreter is at least PY_MIN_MAJOR.PY_MIN_MINOR.
require_python() {
  local py="$1" what="$2"
  if ! "$py" -c "pass" 2>/dev/null; then
    echo "ERROR: $what: cannot run $py." >&2
    exit 1
  fi
  if ! "$py" -c "import sys; sys.exit(0 if sys.version_info >= ($PY_MIN_MAJOR, $PY_MIN_MINOR) else 1)"; then
    echo "ERROR: $what is $("$py" -c "import sys; print(sys.version.split()[0])"); need Python >= $PY_MIN_MAJOR.$PY_MIN_MINOR." >&2
    echo "Use a newer Python (remove the venv or choose another path if it is a venv)." >&2
    exit 1
  fi
}

# Accept optional venv path as $1 (default: .venv)
VENV_DIR="${1:-.venv}"

if command -v uv &>/dev/null; then
  echo "Using uv to create venv and install..."
  [ -d "$VENV_DIR" ] || uv venv --no-python-downloads --python ">=$PY_MIN_MAJOR.$PY_MIN_MINOR" "$VENV_DIR"
  require_python "$VENV_DIR/bin/python3" "existing venv $VENV_DIR"
  uv pip install --python "$VENV_DIR/bin/python3" "${REQUIREMENTS[@]}"
elif python3 -c "import venv" 2>/dev/null; then
  echo "Using python3 venv + pip..."
  if [ ! -d "$VENV_DIR" ]; then
    require_python python3 "python3"
    python3 -m venv "$VENV_DIR"
  fi
  require_python "$VENV_DIR/bin/python3" "existing venv $VENV_DIR"
  "$VENV_DIR/bin/pip" install "${REQUIREMENTS[@]}"
else
  echo "ERROR: need uv or python3 with the venv module; refusing to install into system Python." >&2
  exit 1
fi

echo ""
echo "amsc-client installed in $VENV_DIR (activate: source $VENV_DIR/bin/activate)"
echo "Run 'python3 .claude/skills/amsc-python-client/scripts/verify_setup.py' to verify."
