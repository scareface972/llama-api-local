#!/bin/bash

echo "🔧 Installation des dépendances pour l'API Llama.cpp"
echo "=================================================="

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${CYAN}[SUCCESS]${NC} $1"
}

# Vérification de Python
print_status "Vérification de Python..."
PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
print_status "Version Python détectée: $PYTHON_VERSION"

# Vérification de pip
print_status "Vérification de pip..."
if ! command -v pip3 &> /dev/null; then
    print_error "pip3 n'est pas installé"
    print_status "Installation de pip3..."
    sudo apt update
    sudo apt install -y python3-pip
else
    print_success "pip3 est installé"
fi

# Mise à jour de pip
print_status "Mise à jour de pip..."
pip3 install --upgrade pip

# Vérification de l'environnement virtuel
if [ ! -d "venv" ]; then
    print_status "Création de l'environnement virtuel..."
    python3 -m venv venv
    print_success "Environnement virtuel créé"
else
    print_status "Environnement virtuel existant détecté"
fi

# Activation de l'environnement virtuel
print_status "Activation de l'environnement virtuel..."
source venv/bin/activate

# Vérification de l'activation
if [[ "$VIRTUAL_ENV" != "" ]]; then
    print_success "Environnement virtuel activé: $VIRTUAL_ENV"
else
    print_error "Échec de l'activation de l'environnement virtuel"
    exit 1
fi

# Installation des dépendances système
print_status "Installation des dépendances système..."
sudo apt update
sudo apt install -y build-essential cmake pkg-config

# Installation des dépendances Python
print_status "Installation des dépendances Python..."

# Installation par étapes pour éviter les conflits
print_status "Étape 1: Dépendances de base..."
pip install fastapi uvicorn[standard] pydantic python-multipart jinja2 aiofiles websockets

print_status "Étape 2: NumPy..."
pip install numpy

print_status "Étape 3: psutil..."
pip install psutil

print_status "Étape 4: PyTorch (version compatible Python 3.12)..."
pip install torch --index-url https://download.pytorch.org/whl/cpu

print_status "Étape 5: Transformers et dépendances..."
pip install transformers sentencepiece accelerate

print_status "Étape 6: llama-cpp-python..."
pip install llama-cpp-python

# Vérification de l'installation
print_status "Vérification de l'installation..."
echo ""

# Test des modules principaux
MODULES=("fastapi" "uvicorn" "pydantic" "numpy" "torch" "transformers" "llama_cpp")
for module in "${MODULES[@]}"; do
    if python -c "import $module" 2>/dev/null; then
        print_success "✅ $module installé"
    else
        print_error "❌ $module non installé"
    fi
done

echo ""
print_success "🎉 Installation terminée !"
echo ""
print_status "Prochaines étapes :"
echo "1. Télécharger un modèle : ./download_model.sh"
echo "2. Démarrer l'API : python3 llama_api.py"
echo "3. Ou démarrer le service : sudo systemctl start llama-api"
echo ""

# Désactivation de l'environnement virtuel
deactivate
print_status "Environnement virtuel désactivé" 