#!/usr/bin/env bash
set -euo pipefail

if [ ! -f .envrc ]; then
    cp .envrc.example .envrc
    echo "Created .envrc from .envrc.example — fill in 1C credentials"
fi

pre-commit install

BASHRC="${_REMOTE_USER_HOME:-$HOME}/.bashrc"
ZSHRC="${_REMOTE_USER_HOME:-$HOME}/.zshrc"

if ! grep -q _complete_bake "${BASHRC}" 2>/dev/null; then
    ./bake --print-completion-script=bash >> "${BASHRC}"
fi

if ! grep -q _complete_bake "${ZSHRC}" 2>/dev/null; then
    ./bake --print-completion-script=zsh >> "${ZSHRC}"
fi

if [ -n "${ZSH_VERSION:-}" ]; then
    eval "$(./bake --print-completion-script=zsh)"
else
    eval "$(./bake --print-completion-script=bash)"
fi

docker buildx version
./bake --version >/dev/null

echo ""
echo "Devcontainer ready."
echo "Build leaf target:    ./bake build oscript"
echo "Build server chain:   ./bake build server"
echo "Build full graph:     ./bake build default"
echo ""
