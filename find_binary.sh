#!/bin/bash

echo "🔍 Recherche automatique du binaire compilé"
echo "=========================================="

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
    exit 1
fi

cd llama.cpp

# Vérification du répertoire build
if [ ! -d "build" ]; then
    print_error "Répertoire build non trouvé"
    exit 1
fi

cd build

# Recherche de binaires possibles
print_status "Recherche de binaires compilés..."

# Liste des noms possibles (par ordre de priorité)
binaries=(
    "llama-server"
    "main"
    "llama"
    "server"
    "llama-cpp"
    "llama-cpp-server"
    "llama-cpp-python"
)

found_binary=""

for binary in "${binaries[@]}"; do
    if [ -f "$binary" ] && [ -x "$binary" ]; then
        found_binary="$binary"
        print_status "✅ Binaire trouvé : $binary"
        echo "   Taille: $(du -h "$binary" | cut -f1)"
        echo "   Permissions: $(ls -la "$binary" | awk '{print $1}')"
        break
    fi
done

if [ -z "$found_binary" ]; then
    print_error "❌ Aucun binaire exécutable trouvé"
    print_status "Fichiers dans le répertoire build :"
    ls -la
    
    print_status "Recherche de tous les fichiers exécutables :"
    find . -type f -executable -exec ls -la {} \;
    
    exit 1
fi

# Retour au répertoire principal
cd ../..

print_status "🎯 Binaire identifié : $found_binary"
print_status "Chemin complet : $(pwd)/llama.cpp/build/$found_binary"

# Création d'un fichier de configuration avec le nom du binaire
echo "LLAMA_BINARY=$found_binary" > .llama_binary

print_status "✅ Configuration sauvegardée dans .llama_binary"
print_status "Vous pouvez maintenant utiliser ce binaire dans vos scripts" 