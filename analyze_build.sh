#!/bin/bash

echo "🔬 Analyse avancée du répertoire build"
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

print_status "📁 Contenu complet du répertoire build :"
echo "============================================="
ls -la

echo ""
print_status "🔍 Tous les fichiers exécutables :"
echo "======================================="
find . -type f -executable -exec ls -la {} \; 2>/dev/null

echo ""
print_status "📊 Fichiers par taille (plus gros en premier) :"
echo "=================================================="
find . -type f -exec ls -la {} \; 2>/dev/null | sort -k5 -nr | head -10

echo ""
print_status "🕒 Fichiers par date (plus récents en premier) :"
echo "=================================================="
ls -lat | head -10

echo ""
print_status "🔧 Recherche de fichiers binaires :"
echo "========================================"

# Recherche de fichiers binaires (non-text)
find . -type f -exec file {} \; 2>/dev/null | grep -E "(executable|binary|ELF)" | head -10

echo ""
print_status "📝 Recherche de fichiers de configuration :"
echo "==============================================="
find . -name "*.cmake" -o -name "CMakeCache.txt" -o -name "Makefile" | head -5

echo ""
print_status "🎯 Analyse des cibles CMake :"
echo "================================="
if [ -f "CMakeCache.txt" ]; then
    grep -E "CMAKE_TARGETS" CMakeCache.txt 2>/dev/null || echo "Aucune cible trouvée"
else
    echo "CMakeCache.txt non trouvé"
fi

echo ""
print_status "🔍 Recherche de patterns spécifiques :"
echo "==========================================="

# Recherche de fichiers avec des patterns spécifiques
patterns=("llama*" "server*" "main*" "ggml*" "gguf*" "model*" "inference*")

for pattern in "${patterns[@]}"; do
    echo "Pattern '$pattern' :"
    find . -name "$pattern" -type f 2>/dev/null | head -3
    echo ""
done

echo ""
print_status "📋 Résumé des fichiers potentiellement utiles :"
echo "=================================================="

# Recherche de fichiers qui pourraient être des binaires
potential_binaries=$(find . -type f -executable -o -name "llama*" -o -name "server*" -o -name "main*" 2>/dev/null | head -10)

if [ -n "$potential_binaries" ]; then
    echo "$potential_binaries" | while read file; do
        if [ -f "$file" ]; then
            size=$(du -h "$file" 2>/dev/null | cut -f1)
            perms=$(ls -la "$file" 2>/dev/null | awk '{print $1}')
            echo "  📄 $file ($size, $perms)"
        fi
    done
else
    print_warning "Aucun fichier potentiellement utile trouvé"
fi

# Retour au répertoire principal
cd ../..

print_status "✅ Analyse terminée"
print_status "Vérifiez les fichiers listés ci-dessus pour identifier le binaire compilé" 