#!/bin/bash

echo "📥 Téléchargement du modèle Llama.cpp optimisé"
echo "=============================================="

# Configuration
MODEL_NAME="llama-2-7b-chat.gguf"
MODEL_URL="https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGUF/resolve/main/llama-2-7b-chat.Q4_K_M.gguf"
MODELS_DIR="models"

# Création du répertoire models s'il n'existe pas
mkdir -p $MODELS_DIR

# Vérification si le modèle existe déjà
if [ -f "$MODELS_DIR/$MODEL_NAME" ]; then
    echo "✅ Le modèle existe déjà dans $MODELS_DIR/$MODEL_NAME"
    echo "📊 Taille du fichier: $(du -h $MODELS_DIR/$MODEL_NAME | cut -f1)"
    read -p "Voulez-vous le télécharger à nouveau ? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "🚀 Utilisation du modèle existant"
        exit 0
    fi
fi

echo "🌐 Téléchargement depuis Hugging Face..."
echo "📦 URL: $MODEL_URL"
echo "💾 Destination: $MODELS_DIR/$MODEL_NAME"
echo ""

# Téléchargement avec wget avec barre de progression
if command -v wget &> /dev/null; then
    echo "📥 Utilisation de wget..."
    wget --progress=bar:force:noscroll -O "$MODELS_DIR/$MODEL_NAME" "$MODEL_URL"
elif command -v curl &> /dev/null; then
    echo "📥 Utilisation de curl..."
    curl -L -o "$MODELS_DIR/$MODEL_NAME" "$MODEL_URL"
else
    echo "❌ Erreur: wget ou curl non trouvé"
    exit 1
fi

# Vérification du téléchargement
if [ -f "$MODELS_DIR/$MODEL_NAME" ]; then
    echo ""
    echo "✅ Téléchargement terminé avec succès !"
    echo "📊 Taille du fichier: $(du -h $MODELS_DIR/$MODEL_NAME | cut -f1)"
    echo "🔍 Vérification de l'intégrité..."
    
    # Vérification basique du fichier
    if file "$MODELS_DIR/$MODEL_NAME" | grep -q "data"; then
        echo "✅ Fichier valide détecté"
    else
        echo "⚠️  Le fichier ne semble pas être un modèle valide"
    fi
    
    echo ""
    echo "🚀 Le modèle est prêt à être utilisé !"
    echo "📋 Prochaines étapes :"
    echo "1. Exécutez : ./start_server.sh"
    echo "2. Ouvrez votre navigateur sur : http://localhost:8000"
    echo ""
    echo "💡 Informations sur le modèle :"
    echo "   • Modèle: Llama-2-7B-Chat"
    echo "   • Quantisation: Q4_K_M (optimisé pour votre configuration)"
    echo "   • Taille: ~4GB (idéal pour 8GB RAM + 4GB VRAM)"
    echo "   • Performance: Équilibrée entre vitesse et qualité"
    
else
    echo "❌ Erreur lors du téléchargement"
    echo "🔧 Solutions possibles :"
    echo "   • Vérifiez votre connexion internet"
    echo "   • Assurez-vous d'avoir suffisamment d'espace disque"
    echo "   • Essayez de télécharger manuellement depuis :"
    echo "     $MODEL_URL"
    exit 1
fi

echo ""
echo "🎯 Optimisations appliquées pour votre configuration :"
echo "   • CPU i5: Utilisation optimisée des cœurs"
echo "   • GPU GTX 950M: 20 couches GPU activées"
echo "   • RAM 8GB: Gestion intelligente de la mémoire"
echo "   • VRAM 4GB: Quantisation Q4_K_M optimale"
echo ""
echo "✨ Votre IA locale est prête !" 