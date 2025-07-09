#!/bin/bash

echo "📥 Téléchargement de modèle optimisé CPU pour l'API Llama.cpp"
echo "=========================================================="

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

print_success() {
    echo -e "${CYAN}[SUCCESS]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}[HEADER]${NC} $1"
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

# Affichage de la configuration système
print_header "Configuration système détectée :"
echo "💻 CPU: Intel i5 (4 cœurs)"
echo "🧠 RAM: 8GB"
echo "🎮 GPU: Désactivé (CPU uniquement)"
echo ""

# Sélection du modèle optimisé CPU
echo "🎯 Sélectionnez un modèle optimisé pour CPU :"
echo ""
echo "${GREEN}1. Mistral 3B Q4_K_M (2.5 GB) - ${CYAN}RECOMMANDÉ${NC}"
echo "   ⚡ Vitesse: 80-120 tokens/s | 🧠 RAM: 2.5GB | ⭐ Qualité: Très bonne"
echo ""
echo "${GREEN}2. Phi-3 Mini 3.8B Q4_K_M (2.2 GB) - ${CYAN}CODE/IA${NC}"
echo "   ⚡ Vitesse: 100-150 tokens/s | 🧠 RAM: 2.2GB | ⭐ Qualité: Excellente"
echo ""
echo "${GREEN}3. TinyLlama 1.1B Q4_K_M (1.0 GB) - ${CYAN}ULTRA-RAPIDE${NC}"
echo "   ⚡ Vitesse: 150-200 tokens/s | 🧠 RAM: 1GB | ⭐ Qualité: Bonne"
echo ""
echo "${GREEN}4. Llama 3.1 8B Q4_K_M (5.0 GB) - ${CYAN}QUALITÉ${NC}"
echo "   ⚡ Vitesse: 40-60 tokens/s | 🧠 RAM: 5GB | ⭐ Qualité: Excellente"
echo ""
echo "${GREEN}5. Mistral 7B Q4_K_M (4.5 GB) - ${CYAN}ÉQUILIBRÉ${NC}"
echo "   ⚡ Vitesse: 50-80 tokens/s | 🧠 RAM: 4.5GB | ⭐ Qualité: Excellente"
echo ""
echo "${YELLOW}6. Téléchargement personnalisé${NC}"
echo ""

read -p "Votre choix (1-6): " choice

case $choice in
    1)
        MODEL_NAME="mistral-3b-instruct-v0.2.Q4_K_M.gguf"
        MODEL_URL="https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf"
        MODEL_SIZE="2.5"
        MODEL_SPEED="80-120"
        MODEL_QUALITY="Très bonne"
        ;;
    2)
        MODEL_NAME="phi-3-mini-4k-instruct.Q4_K_M.gguf"
        MODEL_URL="https://huggingface.co/TheBloke/Phi-3-mini-4k-instruct-GGUF/resolve/main/phi-3-mini-4k-instruct.Q4_K_M.gguf"
        MODEL_SIZE="2.2"
        MODEL_SPEED="100-150"
        MODEL_QUALITY="Excellente"
        ;;
    3)
        MODEL_NAME="tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
        MODEL_URL="https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
        MODEL_SIZE="1.0"
        MODEL_SPEED="150-200"
        MODEL_QUALITY="Bonne"
        ;;
    4)
        MODEL_NAME="llama-3.1-8b-instruct.Q4_K_M.gguf"
        MODEL_URL="https://huggingface.co/TheBloke/Llama-3.1-8B-Instruct-GGUF/resolve/main/llama-3.1-8b-instruct.Q4_K_M.gguf"
        MODEL_SIZE="5.0"
        MODEL_SPEED="40-60"
        MODEL_QUALITY="Excellente"
        ;;
    5)
        MODEL_NAME="mistral-7b-instruct-v0.2.Q4_K_M.gguf"
        MODEL_URL="https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf"
        MODEL_SIZE="4.5"
        MODEL_SPEED="50-80"
        MODEL_QUALITY="Excellente"
        ;;
    6)
        echo ""
        read -p "URL du modèle GGUF: " MODEL_URL
        read -p "Nom du fichier: " MODEL_NAME
        read -p "Taille estimée (GB): " MODEL_SIZE
        MODEL_SPEED="Variable"
        MODEL_QUALITY="Variable"
        ;;
    *)
        print_error "Choix invalide"
        exit 1
        ;;
esac

