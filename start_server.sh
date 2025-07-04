#!/bin/bash

echo "🚀 Démarrage de l'API Llama.cpp"
echo "=============================="

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

# Vérification de l'environnement virtuel
if [ ! -d "venv" ]; then
    print_error "Environnement virtuel non trouvé"
    print_status "Exécutez d'abord : ./install_clean.sh"
    exit 1
fi

# Vérification du modèle
if [ ! -f "models/llama-2-7b-chat.gguf" ] && [ ! -f "models/llama-2-13b-chat.gguf" ] && [ ! -f "models/llama-2-7b.gguf" ] && [ ! -f "models/codellama-7b-instruct.gguf" ] && [ ! -f "models/mistral-7b-instruct.gguf" ]; then
    print_warning "Aucun modèle trouvé"
    print_status "Téléchargez un modèle avec : ./download_model.sh"
    echo ""
    read -p "Voulez-vous télécharger un modèle maintenant ? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./download_model.sh
        if [ $? -ne 0 ]; then
            print_error "Échec du téléchargement du modèle"
            exit 1
        fi
    else
        print_status "Démarrage sans modèle (le modèle devra être téléchargé manuellement)"
    fi
fi

# Activation de l'environnement virtuel
print_status "Activation de l'environnement virtuel..."
source venv/bin/activate

if [ -z "$VIRTUAL_ENV" ]; then
    print_error "Échec de l'activation de l'environnement virtuel"
    exit 1
fi

print_status "Environnement virtuel activé : $VIRTUAL_ENV"

# Vérification des dépendances
print_status "Vérification des dépendances..."
python -c "
import sys
packages = ['fastapi', 'uvicorn', 'llama_cpp']
missing = []
for pkg in packages:
    try:
        __import__(pkg)
        print(f'✅ {pkg} disponible')
    except ImportError:
        missing.append(pkg)
        print(f'❌ {pkg} manquant')

if missing:
    print(f'\\n❌ Packages manquants: {missing}')
    print('Exécutez : ./install_clean.sh')
    sys.exit(1)
else:
    print('\\n✅ Toutes les dépendances sont disponibles')
"

if [ $? -ne 0 ]; then
    print_error "Dépendances manquantes"
    exit 1
fi

# Vérification du port
print_status "Vérification du port 8000..."
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null ; then
    print_warning "⚠️  Le port 8000 est déjà utilisé"
    read -p "Voulez-vous continuer quand même ? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Arrêt du démarrage"
        exit 0
    fi
else
    print_status "✅ Port 8000 disponible"
fi

# Démarrage du serveur
print_status "Démarrage du serveur..."
echo ""
print_status "🌐 URLs d'accès :"
echo "   • Interface Web : http://localhost:8000"
echo "   • Documentation API : http://localhost:8000/docs"
echo "   • Health Check : http://localhost:8000/health"
echo ""
print_status "📋 Commandes utiles :"
echo "   • Arrêter le serveur : Ctrl+C"
echo "   • Voir les logs : tail -f logs/llama_api.log"
echo "   • Démarrer en service : sudo systemctl start llama-api"
echo ""

# Démarrage avec uvicorn
python llama_api.py 