#!/bin/bash

echo "🤖 Installation de llama-cpp-python"
echo "=================================="

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
        return 1
    fi
    return 0
}

# Vérification de l'environnement virtuel
if [ -z "$VIRTUAL_ENV" ]; then
    print_error "Environnement virtuel non activé"
    print_status "Activation de l'environnement virtuel..."
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    else
        print_error "Environnement virtuel non trouvé"
        print_status "Exécutez d'abord : ./fix_venv.sh"
        exit 1
    fi
fi

print_status "Environnement virtuel activé : $VIRTUAL_ENV"

# Vérification de CUDA
print_status "Vérification de CUDA..."
if command -v nvidia-smi &> /dev/null; then
    print_status "✅ NVIDIA GPU détecté"
    CUDA_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits | head -1 | cut -d. -f1)
    print_status "Version CUDA détectée : $CUDA_VERSION"
else
    print_warning "⚠️  NVIDIA GPU non détecté, installation sans CUDA"
    CUDA_VERSION=""
fi

# Méthode 1 : Dépôt personnalisé avec CUDA
print_status "Méthode 1 : Installation depuis le dépôt personnalisé..."
if [ -n "$CUDA_VERSION" ]; then
    print_status "Tentative d'installation depuis le dépôt personnalisé..."
    if python -m pip install llama-cpp-python --force-reinstall --index-url https://jllllll.github.io/llama-cpp-python-cuBLAS-wheels/AVX2/cu118 2>/dev/null; then
        print_status "✅ llama-cpp-python installé depuis le dépôt personnalisé"
        exit 0
    else
        print_warning "❌ Échec de l'installation depuis le dépôt personnalisé"
    fi
else
    print_warning "⚠️  CUDA non détecté, passage à la méthode suivante"
fi

# Méthode 2 : Compilation CUDA depuis PyPI
print_status "Méthode 2 : Compilation CUDA depuis PyPI..."
if [ -n "$CUDA_VERSION" ]; then
    print_status "Installation avec compilation CUDA..."
    export CMAKE_ARGS="-DLLAMA_CUBLAS=on"
    export FORCE_CMAKE=1
    if python -m pip install llama-cpp-python --force-reinstall --no-cache-dir; then
        print_status "✅ llama-cpp-python installé avec compilation CUDA"
        exit 0
    else
        print_warning "❌ Échec de la compilation CUDA"
    fi
else
    print_warning "⚠️  CUDA non détecté, passage à la méthode suivante"
fi

# Méthode 3 : Installation standard depuis PyPI
print_status "Méthode 3 : Installation standard depuis PyPI..."
print_status "Installation sans CUDA (CPU uniquement)..."
if python -m pip install llama-cpp-python --force-reinstall --no-cache-dir; then
    print_status "✅ llama-cpp-python installé (CPU uniquement)"
    exit 0
else
    print_error "❌ Échec de l'installation standard"
fi

# Méthode 4 : Installation depuis le code source
print_status "Méthode 4 : Installation depuis le code source..."
print_status "Clonage du dépôt llama-cpp-python..."
if [ ! -d "llama-cpp-python-src" ]; then
    git clone https://github.com/abetlen/llama-cpp-python.git llama-cpp-python-src
fi

cd llama-cpp-python-src

if [ -n "$CUDA_VERSION" ]; then
    print_status "Compilation avec support CUDA..."
    export CMAKE_ARGS="-DLLAMA_CUBLAS=on"
    export FORCE_CMAKE=1
    python -m pip install . --force-reinstall --no-cache-dir
else
    print_status "Compilation sans CUDA..."
    python -m pip install . --force-reinstall --no-cache-dir
fi

if check_error "Échec de l'installation depuis le code source"; then
    cd ..
    print_status "✅ llama-cpp-python installé depuis le code source"
    exit 0
else
    cd ..
    print_error "❌ Toutes les méthodes d'installation ont échoué"
    exit 1
fi 