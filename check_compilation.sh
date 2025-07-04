#!/bin/bash

echo "🔍 Vérification de la compilation"
echo "================================"

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

print_status "📁 Vérification de la structure :"
echo "===================================="
ls -la

echo ""
print_status "🔍 Vérification du répertoire build :"
echo "========================================="

if [ -d "build" ]; then
    cd build
    print_status "✅ Répertoire build existe"
    
    echo ""
    print_status "📋 Contenu du répertoire build :"
    echo "===================================="
    ls -la
    
    echo ""
    print_status "🔧 Vérification des fichiers CMake :"
    echo "========================================"
    
    if [ -f "CMakeCache.txt" ]; then
        print_status "✅ CMakeCache.txt trouvé"
        echo "Taille: $(du -h CMakeCache.txt | cut -f1)"
    else
        print_error "❌ CMakeCache.txt manquant"
    fi
    
    if [ -f "Makefile" ]; then
        print_status "✅ Makefile trouvé"
        echo "Taille: $(du -h Makefile | cut -f1)"
    else
        print_error "❌ Makefile manquant"
    fi
    
    echo ""
    print_status "🎯 Recherche de cibles compilées :"
    echo "======================================"
    
    # Recherche dans CMakeCache.txt
    if [ -f "CMakeCache.txt" ]; then
        echo "Cibles CMake trouvées :"
        grep -E "CMAKE_TARGETS|TARGETS" CMakeCache.txt 2>/dev/null | head -5 || echo "Aucune cible trouvée"
    fi
    
    echo ""
    print_status "📊 Fichiers les plus récents :"
    echo "=================================="
    ls -lat | head -5
    
    cd ..
else
    print_error "❌ Répertoire build manquant"
    print_status "La compilation n'a pas été effectuée ou a échoué"
fi

echo ""
print_status "🔍 Vérification des dépendances :"
echo "====================================="

# Vérification de CMake
if command -v cmake &> /dev/null; then
    cmake_version=$(cmake --version | head -1)
    print_status "✅ CMake installé : $cmake_version"
else
    print_error "❌ CMake non installé"
fi

# Vérification de make
if command -v make &> /dev/null; then
    make_version=$(make --version | head -1)
    print_status "✅ Make installé : $make_version"
else
    print_error "❌ Make non installé"
fi

# Vérification de gcc/g++
if command -v gcc &> /dev/null; then
    gcc_version=$(gcc --version | head -1)
    print_status "✅ GCC installé : $gcc_version"
else
    print_error "❌ GCC non installé"
fi

echo ""
print_status "🔧 Test de compilation rapide :"
echo "==================================="

if [ -d "build" ]; then
    cd build
    
    if [ -f "Makefile" ]; then
        print_status "Tentative de compilation d'une cible..."
        
        # Affichage des cibles disponibles
        echo "Cibles disponibles :"
        make help 2>/dev/null | head -10 || echo "Impossible d'afficher les cibles"
        
        echo ""
        print_status "Tentative de compilation..."
        
        # Compilation avec affichage des erreurs
        make -j1 2>&1 | tail -10
        
        if [ $? -eq 0 ]; then
            print_status "✅ Compilation réussie"
        else
            print_error "❌ Compilation échouée"
        fi
    else
        print_error "❌ Makefile manquant"
    fi
    
    cd ..
else
    print_error "❌ Répertoire build manquant"
fi

# Retour au répertoire principal
cd ..

print_status "✅ Vérification terminée"
print_status "Utilisez ./analyze_build.sh pour une analyse plus détaillée" 