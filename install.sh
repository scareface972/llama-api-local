#!/bin/bash

echo "🚀 Installation de l'API Llama.cpp optimisée pour Ubuntu"
echo "=================================================="

# Mise à jour du système
echo "📦 Mise à jour du système..."
sudo apt update && sudo apt upgrade -y

# Installation des dépendances système
echo "🔧 Installation des dépendances système..."
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

# Installation de CUDA et cuDNN
echo "🎮 Configuration CUDA pour GPU NVIDIA..."
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
sudo dpkg -i cuda-keyring_1.0-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-toolkit-12-0

# Configuration des variables d'environnement CUDA
echo 'export PATH=/usr/local/cuda-12.0/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.0/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc

# Installation de llama.cpp
echo "🤖 Installation de llama.cpp..."
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp

# Compilation optimisée pour votre configuration
echo "⚙️ Compilation optimisée pour i5 + GTX 950M..."
make clean
make LLAMA_CUBLAS=1 LLAMA_AVX=1 LLAMA_AVX2=1 LLAMA_F16C=1 LLAMA_FMA=1 LLAMA_BLAS=1 LLAMA_OPENBLAS=1 -j$(nproc)

# Retour au répertoire principal
cd ..

# Création de l'environnement virtuel Python
echo "🐍 Configuration de l'environnement Python..."
python3 -m venv venv
source venv/bin/activate

# Installation des dépendances Python
echo "📚 Installation des dépendances Python..."
pip install --upgrade pip
pip install -r requirements.txt

# Installation de PyTorch avec support CUDA
echo "🔥 Installation de PyTorch avec support CUDA..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Création des répertoires nécessaires
echo "📁 Création de la structure du projet..."
mkdir -p models
mkdir -p logs
mkdir -p static
mkdir -p templates
mkdir -p config

# Configuration des permissions
chmod +x start_server.sh
chmod +x download_model.sh

echo "✅ Installation terminée !"
echo "=================================================="
echo "📋 Prochaines étapes :"
echo "1. Exécutez : ./download_model.sh"
echo "2. Exécutez : ./start_server.sh"
echo "3. Ouvrez votre navigateur sur : http://localhost:8000"
echo "==================================================" 