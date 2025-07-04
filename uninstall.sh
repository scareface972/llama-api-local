#!/bin/bash

echo "🧹 Désinstallation complète de l'API Llama.cpp"
echo "============================================="

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
    print_status "Utilisez un utilisateur normal avec sudo"
    exit 1
fi

print_status "Début de la désinstallation..."

# ============================================================================
# ÉTAPE 1: ARRÊT ET SUPPRESSION DU SERVICE SYSTEMD
# ============================================================================
print_status "ÉTAPE 1: Arrêt et suppression du service systemd..."

# Arrêt du service s'il est en cours d'exécution
if systemctl is-active --quiet llama-api; then
    print_status "Arrêt du service llama-api..."
    sudo systemctl stop llama-api
fi

# Désactivation du service
if systemctl is-enabled --quiet llama-api; then
    print_status "Désactivation du service llama-api..."
    sudo systemctl disable llama-api
fi

# Suppression du fichier service
if [ -f "/etc/systemd/system/llama-api.service" ]; then
    print_status "Suppression du fichier service..."
    sudo rm -f /etc/systemd/system/llama-api.service
    sudo systemctl daemon-reload
fi

# ============================================================================
# ÉTAPE 2: SUPPRESSION DES PROCESSUS EN COURS
# ============================================================================
print_status "ÉTAPE 2: Suppression des processus en cours..."

# Arrêt des processus Python liés à l'API
pkill -f "llama_api.py" 2>/dev/null || true
pkill -f "uvicorn" 2>/dev/null || true

# ============================================================================
# ÉTAPE 3: SUPPRESSION DE L'ENVIRONNEMENT VIRTUEL
# ============================================================================
print_status "ÉTAPE 3: Suppression de l'environnement virtuel..."

if [ -d "venv" ]; then
    print_status "Suppression de l'environnement virtuel..."
    rm -rf venv
fi

# ============================================================================
# ÉTAPE 4: SUPPRESSION DE LLAMA.CPP
# ============================================================================
print_status "ÉTAPE 4: Suppression de llama.cpp..."

if [ -d "llama.cpp" ]; then
    print_status "Suppression de llama.cpp..."
    rm -rf llama.cpp
fi

# ============================================================================
# ÉTAPE 5: SUPPRESSION DES MODÈLES ET DONNÉES
# ============================================================================
print_status "ÉTAPE 5: Suppression des modèles et données..."

# Suppression des modèles téléchargés
if [ -d "models" ]; then
    print_status "Suppression des modèles..."
    rm -rf models
fi

# Suppression des logs
if [ -d "logs" ]; then
    print_status "Suppression des logs..."
    rm -rf logs
fi

# ============================================================================
# ÉTAPE 6: SUPPRESSION DES FICHIERS TEMPORAIRES
# ============================================================================
print_status "ÉTAPE 6: Suppression des fichiers temporaires..."

# Suppression des fichiers CUDA téléchargés
rm -f cuda-keyring_*.deb 2>/dev/null || true
rm -f cuda-repo-*.deb 2>/dev/null || true
rm -f cuda-ubuntu*.pin 2>/dev/null || true

# Suppression des fichiers de cache Python
find . -name "*.pyc" -delete 2>/dev/null || true
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# ============================================================================
# ÉTAPE 7: SUPPRESSION DES DÉPÔTS CUDA
# ============================================================================
print_status "ÉTAPE 7: Nettoyage des dépôts CUDA..."

# Suppression des dépôts CUDA ajoutés
sudo rm -f /etc/apt/sources.list.d/cuda* 2>/dev/null || true
sudo rm -f /etc/apt/sources.list.d/nvidia* 2>/dev/null || true
sudo rm -f /etc/apt/preferences.d/cuda* 2>/dev/null || true

# Mise à jour des dépôts
sudo apt update 2>/dev/null || true

# ============================================================================
# ÉTAPE 8: SUPPRESSION DES VARIABLES D'ENVIRONNEMENT
# ============================================================================
print_status "ÉTAPE 8: Nettoyage des variables d'environnement..."

# Suppression des variables CUDA du .bashrc
if [ -f ~/.bashrc ]; then
    print_status "Suppression des variables CUDA du .bashrc..."
    sed -i '/export PATH.*cuda/d' ~/.bashrc
    sed -i '/export LD_LIBRARY_PATH.*cuda/d' ~/.bashrc
fi

# ============================================================================
# ÉTAPE 9: SUPPRESSION DES PACKAGES OPTIONNELS
# ============================================================================
print_status "ÉTAPE 9: Nettoyage des packages optionnels..."

# Demande à l'utilisateur s'il veut supprimer les packages CUDA
read -p "Voulez-vous supprimer les packages CUDA installés ? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Suppression des packages CUDA..."
    sudo apt remove --purge cuda* nvidia-cuda* -y 2>/dev/null || true
    sudo apt autoremove -y
fi

# ============================================================================
# ÉTAPE 10: SUPPRESSION DES FICHIERS DE CONFIGURATION
# ============================================================================
print_status "ÉTAPE 10: Suppression des fichiers de configuration..."

# Suppression des fichiers de configuration
rm -f config.py 2>/dev/null || true
rm -f llama_api.py 2>/dev/null || true
rm -f requirements.txt 2>/dev/null || true

# ============================================================================
# FINALISATION
# ============================================================================
print_status "✅ Désinstallation terminée !"
echo ""
print_status "Le projet a été complètement nettoyé."
print_status "Vous pouvez maintenant relancer l'installation avec :"
echo "   ./install_clean.sh"
echo ""
print_status "Ou supprimer complètement le répertoire avec :"
echo "   cd .. && rm -rf llama-api-local"
echo "" 