#!/usr/bin/env bash

# Ibex Environment Setup Script
# Source this script to activate the Ibex environment
# Usage: source setup_env.sh

IBEX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(dirname "$IBEX_DIR")"
VERILATOR_DIR="$TOOLS_DIR/verilator"
IBEX_HOST_TOOLS="$TOOLS_DIR/ibex-host-tools"

# Activate virtual environment
if [ -d "$IBEX_DIR/venv" ]; then
    source "$IBEX_DIR/venv/bin/activate"
    echo "Virtual environment activated"
else
    echo "Warning: Virtual environment not found at $IBEX_DIR/venv"
fi

# Set Ibex-specific environment variables
export IBEX_ROOT="$IBEX_DIR"
export PATH="$IBEX_DIR/venv/bin:$PATH"

# SCORE project-local prebuilts (portable install path)
if [ -d "$IBEX_HOST_TOOLS/riscv/bin" ]; then
    export RISCV="$IBEX_HOST_TOOLS/riscv"
    export PATH="$RISCV/bin:$PATH"
fi
if [ -d "$IBEX_HOST_TOOLS/riscv-isa-sim/bin" ]; then
    export PATH="$IBEX_HOST_TOOLS/riscv-isa-sim/bin:$PATH"
fi
if [ -d "$IBEX_HOST_TOOLS/verilator" ]; then
    for _v in "$IBEX_HOST_TOOLS/verilator"/*; do
        [ -d "$_v/bin" ] && export PATH="$_v/bin:$PATH"
    done
fi
if [ -d "$IBEX_HOST_TOOLS/verible/bin" ]; then
    export PATH="$IBEX_HOST_TOOLS/verible/bin:$PATH"
fi
if [ -d "$IBEX_HOST_TOOLS/srecord/bin" ]; then
    export PATH="$IBEX_HOST_TOOLS/srecord/bin:$PATH"
fi

# Add local Verilator installation to PATH if it exists
if [ -d "$VERILATOR_DIR/install/bin" ]; then
    export PATH="$VERILATOR_DIR/install/bin:$PATH"
    echo "Local Verilator installation added to PATH"
fi

# Upstream CI paths (/tools/...) when install-build-deps.sh was used with sudo
if [ -d "/tools/riscv-isa-sim/bin" ]; then
    export PATH="/tools/riscv-isa-sim/bin:$PATH"
fi
if [ -d "/tools/verilator/bin" ]; then
    export PATH="/tools/verilator/bin:$PATH"
fi
if [ -d "/tools/verible/bin" ]; then
    export PATH="/tools/verible/bin:$PATH"
fi
if [ -d "/tools/riscv/bin" ]; then
    export RISCV="/tools/riscv"
    export PATH="$RISCV/bin:$PATH"
fi

# Prebuilts above prepend to PATH; put the Ibex venv back in front so `python3` and FuseSoC
# pre_build hooks use the venv (packaging, edalize, etc.).
export PATH="$IBEX_DIR/venv/bin:$PATH"

# Portable Verilator prebuilts embed CI paths in generated makefiles unless VERILATOR_ROOT points at
# the real .../share/verilator tree. install_ibex_portable_host_tools adds symlinks under
# share/verilator/bin so the perl driver and V*.mk recipes both resolve.
if command -v verilator >/dev/null 2>&1; then
    _VER_BIN="$(command -v verilator)"
    _VER_PREFIX="$(cd "$(dirname "$_VER_BIN")/.." && pwd)"
    if [ -f "$_VER_PREFIX/share/verilator/include/verilated.mk" ]; then
        export VERILATOR_ROOT="$_VER_PREFIX/share/verilator"
    fi
    unset _VER_BIN _VER_PREFIX
fi
export MAKEFLAGS="${MAKEFLAGS:+$MAKEFLAGS }-e"

echo "Ibex environment setup complete"
echo "IBEX_ROOT: $IBEX_ROOT"
echo "Python: $(command -v python)"
echo "Python3: $(command -v python3)"
echo "Verilator: $(command -v verilator 2>/dev/null || echo 'not found')"
if [ -n "$(which verilator 2>/dev/null)" ]; then
    echo "Verilator version: $(verilator --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+' | head -1)"
fi
