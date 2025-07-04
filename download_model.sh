#!/bin/bash

echo "📥 Téléchargement de modèle pour l'API Llama.cpp"
echo "=============================================="

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

# Vérification du répertoire models
if [ ! -d "models" ]; then
    print_status "Création du répertoire models..."
    mkdir -p models
fi

cd models

# Sélection du modèle
echo ""
echo "🎯 Sélectionnez un modèle à télécharger :"
echo "1. Llama-2-7B-Chat (4.37 GB) - Recommandé pour débuter"
echo "2. Llama-2-13B-Chat (7.87 GB) - Plus performant, plus lent"
echo "3. Llama-2-7B (4.37 GB) - Modèle de base (sans chat)"
echo "4. CodeLlama-7B-Instruct (4.37 GB) - Spécialisé code"
echo "5. Mistral-7B-Instruct (4.37 GB) - Très performant"
echo "6. Téléchargement personnalisé"
echo ""

read -p "Votre choix (1-6): " choice

case $choice in
    1)
        MODEL_NAME="llama-2-7b-chat.gguf"
        MODEL_URL="https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGUF/resolve/main/llama-2-7b-chat.Q4_K_M.gguf"
        ;;
    2)
        MODEL_NAME="llama-2-13b-chat.gguf"
        MODEL_URL="https://huggingface.co/TheBloke/Llama-2-13B-Chat-GGUF/resolve/main/llama-2-13b-chat.Q4_K_M.gguf"
        ;;
    3)
        MODEL_NAME="llama-2-7b.gguf"
        MODEL_URL="https://huggingface.co/TheBloke/Llama-2-7B-GGUF/resolve/main/llama-2-7b.Q4_K_M.gguf"
        ;;
    4)
        MODEL_NAME="codellama-7b-instruct.gguf"
        MODEL_URL="https://huggingface.co/TheBloke/CodeLlama-7B-Instruct-GGUF/resolve/main/codellama-7b-instruct.Q4_K_M.gguf"
        ;;
    5)
        MODEL_NAME="mistral-7b-instruct.gguf"
        MODEL_URL="https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf"
        ;;
    6)
        echo ""
        read -p "URL du modèle GGUF: " MODEL_URL
        read -p "Nom du fichier: " MODEL_NAME
        ;;
    *)
        print_error "Choix invalide"
        exit 1
        ;;
esac

# Vérification de l'espace disque
print_status "Vérification de l'espace disque..."
FREE_SPACE=$(df . | awk 'NR==2 {print $4}')
FREE_SPACE_GB=$((FREE_SPACE / 1024 / 1024))

if [ $FREE_SPACE_GB -lt 10 ]; then
    print_warning "⚠️  Espace disque faible: ${FREE_SPACE_GB} GB disponible"
    print_warning "Il est recommandé d'avoir au moins 10 GB d'espace libre"
    read -p "Continuer quand même ? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Téléchargement annulé"
        exit 0
    fi
else
    print_status "✅ Espace disque suffisant: ${FREE_SPACE_GB} GB disponible"
fi

# Téléchargement du modèle
print_status "Téléchargement de $MODEL_NAME..."
print_status "URL: $MODEL_URL"
echo ""

# Utilisation de wget avec barre de progression
wget --progress=bar:force:noscroll -O "$MODEL_NAME" "$MODEL_URL"

if [ $? -eq 0 ]; then
    print_status "✅ Téléchargement terminé avec succès !"
    
    # Affichage des informations du fichier
    FILE_SIZE=$(du -h "$MODEL_NAME" | cut -f1)
    print_status "Taille du fichier: $FILE_SIZE"
    
    # Mise à jour du fichier de configuration
    cd ..
    if [ -f "config.py" ]; then
        print_status "Mise à jour de la configuration..."
        sed -i "s/DEFAULT_MODEL = \".*\"/DEFAULT_MODEL = \"$MODEL_NAME\"/" config.py
        print_status "✅ Configuration mise à jour"
    fi
    
    echo ""
    print_status "🎉 Modèle prêt à utiliser !"
    echo ""
    print_status "Prochaines étapes :"
    echo "1. Démarrer le serveur : ./start_server.sh"
    echo "2. Ou démarrer le service : sudo systemctl start llama-api"
    echo "3. Accéder à l'interface : http://localhost:8000"
    echo ""
    
else
    print_error "❌ Échec du téléchargement"
    exit 1
fi 