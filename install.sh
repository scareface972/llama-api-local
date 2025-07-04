#!/bin/bash

echo "🚀 Installation complète de l'API Llama.cpp optimisée pour Ubuntu"
echo "================================================================"

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

# Vérification de l'utilisateur
if [ "$EUID" -eq 0 ]; then
    print_error "Ne pas exécuter ce script en tant que root"
    print_status "Utilisez un utilisateur normal avec sudo"
    exit 1
fi

print_status "Utilisateur: $(whoami)"
print_status "Répertoire: $(pwd)"

# ============================================================================
# ÉTAPE 1: MISE À JOUR DU SYSTÈME
# ============================================================================
print_status "ÉTAPE 1: Mise à jour du système..."
sudo apt update && sudo apt upgrade -y
check_error "Échec de la mise à jour du système"

# ============================================================================
# ÉTAPE 2: INSTALLATION DES DÉPENDANCES SYSTÈME
# ============================================================================
print_status "ÉTAPE 2: Installation des dépendances système..."

# Dépendances système essentielles (sans packages obsolètes)
sudo apt install -y \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    python3 \
    python3-pip \
    python3-venv \
    libopenblas-dev \
    liblapack-dev \
    libatlas-base-dev \
    gfortran \
    libssl-dev \
    libffi-dev \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    libxft-dev \
    pkg-config \
    libhdf5-dev \
    libhdf5-serial-dev \
    libgtk-3-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    libtiff-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libgtk2.0-dev \
    libtiff5-dev

check_error "Échec de l'installation des dépendances système"

# ============================================================================
# ÉTAPE 3: INSTALLATION DE CUDA (si GPU NVIDIA détecté)
# ============================================================================
print_status "ÉTAPE 3: Configuration CUDA..."

if command -v nvidia-smi &> /dev/null; then
    print_status "✅ GPU NVIDIA détecté, installation de CUDA..."
    
    # Installation des dépendances de base pour CUDA
    print_status "Installation des dépendances de base..."
    sudo apt install -y \
        build-essential \
        gcc \
        g++ \
        make \
        cmake \
        pkg-config
    check_error "Échec de l'installation des dépendances de base"
    
    # Nettoyage des packages cassés
    print_status "Nettoyage des packages cassés..."
    sudo apt autoremove -y
    sudo apt autoclean
    sudo apt --fix-broken install -y
    check_error "Échec de la réparation des packages"
    
    # Installation de CUDA Toolkit
    print_status "Téléchargement de CUDA keyring..."
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
    check_error "Échec du téléchargement de CUDA keyring"
    
    print_status "Installation de CUDA keyring..."
    sudo dpkg -i cuda-keyring_1.0-1_all.deb
    check_error "Échec de l'installation de CUDA keyring"
    
    print_status "Mise à jour des dépôts..."
    sudo apt-get update
    check_error "Échec de la mise à jour des dépôts"
    
    # Installation sélective de CUDA (sans nsight-systems qui pose problème)
    print_status "Installation de CUDA toolkit (sans outils de développement)..."
    sudo apt-get install -y cuda-runtime-12-0 cuda-libraries-12-0 --no-install-recommends
    if [ $? -ne 0 ]; then
        print_warning "Installation de base échouée, tentative d'installation minimale..."
        sudo apt-get install -y cuda-compiler-12-0 cuda-libraries-12-0
        check_error "Échec de l'installation minimale de CUDA"
    fi
    
    # Configuration des variables d'environnement CUDA
    print_status "Configuration des variables d'environnement CUDA..."
    if [ -d "/usr/local/cuda-12.0" ]; then
        echo 'export PATH=/usr/local/cuda-12.0/bin:$PATH' >> ~/.bashrc
        echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.0/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
        source ~/.bashrc
        print_status "✅ CUDA installé et configuré"
    else
        print_warning "⚠️  CUDA installé mais répertoire non trouvé, configuration manuelle nécessaire"
    fi
else
    print_warning "⚠️  GPU NVIDIA non détecté, installation sans CUDA"
fi

# ============================================================================
# ÉTAPE 4: INSTALLATION DE LLAMA.CPP
# ============================================================================
print_status "ÉTAPE 4: Installation de llama.cpp..."

# Suppression de l'ancienne installation si elle existe
if [ -d "llama.cpp" ]; then
    print_warning "llama.cpp existe déjà, suppression..."
    rm -rf llama.cpp
fi

# Clonage de llama.cpp
git clone https://github.com/ggerganov/llama.cpp.git
check_error "Échec du clonage de llama.cpp"

cd llama.cpp

# Compilation optimisée pour votre configuration
print_status "Compilation optimisée pour i5 + GTX 950M..."
make clean

