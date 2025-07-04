#!/bin/bash

echo "🔧 Réparation de l'environnement virtuel"
echo "======================================="

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

print_status "Diagnostic de l'environnement virtuel..."

# Vérification de l'existence du dossier venv
if [ ! -d "venv" ]; then
    print_warning "Dossier venv non trouvé"
    print_status "Création d'un nouvel environnement virtuel..."
    python3 -m venv venv
    check_error "Échec de la création de l'environnement virtuel"
    print_status "✅ Environnement virtuel créé"
else
    print_status "Dossier venv trouvé"
    
    # Vérification de l'intégrité
    if [ ! -f "venv/bin/python" ]; then
        print_error "Python manquant dans l'environnement virtuel"
        print_status "Suppression et recréation..."
        rm -rf venv
        python3 -m venv venv
        check_error "Échec de la recréation de l'environnement virtuel"
        print_status "✅ Environnement virtuel recréé"
    else
        print_status "✅ Python trouvé dans l'environnement virtuel"
    fi
    
    if [ ! -f "venv/bin/pip" ]; then
        print_error "Pip manquant dans l'environnement virtuel"
        print_status "Installation de pip..."
        venv/bin/python -m ensurepip --upgrade
        check_error "Échec de l'installation de pip"
        print_status "✅ Pip installé"
    else
        print_status "✅ Pip trouvé dans l'environnement virtuel"
    fi
fi

# Activation de l'environnement virtuel
print_status "Activation de l'environnement virtuel..."
source venv/bin/activate
check_error "Échec de l'activation de l'environnement virtuel"

# Vérification de l'activation
if [ -z "$VIRTUAL_ENV" ]; then
    print_error "L'environnement virtuel n'est pas activé"
    exit 1
fi

print_status "Environnement virtuel activé : $VIRTUAL_ENV"

# Test de pip
print_status "Test de pip..."
if ! python -c "import pip" 2>/dev/null; then
    print_warning "Pip non fonctionnel, réinstallation..."
    python -m ensurepip --upgrade
    check_error "Échec de la réinstallation de pip"
fi

# Mise à jour de pip
print_status "Mise à jour de pip..."
python -m pip install --upgrade pip
check_error "Échec de la mise à jour de pip"

# Test d'installation
print_status "Test d'installation d'un package..."
python -m pip install requests --dry-run > /dev/null 2>&1
if [ $? -eq 0 ]; then
    print_status "✅ Pip fonctionne correctement"
else
    print_error "❌ Problème avec pip"
    exit 1
fi

print_status "✅ Environnement virtuel réparé !"
echo ""
print_status "Prochaines étapes :"
echo "1. Installer les dépendances : python -m pip install -r requirements.txt"
echo "2. Ou utiliser le script complet : ./update_dependencies.sh"
echo "3. Tester le serveur : ./start_server.sh"
echo "" 