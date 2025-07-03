#!/bin/bash

echo "🚀 Démarrage de l'API Llama.cpp optimisée"
echo "========================================="

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

# Vérification de l'environnement virtuel
print_status "Vérification de l'environnement virtuel..."
if [ ! -d "venv" ]; then
    print_error "Environnement virtuel non trouvé"
    print_error "Exécutez d'abord : ./install.sh"
    exit 1
fi

if [ ! -f "venv/bin/activate" ]; then
    print_error "Script d'activation de l'environnement virtuel non trouvé"
    print_error "Exécutez d'abord : ./install.sh"
    exit 1
fi

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

# Vérification des dépendances
print_status "Vérification des dépendances..."
if ! python -c "import fastapi, uvicorn, llama_cpp" 2>/dev/null; then
    print_error "Dépendances manquantes"
    print_error "Exécutez : pip install -r requirements.txt"
    print_error "Ou relancez : ./install.sh"
    exit 1
fi

print_status "✅ Dépendances vérifiées"

# Vérification du modèle
print_status "Vérification du modèle..."
if [ ! -f "models/llama-2-7b-chat.gguf" ]; then
    print_warning "Modèle non trouvé"
    print_status "Exécutez d'abord : ./download_model.sh"
    print_status "Ou téléchargez manuellement le modèle dans le dossier models/"
    read -p "Voulez-vous continuer sans modèle ? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Démarrage annulé"
        exit 1
    fi
else
    print_status "✅ Modèle trouvé"
fi

# Vérification de llama.cpp
if [ ! -d "llama.cpp" ]; then
    print_error "llama.cpp non trouvé"
    print_error "Exécutez d'abord : ./install.sh"
    exit 1
fi

# Vérification de la compilation
if [ ! -f "llama.cpp/main" ]; then
    print_warning "llama.cpp non compilé, compilation en cours..."
    cd llama.cpp
    make clean
    make LLAMA_CUBLAS=1 LLAMA_AVX=1 LLAMA_AVX2=1 LLAMA_F16C=1 LLAMA_FMA=1 LLAMA_BLAS=1 LLAMA_OPENBLAS=1 -j$(nproc)
    check_error "Échec de la compilation de llama.cpp"
    cd ..
    print_status "✅ llama.cpp compilé"
else
    print_status "✅ llama.cpp déjà compilé"
fi

# Vérification de CUDA
print_status "Vérification de CUDA..."
if command -v nvidia-smi &> /dev/null; then
    print_status "✅ NVIDIA GPU détecté"
    nvidia-smi --query-gpu=name,memory.total,memory.free --format=csv,noheader,nounits
else
    print_warning "⚠️  NVIDIA GPU non détecté, utilisation CPU uniquement"
fi

# Vérification de la mémoire
print_status "Vérification de la mémoire..."
TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
AVAILABLE_RAM=$(free -g | awk '/^Mem:/{print $7}')
echo "📊 RAM totale: ${TOTAL_RAM}GB, Disponible: ${AVAILABLE_RAM}GB"

if [ $AVAILABLE_RAM -lt 4 ]; then
    print_warning "Attention: Moins de 4GB de RAM disponible"
    print_warning "Fermez d'autres applications pour de meilleures performances"
fi

# Création des répertoires nécessaires
print_status "Création des répertoires..."
mkdir -p logs
mkdir -p static
mkdir -p templates

# Vérification des permissions
print_status "Vérification des permissions..."
chmod +x llama_api.py
chmod +x config.py

# Affichage de la configuration
echo ""
print_status "Configuration détectée :"
echo "   • Modèle: llama-2-7b-chat.gguf"
echo "   • API: FastAPI + Uvicorn"
echo "   • Interface: Web moderne avec coloration syntaxique"
echo "   • Optimisations: i5 + GTX 950M + 8GB RAM"
echo "   • Accès réseau: 0.0.0.0:8000"
echo ""

# Démarrage du serveur
print_status "Démarrage du serveur..."
echo "📡 L'API sera accessible sur :"
echo "   • Local: http://localhost:8000"
echo "   • Réseau: http://[VOTRE_IP]:8000"
echo "📖 Documentation API : http://localhost:8000/docs"
echo "🔧 Interface web : http://localhost:8000"
echo "🏥 Health Check : http://localhost:8000/health"
echo ""
echo "🛑 Pour arrêter le serveur, appuyez sur Ctrl+C"
echo ""

# Démarrage avec uvicorn
python llama_api.py 