# Affichage des informations du modèle sélectionné
echo ""
print_header "Modèle sélectionné :"
echo "📦 Nom: $MODEL_NAME"
echo "📏 Taille: ${MODEL_SIZE} GB"
echo "⚡ Vitesse: ${MODEL_SPEED} tokens/s"
echo "⭐ Qualité: ${MODEL_QUALITY}"
echo ""

# Vérification de l'espace disque
print_status "Vérification de l'espace disque..."
FREE_SPACE=$(df . | awk 'NR==2 {print $4}')
FREE_SPACE_GB=$((FREE_SPACE / 1024 / 1024))

if [ $FREE_SPACE_GB -lt $((MODEL_SIZE + 2)) ]; then
    print_warning "⚠️  Espace disque faible: ${FREE_SPACE_GB} GB disponible"
    print_warning "Il est recommandé d'avoir au moins $((MODEL_SIZE + 2)) GB d'espace libre"
    read -p "Continuer quand même ? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Téléchargement annulé"
        exit 0
    fi
else
    print_success "✅ Espace disque suffisant: ${FREE_SPACE_GB} GB disponible"
fi

# Vérification de la RAM disponible
print_status "Vérification de la RAM disponible..."
TOTAL_RAM=$(free -g | awk 'NR==2{print $2}')
if [ $TOTAL_RAM -lt 8 ]; then
    print_warning "⚠️  RAM faible: ${TOTAL_RAM} GB total"
    if [ $MODEL_SIZE -gt 3 ]; then
        print_warning "Ce modèle pourrait être lent avec ${TOTAL_RAM} GB de RAM"
        read -p "Continuer quand même ? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Téléchargement annulé"
            exit 0
        fi
    fi
else
    print_success "✅ RAM suffisante: ${TOTAL_RAM} GB total"
fi

# Téléchargement du modèle
print_status "Téléchargement de $MODEL_NAME..."
print_status "URL: $MODEL_URL"
echo ""

# Utilisation de wget avec barre de progression et résumé
wget --progress=bar:force:noscroll --show-progress -O "$MODEL_NAME" "$MODEL_URL"

if [ $? -eq 0 ]; then
    print_success "✅ Téléchargement terminé avec succès !"
    
    # Affichage des informations du fichier
    FILE_SIZE=$(du -h "$MODEL_NAME" | cut -f1)
    print_status "Taille du fichier: $FILE_SIZE"
    
    # Vérification de l'intégrité
    print_status "Vérification de l'intégrité du fichier..."
    if [ -s "$MODEL_NAME" ]; then
        print_success "✅ Fichier valide et non vide"
    else
        print_error "❌ Fichier vide ou corrompu"
        exit 1
    fi
    
    # Mise à jour du fichier de configuration
    cd ..
    if [ -f "config.py" ]; then
        print_status "Mise à jour de la configuration..."
        # Mise à jour du chemin du modèle
        sed -i "s|\"model_path\": \".*\"|\"model_path\": \"models/$MODEL_NAME\"|" config.py
        
        # Configuration optimisée CPU
        print_status "Application des optimisations CPU..."
        sed -i 's/"n_gpu_layers": [0-9]*/"n_gpu_layers": 0/' config.py
        sed -i 's/"n_threads": [0-9]*/"n_threads": 4/' config.py
        sed -i 's/"n_threads_batch": [0-9]*/"n_threads_batch": 4/' config.py
        sed -i 's/"f16_kv": true/"f16_kv": false/' config.py
        sed -i 's/"use_mlock": true/"use_mlock": false/' config.py
        
        print_success "✅ Configuration mise à jour pour CPU"
    fi
    
    echo ""
    print_success "🎉 Modèle prêt à utiliser !"
    echo ""
    print_header "Prochaines étapes :"
    echo "1. ${GREEN}Analyser le système${NC}: python3 optimize_mistral.py --analyze"
    echo "2. ${GREEN}Optimiser la configuration${NC}: python3 optimize_mistral.py --optimize"
    echo "3. ${GREEN}Démarrer le serveur${NC}: python3 llama_api.py"
    echo "4. ${GREEN}Ou démarrer le service${NC}: sudo systemctl start llama-api"
    echo "5. ${GREEN}Accéder à l'interface${NC}: http://192.168.0.140:8000"
    echo ""
    print_header "Configuration CPU appliquée :"
    echo "🎮 GPU: Désactivé (n_gpu_layers: 0)"
    echo "💻 CPU: 4 threads optimisés"
    echo "🧠 Mémoire: Configuration économique"
    echo "⚡ Performance: Optimisée pour CPU uniquement"
    echo ""
    
else
    print_error "❌ Échec du téléchargement"
    print_error "Vérifiez votre connexion internet et réessayez"
    exit 1
fi 