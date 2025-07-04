#!/bin/bash

echo "🔍 Diagnostic des fichiers compilés"
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

# Vérification de llama.cpp
if [ ! -d "llama.cpp" ]; then
    print_error "llama.cpp non trouvé"
    print_status "Exécutez d'abord : ./install_clean.sh"
    exit 1
fi

cd llama.cpp

# Vérification du répertoire build
if [ ! -d "build" ]; then
    print_error "Répertoire build non trouvé"
    print_status "Exécutez d'abord : ./compile_default.sh"
    exit 1
fi

cd build

print_status "Contenu du répertoire build :"
echo "=================================="
ls -la

echo ""
print_status "Fichiers exécutables :"
echo "=========================="
find . -type f -executable -exec ls -la {} \;

echo ""
print_status "Fichiers avec extension :"
echo "=============================="
find . -type f -name "*.exe" -o -name "llama*" -o -name "main*" -o -name "server*" | head -10

echo ""
print_status "Fichiers les plus récents :"
echo "================================"
ls -lat | head -10

echo ""
print_status "Recherche de binaires courants :"
echo "====================================="

# Recherche de binaires courants
binaries=("llama-server" "main" "llama" "server" "llama-cpp" "llama-cpp-server")

for binary in "${binaries[@]}"; do
    if [ -f "$binary" ]; then
        print_status "✅ Trouvé : $binary"
        echo "   Taille: $(du -h "$binary" | cut -f1)"
        echo "   Permissions: $(ls -la "$binary" | awk '{print $1}')"
    else
        print_warning "❌ Non trouvé : $binary"
    fi
done

# Retour au répertoire principal
cd ../..

print_status "✅ Diagnostic terminé"
print_status "Utilisez les informations ci-dessus pour identifier le bon binaire" 