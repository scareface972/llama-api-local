#!/bin/bash

echo "📦 Mise à jour des dépendances Python"
echo "===================================="

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
        return 1
    fi
    return 0
}

# Vérification de l'environnement virtuel
if [ -z "$VIRTUAL_ENV" ]; then
    print_error "Environnement virtuel non activé"
    print_status "Activation de l'environnement virtuel..."
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    else
        print_error "Environnement virtuel non trouvé"
        print_status "Exécutez d'abord : ./fix_venv.sh"
        exit 1
    fi
fi

print_status "Environnement virtuel activé : $VIRTUAL_ENV"

# Mise à jour de pip
print_status "Mise à jour de pip..."
python -m pip install --upgrade pip
check_error "Échec de la mise à jour de pip"

# Installation des dépendances de base (sans conflits)
print_status "Installation des dépendances de base..."
python -m pip install --upgrade setuptools wheel
check_error "Échec de l'installation de setuptools/wheel"

# Installation séquentielle des dépendances
print_status "Installation séquentielle des dépendances..."

# 1. Numpy (base pour beaucoup d'autres packages)
print_status "1. Installation de numpy..."
python -m pip install "numpy>=1.24.0" --upgrade
check_error "Échec de l'installation de numpy"

# 2. FastAPI et Uvicorn
print_status "2. Installation de FastAPI et Uvicorn..."
python -m pip install "fastapi>=0.104.1" "uvicorn[standard]>=0.24.0" --upgrade
check_error "Échec de l'installation de FastAPI/Uvicorn"

# 3. Pydantic
print_status "3. Installation de Pydantic..."
python -m pip install "pydantic>=2.5.0" --upgrade
check_error "Échec de l'installation de Pydantic"

# 4. Autres dépendances web
print_status "4. Installation des dépendances web..."
python -m pip install "python-multipart>=0.0.6" "jinja2>=3.1.2" "aiofiles>=23.2.1" "websockets>=12.0" --upgrade
check_error "Échec de l'installation des dépendances web"

# 5. Psutil
print_status "5. Installation de psutil..."
python -m pip install "psutil>=5.9.6" --upgrade
check_error "Échec de l'installation de psutil"

# 6. PyTorch (séparé car peut être long)
print_status "6. Installation de PyTorch..."
python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 --upgrade
check_error "Échec de l'installation de PyTorch"

# 7. Transformers et dépendances
print_status "7. Installation de Transformers..."
python -m pip install "transformers>=4.36.0" "sentencepiece>=0.1.99" "accelerate>=0.25.0" --upgrade
check_error "Échec de l'installation de Transformers"

# 8. Llama-cpp-python (avec le script dédié)
print_status "8. Installation de llama-cpp-python..."
./install_llama_cpp.sh
check_error "Échec de l'installation de llama-cpp-python"

# Vérification finale
print_status "Vérification des installations..."
python -c "
import sys
packages = ['fastapi', 'uvicorn', 'pydantic', 'numpy', 'torch', 'transformers', 'llama_cpp']
missing = []
for pkg in packages:
    try:
        __import__(pkg)
        print(f'✅ {pkg} installé')
    except ImportError:
        missing.append(pkg)
        print(f'❌ {pkg} manquant')

if missing:
    print(f'\\n❌ Packages manquants: {missing}')
    sys.exit(1)
else:
    print('\\n✅ Toutes les dépendances sont installées')
"

if [ $? -eq 0 ]; then
    print_status "✅ Mise à jour des dépendances terminée avec succès !"
    echo ""
    print_status "Prochaines étapes :"
    echo "1. Télécharger le modèle : ./download_model.sh"
    echo "2. Tester le serveur : ./start_server.sh"
    echo "3. Ou démarrer le service : sudo systemctl restart llama-api"
else
    print_error "❌ Certaines dépendances n'ont pas pu être installées"
    print_status "Essayez d'installer manuellement les packages manquants"
fi 