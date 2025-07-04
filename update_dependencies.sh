#!/bin/bash

echo "🔄 Mise à jour des dépendances système"
echo "====================================="

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage avec couleur
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction de vérification d'erreur
check_error() {
    if [ $? -ne 0 ]; then
        print_error "$1"
        exit 1
    fi
}

# Mise à jour du système
print_status "Mise à jour du système..."
sudo apt update && sudo apt upgrade -y
check_error "Échec de la mise à jour du système"

# Installation des dépendances système corrigées
print_status "Installation des dépendances système corrigées..."
sudo apt install -y \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    python3 \
    python3-pip \
    python3-venv \
    nvidia-cuda-toolkit \
    nvidia-driver-535 \
    libopenblas-dev \
    liblapack-dev \
    libatlas-base-dev \
    gfortran \
    libssl-dev \
    libffi-dev \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    libxft-dev \
    pkg-config \
    libhdf5-dev \
    libhdf5-serial-dev \
    libgtk-3-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    libtiff-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libgtk2.0-dev \
    libtiff5-dev

check_error "Échec de l'installation des dépendances système"

# Vérification de l'environnement virtuel
print_status "Vérification de l'environnement virtuel..."
if [ -d "venv" ]; then
    print_status "Environnement virtuel trouvé, vérification de l'intégrité..."
    
    # Vérification de l'intégrité de l'environnement virtuel
    if [ ! -f "venv/bin/python" ] || [ ! -f "venv/bin/pip" ]; then
        print_warning "Environnement virtuel corrompu détecté"
        print_status "Suppression et recréation de l'environnement virtuel..."
        deactivate 2>/dev/null || true
        rm -rf venv
        python3 -m venv venv
        check_error "Échec de la recréation de l'environnement virtuel"
        print_status "✅ Nouvel environnement virtuel créé"
    fi
    
    # Activation explicite de l'environnement virtuel
    source venv/bin/activate
    
    # Vérification que l'environnement est activé
    if [ -z "$VIRTUAL_ENV" ]; then
        print_error "L'environnement virtuel n'est pas activé"
        print_error "Tentative de réactivation..."
        export VIRTUAL_ENV="$(pwd)/venv"
        export PATH="$VIRTUAL_ENV/bin:$PATH"
        unset PYTHONHOME
    fi
    
    print_status "Environnement virtuel activé : $VIRTUAL_ENV"
    
    # Vérification du Python utilisé
    PYTHON_PATH=$(which python)
    print_status "Python utilisé : $PYTHON_PATH"
    
    if [[ "$PYTHON_PATH" != *"venv"* ]]; then
        print_error "Python système utilisé au lieu de l'environnement virtuel"
        print_error "Suppression et recréation de l'environnement virtuel..."
        deactivate 2>/dev/null || true
        rm -rf venv
        python3 -m venv venv
        source venv/bin/activate
        check_error "Échec de la recréation de l'environnement virtuel"
    fi
    
    # Vérification que pip est disponible
    if ! python -c "import pip" 2>/dev/null; then
        print_warning "Pip non disponible, installation..."
        python -m ensurepip --upgrade
        check_error "Échec de l'installation de pip"
    fi
    
    # Mise à jour de pip dans l'environnement virtuel
    print_status "Mise à jour de pip dans l'environnement virtuel..."
    python -m pip install --upgrade pip
    check_error "Échec de la mise à jour de pip"
    
    # Réinstallation des dépendances Python
    print_status "Installation des dépendances Python..."
    ./update_requirements.sh
    check_error "Échec de l'installation des dépendances Python"
    
    print_status "✅ Dépendances Python mises à jour"
else
    print_warning "Environnement virtuel non trouvé"
    print_status "Création d'un nouvel environnement virtuel..."
    python3 -m venv venv
    source venv/bin/activate
    check_error "Échec de la création de l'environnement virtuel"
    
    print_status "Installation des dépendances dans le nouvel environnement..."
    python -m pip install --upgrade pip
    python -m pip install -r requirements.txt
    python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
    python -m pip install llama-cpp-python --index-url https://jllllll.github.io/llama-cpp-python-cuBLAS-wheels/AVX2/cu118
    check_error "Échec de l'installation des dépendances"
fi

# Vérification de llama.cpp
print_status "Vérification de llama.cpp..."
if [ -d "llama.cpp" ]; then
    print_status "Recompilation de llama.cpp..."
    cd llama.cpp
    make clean
    make LLAMA_CUBLAS=1 LLAMA_AVX=1 LLAMA_AVX2=1 LLAMA_F16C=1 LLAMA_FMA=1 LLAMA_BLAS=1 LLAMA_OPENBLAS=1 -j$(nproc)
    check_error "Échec de la compilation de llama.cpp"
    cd ..
    print_status "✅ llama.cpp recompilé"
else
    print_warning "llama.cpp non trouvé"
    print_status "Exécutez ./install.sh pour une installation complète"
fi

# Vérification finale
print_status "Vérification finale..."
if [ -d "venv" ]; then
    source venv/bin/activate
    if python -c "import fastapi, uvicorn, llama_cpp" 2>/dev/null; then
        print_status "✅ Toutes les dépendances sont installées"
    else
        print_error "❌ Problème avec les dépendances Python"
        print_status "Exécutez ./install.sh pour une réinstallation complète"
    fi
fi

print_status "✅ Mise à jour terminée !"
echo "=================================================="
echo "📋 Prochaines étapes :"
echo "1. Testez le serveur : ./start_server.sh"
echo "2. Ou démarrez le service : sudo systemctl restart llama-api"
echo "3. Vérifiez le statut : sudo systemctl status llama-api"
echo "==================================================" 