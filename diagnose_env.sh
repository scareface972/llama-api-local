#!/bin/bash

echo "🔍 Diagnostic de l'environnement Python"
echo "======================================"

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

echo ""
print_status "=== Informations système ==="
echo "OS: $(lsb_release -d | cut -f2)"
echo "Architecture: $(uname -m)"
echo "Utilisateur: $(whoami)"
echo "Répertoire: $(pwd)"

echo ""
print_status "=== Versions Python ==="
echo "Python3: $(python3 --version 2>/dev/null || echo 'Non installé')"
echo "Python: $(python --version 2>/dev/null || echo 'Non installé')"
echo "Pip3: $(pip3 --version 2>/dev/null || echo 'Non installé')"
echo "Pip: $(pip --version 2>/dev/null || echo 'Non installé')"

echo ""
print_status "=== Variables d'environnement ==="
echo "VIRTUAL_ENV: ${VIRTUAL_ENV:-'Non défini'}"
echo "PYTHONPATH: ${PYTHONPATH:-'Non défini'}"
echo "PYTHONHOME: ${PYTHONHOME:-'Non défini'}"

echo ""
print_status "=== Environnement virtuel ==="
if [ -d "venv" ]; then
    print_status "✅ Dossier venv trouvé"
    echo "   Taille: $(du -sh venv | cut -f1)"
    echo "   Permissions: $(ls -ld venv)"
    
    if [ -f "venv/bin/activate" ]; then
        print_status "✅ Script d'activation trouvé"
    else
        print_error "❌ Script d'activation manquant"
    fi
    
    if [ -f "venv/bin/python" ]; then
        print_status "✅ Python virtuel trouvé"
        echo "   Version: $(venv/bin/python --version)"
    else
        print_error "❌ Python virtuel manquant"
    fi
    
    if [ -f "venv/bin/pip" ]; then
        print_status "✅ Pip virtuel trouvé"
        echo "   Version: $(venv/bin/pip --version)"
    else
        print_error "❌ Pip virtuel manquant"
    fi
else
    print_warning "⚠️  Dossier venv non trouvé"
fi

echo ""
print_status "=== Test d'activation ==="
if [ -d "venv" ]; then
    echo "Tentative d'activation..."
    source venv/bin/activate 2>&1
    
    if [ -n "$VIRTUAL_ENV" ]; then
        print_status "✅ Environnement virtuel activé"
        echo "   Chemin: $VIRTUAL_ENV"
        echo "   Python: $(which python)"
        echo "   Pip: $(which pip)"
    else
        print_error "❌ Échec de l'activation"
    fi
fi

echo ""
print_status "=== Test d'installation ==="
if [ -n "$VIRTUAL_ENV" ]; then
    echo "Test d'installation de pip..."
    python -m pip install --upgrade pip --dry-run 2>&1 | head -5
    
    echo ""
    echo "Test d'installation d'un package..."
    python -m pip install requests --dry-run 2>&1 | head -5
else
    print_warning "⚠️  Environnement virtuel non activé"
fi

echo ""
print_status "=== Recommandations ==="
if [ ! -d "venv" ]; then
    print_status "1. Créer un environnement virtuel : python3 -m venv venv"
elif [ -z "$VIRTUAL_ENV" ]; then
    print_status "1. Activer l'environnement : source venv/bin/activate"
fi

print_status "2. Utiliser python -m pip au lieu de pip directement"
print_status "3. Vérifier les permissions du dossier venv"
print_status "4. En cas de problème, supprimer et recréer venv"

echo ""
print_status "=== Commandes de réparation ==="
echo "Pour réparer l'environnement :"
echo "  rm -rf venv"
echo "  python3 -m venv venv"
echo "  source venv/bin/activate"
echo "  python -m pip install --upgrade pip"
echo "  python -m pip install -r requirements.txt"

echo ""
print_status "Diagnostic terminé !" 