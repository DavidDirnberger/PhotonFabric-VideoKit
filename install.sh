#!/usr/bin/env bash
# -----------------------------------------------------------------------------
#  install.sh – Video‑Manager + Real‑ESRGAN (Conda‑basiert)
#  Unterstützt Linux und macOS; für Windows bitte "Anaconda Prompt" nutzen.
# -----------------------------------------------------------------------------
set -euo pipefail

# Suppress tarfile DeprecationWarnings during Conda operations
export PYTHONWARNINGS="${PYTHONWARNINGS:-ignore::DeprecationWarning}"

ENV_NAME="videoManager"
PYTHON_VERSION="3.11"
TORCH_VER="2.2.1"
VISION_VER="0.17.1"
VIDEO_CMD="video"

# ───────────────────────────── Interaktiver Pfad‑Dialog ─────────────────────
DEFAULT_BASE="$HOME/syscripts/videoManager"
read -erp "Installationsverzeichnis [$DEFAULT_BASE]: " INSTALL_DIR
INSTALL_DIR="${INSTALL_DIR:-$DEFAULT_BASE}"
# remove possible trailing slash
INSTALL_DIR="${INSTALL_DIR%/}"
VENV_DIR="$INSTALL_DIR/venv"
CONDA_DIR="${CONDA_DIR:-$INSTALL_DIR/miniconda}"

# Directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Extract optional src.tar.gz located next to this script
ARCHIVE="$SCRIPT_DIR/src.tar.gz"
if [[ -f "$ARCHIVE" ]]; then
  log "Entpacke src.tar.gz nach $INSTALL_DIR"
  tar -xzf "$ARCHIVE" -C "$INSTALL_DIR"
fi

CONDA_PREFIX="$CONDA_DIR/envs/$ENV_NAME"
ALIAS_LINE="alias $VIDEO_CMD=\"$CONDA_PREFIX/bin/python $INSTALL_DIR/videoManager.py\""

# Ask if AI features should be installed
if ask_question "Möchtest du KI-Funktionen (Real-ESRGAN, PyTorch) installieren?" "y"; then
  INSTALL_AI=true
else
  INSTALL_AI=false
fi


INSTALL_CUDA_TOOLKIT=false
for a in "$@"; do [[ "$a" == "--cuda-toolkit" ]] && INSTALL_CUDA_TOOLKIT=true; done

# optional: CUDA Toolkit (nur falls Flag gesetzt)
if $INSTALL_CUDA_TOOLKIT && $INSTALL_AI; then
  log "Installiere NVIDIA CUDA Toolkit 11.8 (deb‑local) …"
  wget -qO /tmp/cuda-repo.deb "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin"
  sudo mv /tmp/cuda-repo.deb /etc/apt/preferences.d/cuda-repository-pin-600
  curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/3bf863cc.pub | sudo gpg --dearmor -o /usr/share/keyrings/cuda-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/cuda-archive-keyring.gpg] https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/ /" | sudo tee /etc/apt/sources.list.d/cuda.list >/dev/null
  sudo apt-get update -qq && sudo apt-get install -y cuda-toolkit-11-8
fi

# ───────────────────────────── Hilfsfunktionen ──────────────────────────────
log()  { echo -e "\e[32m[install]\e[0m $*"; }
warn() { echo -e "\e[33m[install]\e[0m $*"; }
err()  { echo -e "\e[31m[install]\e[0m $*" >&2; exit 1; }