# Compilation avec optimisations CUDA si disponible
if command -v nvidia-smi &> /dev/null; then
    make LLAMA_CUBLAS=1 LLAMA_AVX=1 LLAMA_AVX2=1 LLAMA_F16C=1 LLAMA_FMA=1 LLAMA_BLAS=1 LLAMA_OPENBLAS=1 -j$(nproc)
else
    make LLAMA_AVX=1 LLAMA_AVX2=1 LLAMA_F16C=1 LLAMA_FMA=1 LLAMA_BLAS=1 LLAMA_OPENBLAS=1 -j$(nproc)
fi

check_error "Échec de la compilation de llama.cpp"

# Retour au répertoire principal
cd ..

# ============================================================================
# ÉTAPE 5: CRÉATION DE L'ENVIRONNEMENT VIRTUEL PYTHON
# ============================================================================
print_status "ÉTAPE 5: Configuration de l'environnement Python..."

# Suppression de l'ancien environnement si il existe
if [ -d "venv" ]; then
    print_warning "Environnement virtuel existe déjà, suppression..."
    rm -rf venv
fi

# Création d'un nouvel environnement virtuel
python3 -m venv venv
check_error "Échec de la création de l'environnement virtuel"

# Activation de l'environnement virtuel
source venv/bin/activate
check_error "Échec de l'activation de l'environnement virtuel"

# Vérification que l'environnement est activé
if [ -z "$VIRTUAL_ENV" ]; then
    print_error "L'environnement virtuel n'est pas activé"
    exit 1
fi

print_status "Environnement virtuel activé : $VIRTUAL_ENV"

# ============================================================================
# ÉTAPE 6: INSTALLATION DES DÉPENDANCES PYTHON
# ============================================================================
print_status "ÉTAPE 6: Installation des dépendances Python..."

# Mise à jour de pip
python -m pip install --upgrade pip
check_error "Échec de la mise à jour de pip"

# Installation des dépendances de base
python -m pip install --upgrade setuptools wheel
check_error "Échec de l'installation de setuptools/wheel"

# Installation séquentielle des dépendances (pour éviter les conflits)
print_status "Installation séquentielle des dépendances..."

# 1. Numpy (base pour beaucoup d'autres packages)
print_status "1. Installation de numpy..."
python -m pip install "numpy>=1.24.0"
check_error "Échec de l'installation de numpy"

# 2. FastAPI et Uvicorn
print_status "2. Installation de FastAPI et Uvicorn..."
python -m pip install "fastapi>=0.104.1" "uvicorn[standard]>=0.24.0"
check_error "Échec de l'installation de FastAPI/Uvicorn"

# 3. Pydantic
print_status "3. Installation de Pydantic..."
python -m pip install "pydantic>=2.5.0"
check_error "Échec de l'installation de Pydantic"

# 4. Autres dépendances web
print_status "4. Installation des dépendances web..."
python -m pip install "python-multipart>=0.0.6" "jinja2>=3.1.2" "aiofiles>=23.2.1" "websockets>=12.0"
check_error "Échec de l'installation des dépendances web"

# 5. Psutil
print_status "5. Installation de psutil..."
python -m pip install "psutil>=5.9.6"
check_error "Échec de l'installation de psutil"

# 6. PyTorch (séparé car peut être long)
print_status "6. Installation de PyTorch..."
if command -v nvidia-smi &> /dev/null; then
    python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
else
    python -m pip install torch torchvision torchaudio
fi
check_error "Échec de l'installation de PyTorch"

# 7. Transformers et dépendances
print_status "7. Installation de Transformers..."
python -m pip install "transformers>=4.36.0" "sentencepiece>=0.1.99" "accelerate>=0.25.0"
check_error "Échec de l'installation de Transformers"

# 8. Llama-cpp-python (avec fallback automatique)
print_status "8. Installation de llama-cpp-python..."
if command -v nvidia-smi &> /dev/null; then
    # Tentative d'installation depuis le dépôt personnalisé
    if python -m pip install llama-cpp-python --index-url https://jllllll.github.io/llama-cpp-python-cuBLAS-wheels/AVX2/cu118 2>/dev/null; then
        print_status "✅ llama-cpp-python installé depuis le dépôt personnalisé"
    else
        print_warning "Échec du dépôt personnalisé, compilation CUDA..."
        export CMAKE_ARGS="-DLLAMA_CUBLAS=on"
        export FORCE_CMAKE=1
        python -m pip install llama-cpp-python --no-cache-dir
        check_error "Échec de l'installation de llama-cpp-python avec CUDA"
    fi
else
    # Installation sans CUDA
    python -m pip install llama-cpp-python --no-cache-dir
    check_error "Échec de l'installation de llama-cpp-python"
fi

# ============================================================================
# ÉTAPE 7: CRÉATION DE LA STRUCTURE DU PROJET
# ============================================================================
print_status "ÉTAPE 7: Création de la structure du projet..."
mkdir -p models
mkdir -p logs
mkdir -p static
mkdir -p templates
mkdir -p config

