#!/bin/bash

echo "🗑️  Désinstallation de l'API Llama.cpp"
echo "====================================="

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

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Désinstallation Llama API${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_header

# Confirmation de l'utilisateur
echo ""
echo "⚠️  ATTENTION : Cette action va supprimer :"
echo "   • Le service systemd llama-api"
echo "   • L'environnement virtuel Python"
echo "   • Les modèles téléchargés"
echo "   • Les logs de l'application"
echo "   • Les fichiers de configuration"
echo ""
read -p "Êtes-vous sûr de vouloir continuer ? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Désinstallation annulée"
    exit 0
fi

# 1. Arrêt et suppression du service systemd
print_status "Arrêt du service systemd..."
if systemctl is-active --quiet llama-api; then
    sudo systemctl stop llama-api
    print_status "Service arrêté"
else
    print_warning "Service déjà arrêté"
fi

print_status "Désactivation du service..."
sudo systemctl disable llama-api 2>/dev/null || true

print_status "Suppression du fichier service..."
sudo rm -f /etc/systemd/system/llama-api.service

print_status "Rechargement de systemd..."
sudo systemctl daemon-reload

# 2. Suppression des fichiers du projet
print_status "Suppression des fichiers du projet..."

# Sauvegarde des modèles si demandé
if [ -d "models" ] && [ "$(ls -A models 2>/dev/null)" ]; then
    echo ""
    read -p "Voulez-vous sauvegarder les modèles avant suppression ? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        BACKUP_DIR="llama_models_backup_$(date +%Y%m%d_%H%M%S)"
        print_status "Sauvegarde des modèles dans $BACKUP_DIR..."
        mkdir -p "$BACKUP_DIR"
        cp -r models/* "$BACKUP_DIR/" 2>/dev/null || true
        print_status "Modèles sauvegardés dans $BACKUP_DIR"
    fi
fi

# Suppression des répertoires et fichiers
print_status "Suppression de l'environnement virtuel..."
rm -rf venv/ 2>/dev/null || true

print_status "Suppression des modèles..."
rm -rf models/ 2>/dev/null || true

print_status "Suppression des logs..."
rm -rf logs/ 2>/dev/null || true

print_status "Suppression des fichiers de cache Python..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyc" -delete 2>/dev/null || true
find . -name "*.pyo" -delete 2>/dev/null || true

print_status "Suppression de llama.cpp..."
rm -rf llama.cpp/ 2>/dev/null || true

# 3. Suppression des dépendances système (optionnel)
echo ""
read -p "Voulez-vous supprimer les dépendances système installées ? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Suppression des dépendances système..."
    
    # Liste des packages à supprimer
    PACKAGES_TO_REMOVE=(
        "build-essential"
        "cmake"
        "libopenblas-dev"
        "liblapack-dev"
        "libatlas-base-dev"
        "gfortran"
        "libssl-dev"
        "libffi-dev"
        "libjpeg-dev"
        "libpng-dev"
        "libfreetype6-dev"
        "libxft-dev"
        "pkg-config"
        "libhdf5-dev"
        "libhdf5-serial-dev"
        "libhdf5-103"
        "libqtgui4"
        "libqtwebkit4"
        "libqt4-test"
        "python3-pyqt5"
        "libgtk-3-dev"
        "libavcodec-dev"
        "libavformat-dev"
        "libswscale-dev"
        "libv4l-dev"
        "libxvidcore-dev"
        "libx264-dev"
        "libtiff-dev"
        "libgstreamer1.0-dev"
        "libgstreamer-plugins-base1.0-dev"
        "libgtk2.0-dev"
        "libtiff5-dev"
        "libjasper-dev"
        "libdc1394-22-dev"
        "htop"
        "iotop"
        "nvtop"
    )
    
    for package in "${PACKAGES_TO_REMOVE[@]}"; do
        if dpkg -l | grep -q "^ii  $package "; then
            print_status "Suppression de $package..."
            sudo apt remove --purge -y "$package" 2>/dev/null || true
        fi
    done
    
    # Nettoyage des packages orphelins
    print_status "Nettoyage des packages orphelins..."
    sudo apt autoremove -y
    sudo apt autoclean
else
    print_warning "Dépendances système conservées"
fi

# 4. Suppression de CUDA (optionnel)
echo ""
read -p "Voulez-vous supprimer CUDA et les drivers NVIDIA ? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Suppression de CUDA..."
    sudo apt remove --purge -y nvidia-cuda-toolkit nvidia-driver-535 2>/dev/null || true
    sudo apt autoremove -y
    print_warning "Redémarrage recommandé après suppression des drivers NVIDIA"
else
    print_warning "CUDA et drivers NVIDIA conservés"
fi

# 5. Nettoyage des variables d'environnement
print_status "Nettoyage des variables d'environnement..."
if [ -f ~/.bashrc ]; then
    # Suppression des lignes CUDA du .bashrc
    sed -i '/export PATH=\/usr\/local\/cuda/d' ~/.bashrc
    sed -i '/export LD_LIBRARY_PATH=\/usr\/local\/cuda/d' ~/.bashrc
    print_status "Variables d'environnement CUDA supprimées"
fi

# 6. Suppression des fichiers temporaires
print_status "Nettoyage des fichiers temporaires..."
rm -f cuda-keyring_*.deb 2>/dev/null || true
rm -f monitor.sh 2>/dev/null || true

# 7. Nettoyage du firewall
print_status "Nettoyage du firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw delete allow 8000/tcp 2>/dev/null || true
    print_status "Règle firewall supprimée"
fi

# 8. Vérification finale
print_status "Vérification de la désinstallation..."

# Vérification du service
if ! systemctl list-unit-files | grep -q "llama-api"; then
    print_status "✅ Service systemd supprimé"
else
    print_warning "⚠️  Service systemd encore présent"
fi

# Vérification des fichiers
if [ ! -d "venv" ] && [ ! -d "models" ] && [ ! -d "llama.cpp" ]; then
    print_status "✅ Fichiers du projet supprimés"
else
    print_warning "⚠️  Certains fichiers peuvent encore être présents"
fi

# 9. Résumé final
echo ""
print_header
echo ""
print_status "Désinstallation terminée !"
echo ""
echo "📋 Résumé des actions effectuées :"
echo "   ✅ Service systemd arrêté et supprimé"
echo "   ✅ Environnement virtuel Python supprimé"
echo "   ✅ Modèles IA supprimés"
echo "   ✅ Logs supprimés"
echo "   ✅ Fichiers de cache nettoyés"
echo "   ✅ Variables d'environnement nettoyées"
echo "   ✅ Règles firewall supprimées"
echo ""
echo "💡 Recommandations :"
echo "   • Redémarrez votre système si vous avez supprimé CUDA"
echo "   • Vérifiez que les ports ne sont plus utilisés : sudo lsof -i :8000"
echo "   • Consultez les logs système : sudo journalctl -f"
echo ""
echo "🔄 Pour réinstaller :"
echo "   • Clonez à nouveau le dépôt"
echo "   • Exécutez : ./install.sh"
echo ""

# 10. Option de suppression complète du répertoire
echo ""
read -p "Voulez-vous supprimer complètement ce répertoire ? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Suppression du répertoire $(pwd)..."
    cd ..
    rm -rf "llma api"
    print_status "Répertoire supprimé"
    echo ""
    print_status "Désinstallation complète terminée !"
else
    print_status "Répertoire conservé"
    echo ""
    print_status "Vous pouvez supprimer manuellement le répertoire si nécessaire"
fi

echo ""
print_status "Merci d'avoir utilisé l'API Llama.cpp ! 👋" 