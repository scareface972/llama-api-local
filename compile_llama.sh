#!/bin/bash

echo "🔨 Compilation rapide de llama.cpp avec CMake"
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

# Vérification de l'utilisateur
if [ "$EUID" -eq 0 ]; then
    print_error "Ne pas exécuter ce script en tant que root"
    print_status "Utilisez un utilisateur normal"
    exit 1
fi

# Vérification de llama.cpp
if [ ! -d "llama.cpp" ]; then
    print_error "llama.cpp non trouvé"
    print_status "Exécutez d'abord : ./install_clean.sh"
    exit 1
fi

cd llama.cpp

# Nettoyage de l'ancienne compilation
if [ -d "build" ]; then
    print_status "Nettoyage de l'ancienne compilation..."
    rm -rf build
fi

# Création du répertoire build
print_status "Création du répertoire build..."
mkdir -p build
cd build

# Configuration CMake avec optimisations
print_status "Configuration CMake avec optimisations..."
cmake ..

if [ $? -ne 0 ]; then
    print_error "Échec de la configuration CMake"
    exit 1
fi

# Compilation
print_status "Compilation en cours..."
make -j$(nproc)

if [ $? -eq 0 ]; then
    print_status "✅ Compilation terminée avec succès !"
    
    # Vérification du binaire
    if [ -f "llama-server" ]; then
        print_status "✅ Binaire llama-server créé"
        print_status "Taille: $(du -h llama-server | cut -f1)"
    elif [ -f "main" ]; then
        print_status "✅ Binaire main créé"
        print_status "Taille: $(du -h main | cut -f1)"
    else
        print_error "❌ Binaire llama-server ou main non trouvé"
        print_status "Fichiers dans le répertoire build :"
        ls -la
        exit 1
    fi
    
else
    print_error "❌ Échec de la compilation"
    exit 1
fi

# Retour au répertoire principal
cd ../..

print_status "🎉 llama.cpp compilé avec succès !"
print_status "Vous pouvez maintenant démarrer le serveur : ./start_server.sh" 