# ============================================================================
# ÉTAPE 8: CONFIGURATION DES PERMISSIONS
# ============================================================================
print_status "ÉTAPE 8: Configuration des permissions..."
chmod +x *.sh
chmod +x llama_api.py
chmod +x config.py

# ============================================================================
# ÉTAPE 9: CONFIGURATION DU DAEMON SYSTEMD
# ============================================================================
print_status "ÉTAPE 9: Configuration du daemon systemd..."

# Vérification de l'existence du fichier service
if [ ! -f "llama-api.service" ]; then
    print_error "Fichier llama-api.service non trouvé"
    exit 1
fi

# Détection de l'utilisateur et du chemin
CURRENT_USER=$(whoami)
CURRENT_GROUP=$(id -gn)
PROJECT_PATH=$(pwd)

print_status "Utilisateur: $CURRENT_USER"
print_status "Groupe: $CURRENT_GROUP"
print_status "Chemin du projet: $PROJECT_PATH"

# Mise à jour du fichier service avec les bonnes informations
sed -i "s|User=ubuntu|User=$CURRENT_USER|g" llama-api.service
sed -i "s|Group=ubuntu|Group=$CURRENT_GROUP|g" llama-api.service
sed -i "s|/home/ubuntu/llama-api-local|$PROJECT_PATH|g" llama-api.service

# Copie du fichier service vers systemd
sudo cp llama-api.service /etc/systemd/system/
check_error "Échec de la copie du fichier service"

# Rechargement de systemd
sudo systemctl daemon-reload
check_error "Échec du rechargement de systemd"

# Activation du service
sudo systemctl enable llama-api.service
check_error "Échec de l'activation du service"

print_status "✅ Service systemd configuré et activé"

# ============================================================================
# ÉTAPE 10: CONFIGURATION DU FIREWALL
# ============================================================================
print_status "ÉTAPE 10: Configuration du firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw allow 8000/tcp
    print_status "✅ Port 8000 ouvert dans le firewall"
else
    print_warning "UFW non installé, configurez manuellement le port 8000"
fi

# ============================================================================
# ÉTAPE 11: INSTALLATION DES OUTILS DE SURVEILLANCE
# ============================================================================
print_status "ÉTAPE 11: Installation des outils de surveillance..."
sudo apt install -y htop iotop nvtop

# ============================================================================
# ÉTAPE 12: VÉRIFICATION FINALE
# ============================================================================
print_status "ÉTAPE 12: Vérification finale..."

# Vérification de l'environnement virtuel
if [ -d "venv" ] && [ -f "venv/bin/activate" ]; then
    print_status "✅ Environnement virtuel créé"
else
    print_error "❌ Environnement virtuel manquant"
    exit 1
fi

# Vérification de llama.cpp
if [ -d "llama.cpp" ] && [ -f "llama.cpp/main" ]; then
    print_status "✅ llama.cpp compilé"
else
    print_error "❌ llama.cpp manquant ou non compilé"
    exit 1
fi

# Vérification des dépendances Python
source venv/bin/activate
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
    print_status "✅ Installation terminée avec succès !"
else
    print_error "❌ Certaines dépendances sont manquantes"
    exit 1
fi

# ============================================================================
# FINALISATION
# ============================================================================
echo ""
echo "🎉 INSTALLATION TERMINÉE AVEC SUCCÈS !"
echo "======================================"
echo ""
echo "📋 Prochaines étapes :"
echo "1. Télécharger le modèle : ./download_model.sh"
echo "2. Tester le serveur : ./start_server.sh"
echo "3. Ou démarrer le service : sudo systemctl start llama-api"
echo "4. Vérifier le statut : sudo systemctl status llama-api"
echo "5. Voir les logs : sudo journalctl -u llama-api -f"
echo "6. Accès réseau : ./network-info.sh"
echo ""
echo "🌐 URLs d'accès :"
echo "   • Interface Web : http://localhost:8000"
echo "   • Documentation API : http://localhost:8000/docs"
echo "   • Health Check : http://localhost:8000/health"
echo ""
echo "🔧 Commandes utiles :"
echo "   • Démarrer : sudo systemctl start llama-api"
echo "   • Arrêter : sudo systemctl stop llama-api"
echo "   • Redémarrer : sudo systemctl restart llama-api"
echo "   • Statut : sudo systemctl status llama-api"
echo "   • Logs : sudo journalctl -u llama-api -f"
echo ""
echo "📊 Surveillance :"
echo "   • Monitoring : ./monitor.sh"
echo "   • Diagnostic : ./diagnose_env.sh"
echo "   • Réparation : ./fix_venv.sh"
echo ""
echo "🎯 Votre API Llama.cpp est prête !" 