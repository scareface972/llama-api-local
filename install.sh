#!/bin/bash

echo "🚀 Installation de l'API Llama.cpp optimisée pour Ubuntu"
echo "=================================================="

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

# Mise à jour du système
print_status "Mise à jour du système..."
sudo apt update && sudo apt upgrade -y
check_error "Échec de la mise à jour du système"

# Installation des dépendances système
print_status "Installation des dépendances système..."
sudo apt install -y \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    python3 \
    python3-pip \
    python3-venv \
    nvidia-cuda-toolkit \
    nvidia-driver-535 \
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
    libhdf5-103 \
    libqtgui4 \
    libqtwebkit4 \
    libqt4-test \
    python3-pyqt5 \
    libgtk-3-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libatlas-base-dev \
    gfortran \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libgtk2.0-dev \
    libtiff5-dev \
    libjasper-dev \
    libdc1394-22-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libatlas-base-dev \
    gfortran \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libgtk2.0-dev \
    libtiff5-dev \
    libjasper-dev \
    libdc1394-22-dev

check_error "Échec de l'installation des dépendances système"

# Installation de CUDA et cuDNN
print_status "Configuration CUDA pour GPU NVIDIA..."
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
check_error "Échec du téléchargement de CUDA keyring"

sudo dpkg -i cuda-keyring_1.0-1_all.deb
check_error "Échec de l'installation de CUDA keyring"

sudo apt-get update
sudo apt-get -y install cuda-toolkit-12-0
check_error "Échec de l'installation de CUDA toolkit"

# Configuration des variables d'environnement CUDA
print_status "Configuration des variables d'environnement CUDA..."
echo 'export PATH=/usr/local/cuda-12.0/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.0/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc

# Installation de llama.cpp
print_status "Installation de llama.cpp..."
if [ -d "llama.cpp" ]; then
    print_warning "llama.cpp existe déjà, suppression..."
    rm -rf llama.cpp
fi

git clone https://github.com/ggerganov/llama.cpp.git
check_error "Échec du clonage de llama.cpp"

cd llama.cpp

# Compilation optimisée pour votre configuration
print_status "Compilation optimisée pour i5 + GTX 950M..."
make clean
make LLAMA_CUBLAS=1 LLAMA_AVX=1 LLAMA_AVX2=1 LLAMA_F16C=1 LLAMA_FMA=1 LLAMA_BLAS=1 LLAMA_OPENBLAS=1 -j$(nproc)
check_error "Échec de la compilation de llama.cpp"

# Retour au répertoire principal
cd ..

# Création de l'environnement virtuel Python
print_status "Configuration de l'environnement Python..."
if [ -d "venv" ]; then
    print_warning "Environnement virtuel existe déjà, suppression..."
    rm -rf venv
fi

python3 -m venv venv
check_error "Échec de la création de l'environnement virtuel"

# Activation de l'environnement virtuel
print_status "Activation de l'environnement virtuel..."
source venv/bin/activate
check_error "Échec de l'activation de l'environnement virtuel"

# Vérification que l'environnement est activé
if [ -z "$VIRTUAL_ENV" ]; then
    print_error "L'environnement virtuel n'est pas activé"
    exit 1
fi

print_status "Environnement virtuel activé : $VIRTUAL_ENV"

# Installation des dépendances Python
print_status "Installation des dépendances Python..."
pip install --upgrade pip
check_error "Échec de la mise à jour de pip"

# Vérification de l'existence du fichier requirements.txt
if [ ! -f "requirements.txt" ]; then
    print_error "Fichier requirements.txt non trouvé"
    exit 1
fi

pip install -r requirements.txt
check_error "Échec de l'installation des dépendances Python"

# Installation de PyTorch avec support CUDA
print_status "Installation de PyTorch avec support CUDA..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
check_error "Échec de l'installation de PyTorch"

# Installation de llama-cpp-python avec support CUDA
print_status "Installation de llama-cpp-python avec support CUDA..."
pip install llama-cpp-python --force-reinstall --index-url https://jllllll.github.io/llama-cpp-python-cuBLAS-wheels/AVX2/cu118
check_error "Échec de l'installation de llama-cpp-python"

# Création des répertoires nécessaires
print_status "Création de la structure du projet..."
mkdir -p models
mkdir -p logs
mkdir -p static
mkdir -p templates
mkdir -p config

# Configuration des permissions
print_status "Configuration des permissions..."
chmod +x start_server.sh
chmod +x download_model.sh
chmod +x daemon-control.sh
chmod +x network-info.sh
chmod +x uninstall.sh

# Configuration du daemon systemd
print_status "Configuration du daemon systemd..."

# Vérification de l'existence du fichier service
if [ ! -f "llama-api.service" ]; then
    print_error "Fichier llama-api.service non trouvé"
    exit 1
fi

# Détection de l'utilisateur actuel
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

print_status "Service systemd configuré et activé"
echo "📋 Commandes de gestion du service :"
echo "   • Démarrage : sudo systemctl start llama-api"
echo "   • Arrêt : sudo systemctl stop llama-api"
echo "   • Redémarrage : sudo systemctl restart llama-api"
echo "   • Statut : sudo systemctl status llama-api"
echo "   • Logs : sudo journalctl -u llama-api -f"

# Configuration du firewall (optionnel)
print_status "Configuration du firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw allow 8000/tcp
    print_status "Port 8000 ouvert dans le firewall"
else
    print_warning "UFW non installé, configurez manuellement le port 8000"
fi

# Configuration de la surveillance système
print_status "Configuration de la surveillance système..."
sudo apt install -y htop iotop nvtop

# Création d'un script de monitoring
cat > monitor.sh << 'EOF'
#!/bin/bash
echo "=== Monitoring Llama API ==="
echo "CPU Usage:"
top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
echo "Memory Usage:"
free -h | grep Mem | awk '{print $3"/"$2}'
echo "GPU Usage:"
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits
else
    echo "NVIDIA GPU non détecté"
fi
echo "Service Status:"
sudo systemctl is-active llama-api
EOF

chmod +x monitor.sh

# Vérification finale
print_status "Vérification de l'installation..."

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
if python -c "import fastapi, uvicorn, llama_cpp" 2>/dev/null; then
    print_status "✅ Dépendances Python installées"
else
    print_error "❌ Dépendances Python manquantes"
    exit 1
fi

print_status "✅ Installation terminée avec succès !"
echo "=================================================="
echo "📋 Prochaines étapes :"
echo "1. Exécutez : ./download_model.sh"
echo "2. Démarrez le service : sudo systemctl start llama-api"
echo "3. Vérifiez le statut : sudo systemctl status llama-api"
echo "4. Ouvrez votre navigateur sur : http://localhost:8000"
echo "5. Surveillez les performances : ./monitor.sh"
echo "6. Vérifiez l'accès réseau : ./network-info.sh"
echo "==================================================" 