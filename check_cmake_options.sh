#!/bin/bash

echo "🔍 Vérification des options CMake disponibles"
echo "============================================"

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

# Vérification de llama.cpp
if [ ! -d "llama.cpp" ]; then
    print_error "llama.cpp non trouvé"
    print_status "Exécutez d'abord : ./install_clean.sh"
    exit 1
fi

cd llama.cpp

# Création d'un répertoire temporaire pour la vérification
print_status "Création d'un répertoire temporaire..."
mkdir -p temp_check
cd temp_check

# Affichage des options CMake disponibles
print_status "Options CMake disponibles dans llama.cpp :"
echo ""

# Tentative de configuration avec affichage des options
cmake .. -L 2>/dev/null | grep -E "^LLAMA_" | head -20

echo ""
print_status "Options CMake recommandées :"
echo "  -DLLAMA_BLAS=ON"
echo "  -DLLAMA_OPENBLAS=ON"
echo "  -DLLAMA_NATIVE=ON"
echo "  -DLLAMA_BUILD_SERVER=ON"
echo "  -DLLAMA_METAL=OFF (pour éviter les conflits)"
echo "  -DLLAMA_CUBLAS=OFF (pour CPU uniquement)"

# Nettoyage
cd ..
rm -rf temp_check

print_status "✅ Vérification terminée"
print_status "Utilisez ces options pour une compilation optimisée" 