ask_question() {
    # ANSI colors for yellow-orange (color 214) and bold
    local COLOR="\e[1;38;5;214m"
    local RESET="\e[0m"
    local BOLD="\e[1m"
    
    local question="$1"
    shift

    local choices=()
    local default=""
    local default_index=1

    # Collect answer options, determine default
    local idx=1
    for opt in "$@"; do
        if [[ "$opt" =~ ^# ]]; then
            default="${opt:1}"
            default_index=$idx
            choices+=("${opt:1}")
        else
            choices+=("$opt")
        fi
        ((idx++))
    done

    # If no default found, use the first option
    if [ -z "$default" ]; then
        default="${choices[0]}"
        default_index=1
    fi

    # Print the question (bold + yellow-orange)
    echo -e -n "${BOLD}${COLOR}${question}${RESET}\n"

    # Print the answer options
    for i in "${!choices[@]}"; do
        local disp="${choices[$i]}"
        # Mark default option
        if [ $((i+1)) -eq $default_index ]; then
            echo -e "  $((i+1)). $disp ${COLOR}[Default]${RESET}"
        else
            echo "  $((i+1)). $disp"
        fi
    done

    # Prompt for input
    echo -ne "\nPlease choose an option (number or name, Enter for default: ${default}): "
    local input
    read input

    # If input is empty, return default
    if [ -z "$input" ]; then
        echo "$default"
        return 0
    fi

    # Check if input is a number
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        if (( input >= 1 && input <= ${#choices[@]} )); then
            echo "${choices[$((input-1))]}"
            return 0
        fi
    fi

    # Check input as text (case-insensitive)
    local input_lc=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    for i in "${!choices[@]}"; do
        local choice_lc=$(echo "${choices[$i]}" | tr '[:upper:]' '[:lower:]')
        if [[ "$input_lc" == "$choice_lc" ]]; then
            echo "${choices[$i]}"
            return 0
        fi
    done

    # If nothing matches: return default
    echo "$default"
}


# Robust pip installation with retries
pip_install() {
  local attempts=4
  local args=("$@")
  for ((i=1; i<=attempts; i++)); do
    python -m pip install --retries 6 --timeout 60 "${args[@]}" && return 0
    warn "pip install failed (Attempt $i/$attempts)"
    sleep 10
  done
  err "pip install failed after $attempts attempts"
}



# Download utility with retries and aria2c/curl fallback
download_with_retries() {
  local url=$1 dest=$2 attempts=3
  for ((i=1; i<=attempts; i++)); do
    if command -v aria2c &>/dev/null; then
      aria2c -c -x16 -s16 -k1M -o "$(basename "$dest")" -d "$(dirname "$dest")" "$url" && return 0
    else
      curl -L --retry 5 --retry-delay 5 -C - "$url" -o "$dest" && return 0
    fi
    warn "Download failed (Attempt $i/$attempts)"
    sleep 5
  done
  err "Failed to download $url"
}


# Run conda/mamba commands with retries to handle transient network issues
conda_retry() {
  local attempts=3
  for ((i=1; i<=attempts; i++)); do
    $CMD_INSTALL "$@" && return 0
    warn "Conda command failed (Attempt $i/$attempts)"
    sleep 5
  done
  err "Conda command failed after $attempts attempts"
}

# Download typical Real-ESRGAN weights
download_realesrgan_models() {
  local dest="$RE_DIR/weights"
  mkdir -p "$dest"
  declare -A urls=(
    [RealESRGAN_x4plus.pth]='https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth'
    [RealESRGAN_x4plus_anime_6B.pth]='https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.2.4/RealESRGAN_x4plus_anime_6B.pth'
    [realesr-general-x4v3.pth]='https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.5.0/realesr-general-x4v3.pth'
  )
  for f in "${!urls[@]}"; do
    [ -f "$dest/$f" ] && continue
    download_with_retries "${urls[$f]}" "$dest/$f"
  done
}



#======================== Alias Setup ============================
if ! grep -qs "$ALIAS_LINE" "$HOME/.bashrc" "$HOME/.bash_aliases" 2>/dev/null; then
  echo -e "\nAlias '$VIDEO_CMD' not found. Where should it be added?"; select d in "$HOME/.bashrc" "$HOME/.bash_aliases" "Custom" "None"; do
    case $REPLY in
      1|2) echo "$ALIAS_LINE" >> "$d"; break ;;
      3) read -rp "Pfad: " p; echo "$ALIAS_LINE" >> "$p"; break ;;
      *) break ;;
    esac; done
fi

# ───────────────────── Miniconda Installation prüfen ─────────────────────
export PATH="$CONDA_DIR/bin:$PATH"
if ! command -v conda &>/dev/null && ! command -v mamba &>/dev/null; then
  log "🔄 Conda nicht gefunden – installiere Miniconda lokal..."
  INSTALLER="Miniconda3-latest-Linux-x86_64.sh"
  URL="https://repo.anaconda.com/miniconda/$INSTALLER"

  download_with_retries "$URL" "/tmp/$INSTALLER"
  bash "/tmp/$INSTALLER" -b -p "$CONDA_DIR"
  rm "/tmp/$INSTALLER"
  export PATH="$CONDA_DIR/bin:$PATH"
fi
# Prefer mamba if available
CMD_INSTALL="conda"
if command -v mamba &>/dev/null; then
  CMD_INSTALL="mamba"
fi

# Initialize conda in script
# shellcheck disable=SC1091
source "$(conda info --base)/etc/profile.d/conda.sh"
source "$CONDA_DIR/etc/profile.d/conda.sh"


# Auto accept Terms of Service for Anaconda channels if supported
if conda --help | grep -q "tos"; then
  conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main >/dev/null 2>&1 || true
  conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r >/dev/null 2>&1 || true
fi



# ───────────────────── Create/Activate Env ───────────────────────────
if ! conda env list | grep -qE "^${ENV_NAME}[[:space:]]"; then
  echo "🆕 Erstelle Conda-Environment '$ENV_NAME' (Python $PYTHON_VERSION)..."
  conda_retry create -y -n "$ENV_NAME" python="$PYTHON_VERSION"
fi

conda activate "$ENV_NAME"

echo "🔁 Activated environment '$ENV_NAME'"

# ───────────────────── GPU-/CPU-Paketwahl ────────────────────────────
GPU=false
if command -v nvidia-smi &>/dev/null; then
  GPU=true
  echo "✅ CUDA-fähige GPU erkannt"
else
  echo "⚠️  Keine CUDA-GPU erkannt – nutze CPU-only"
fi

# ───────────────────── PyTorch & Vision ──────────────────────────────
if [ "$GPU" = true ]; then
  conda_retry install -y pytorch="$TORCH_VER" torchvision="$VISION_VER" cudatoolkit=11.8 -c pytorch -c conda-forge
else
  conda_retry install -y pytorch="$TORCH_VER" torchvision="$VISION_VER" cpuonly -c pytorch -c conda-forge
fi

# ───────────────────── Sonstige Bibliotheken ─────────────────────────
conda_retry install -y \
  ffmpeg pillow networkx sympy jinja2 fsspec filelock requests kiwisolver llvmlite -c conda-forge

# ───────────────────── Real-ESRGAN Setup ─────────────────────────────
RE_DIR="$INSTALL_DIR/real-esrgan"
if [ -d "$RE_DIR" ]; then
  git -C "$RE_DIR" pull --quiet
else
  git clone --quiet https://github.com/xinntao/Real-ESRGAN "$RE_DIR"
fi
pip_install -q -r "$RE_DIR/requirements.txt"
download_realesrgan_models

echo "🎉 Fertig! Aktiviere mit: conda activate $ENV_NAME"
