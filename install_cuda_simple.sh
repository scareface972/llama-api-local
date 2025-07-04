#!/bin/bash

echo "🔧 Installation CUDA simple et compatible"
echo "========================================"

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

# Vérification de l'utilisateur
if [ "$EUID" -eq 0 ]; then
    print_error "Ne pas exécuter ce script en tant que root"
    print_status "Utilisez un utilisateur normal avec sudo"
    exit 1
fi

print_status "Vérification de l'environnement..."

# Vérification de CUDA
print_status "Vérification de CUDA..."
if command -v nvidia-smi &> /dev/null; then
    print_status "✅ GPU NVIDIA détecté"
    nvidia-smi --query-gpu=name,driver_version --format=csv,noheader,nounits
else
    print_warning "⚠️  GPU NVIDIA non détecté"
    print_status "Ce script est destiné aux systèmes avec GPU NVIDIA"
    exit 1
fi

# Nettoyage des packages cassés
print_status "ÉTAPE 1: Nettoyage des packages cassés..."
sudo apt autoremove -y
sudo apt autoclean
sudo apt --fix-broken install -y
check_error "Échec de la réparation des packages"

# Installation des dépendances de base
print_status "ÉTAPE 2: Installation des dépendances de base..."
sudo apt install -y \
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    pkg-config \
    wget
check_error "Échec de l'installation des dépendances"

# Suppression des installations CUDA existantes
print_status "ÉTAPE 3: Suppression des installations CUDA existantes..."
sudo apt remove --purge cuda* nvidia-cuda* -y 2>/dev/null || true
sudo apt autoremove -y
sudo apt autoclean

# Nettoyage des fichiers CUDA
print_status "ÉTAPE 4: Nettoyage des fichiers CUDA..."
sudo rm -rf /usr/local/cuda* 2>/dev/null || true
sudo rm -rf /usr/local/nvidia* 2>/dev/null || true
sudo rm -f /etc/apt/sources.list.d/cuda* 2>/dev/null || true
sudo rm -f /etc/apt/sources.list.d/nvidia* 2>/dev/null || true

# Installation simple de CUDA
print_status "ÉTAPE 5: Installation simple de CUDA..."

# Téléchargement du keyring
print_status "Téléchargement de CUDA keyring..."
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
check_error "Échec du téléchargement de CUDA keyring"

# Installation du keyring
print_status "Installation de CUDA keyring..."
sudo dpkg -i cuda-keyring_1.0-1_all.deb
check_error "Échec de l'installation de CUDA keyring"

# Mise à jour des dépôts
print_status "Mise à jour des dépôts..."
sudo apt-get update
check_error "Échec de la mise à jour des dépôts"

# Installation minimale de CUDA
print_status "Installation minimale de CUDA..."
sudo apt-get install -y cuda-runtime-12-0 --no-install-recommends

if [ $? -ne 0 ]; then
    print_warning "Installation de runtime échouée, tentative d'installation des bibliothèques..."
    sudo apt-get install -y cuda-libraries-12-0 --no-install-recommends
    check_error "Échec de l'installation des bibliothèques CUDA"
fi

# Configuration des variables d'environnement
print_status "ÉTAPE 6: Configuration des variables d'environnement..."

# Recherche du répertoire CUDA
CUDA_PATH=""
for path in /usr/local/cuda-12.0 /usr/local/cuda-11.8 /usr/local/cuda; do
    if [ -d "$path" ]; then
        CUDA_PATH="$path"
        break
    fi
done

if [ -n "$CUDA_PATH" ]; then
    print_status "CUDA trouvé dans : $CUDA_PATH"
    
    # Ajout des variables d'environnement
    if ! grep -q "export PATH=$CUDA_PATH/bin" ~/.bashrc; then
        echo "export PATH=$CUDA_PATH/bin:\$PATH" >> ~/.bashrc
    fi
    
    if ! grep -q "export LD_LIBRARY_PATH=$CUDA_PATH/lib64" ~/.bashrc; then
        echo "export LD_LIBRARY_PATH=$CUDA_PATH/lib64:\$LD_LIBRARY_PATH" >> ~/.bashrc
    fi
    
    # Application immédiate
    export PATH="$CUDA_PATH/bin:$PATH"
    export LD_LIBRARY_PATH="$CUDA_PATH/lib64:$LD_LIBRARY_PATH"
    
    print_status "✅ Variables d'environnement configurées"
else
    print_warning "⚠️  Répertoire CUDA non trouvé"
    print_status "Configuration manuelle nécessaire"
fi

# Vérification de l'installation
print_status "ÉTAPE 7: Vérification de l'installation..."

# Test de nvcc
if command -v nvcc &> /dev/null; then
    print_status "✅ nvcc trouvé : $(nvcc --version | head -1)"
else
    print_warning "⚠️  nvcc non trouvé (normal pour une installation minimale)"
fi

# Test de CUDA avec PyTorch
print_status "Test de CUDA avec PyTorch..."
if python3 -c "import torch; print('CUDA disponible:', torch.cuda.is_available())" 2>/dev/null; then
    print_status "✅ PyTorch CUDA fonctionnel"
else
    print_warning "⚠️  PyTorch CUDA non testé (PyTorch pas encore installé)"
fi

print_status "✅ Installation CUDA simple terminée !"
echo ""
print_status "Prochaines étapes :"
echo "1. Redémarrez votre terminal ou exécutez : source ~/.bashrc"
echo "2. Testez CUDA : nvcc --version (si installé)"
echo "3. Relancez l'installation : ./install.sh"
echo "" 