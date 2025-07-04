#!/bin/bash
# Script de déploiement sur serveur distant

echo "🚀 Déploiement des optimisations Mistral sur le serveur..."

# Configuration
SERVER_USER="root"  # À modifier selon votre configuration
SERVER_IP="your-server-ip"  # À modifier
SERVER_PATH="/opt/llama-api"  # Chemin sur le serveur

echo "📋 Configuration actuelle:"
echo "   • Serveur: $SERVER_USER@$SERVER_IP"
echo "   • Chemin: $SERVER_PATH"
echo ""

# Vérification de la connexion SSH
echo "🔍 Test de connexion SSH..."
if ssh -o ConnectTimeout=10 $SERVER_USER@$SERVER_IP "echo 'Connexion SSH OK'" 2>/dev/null; then
    echo "✅ Connexion SSH réussie"
else
    echo "❌ Impossible de se connecter au serveur"
    echo "   Vérifiez:"
    echo "   • L'adresse IP du serveur"
    echo "   • Les clés SSH"
    echo "   • La connexion réseau"
    exit 1
fi

# Création du dossier de logs sur le serveur
echo "📁 Création des dossiers sur le serveur..."
ssh $SERVER_USER@$SERVER_IP "mkdir -p $SERVER_PATH/logs"

# Copie des fichiers d'optimisation
echo "📤 Copie des fichiers d'optimisation..."
scp optimize_mistral.py $SERVER_USER@$SERVER_IP:$SERVER_PATH/
scp diagnose_performance.py $SERVER_USER@$SERVER_IP:$SERVER_PATH/
scp logs.py $SERVER_USER@$SERVER_IP:$SERVER_PATH/

# Copie de l'API mise à jour
echo "📤 Copie de l'API optimisée..."
scp llama_api.py $SERVER_USER@$SERVER_IP:$SERVER_PATH/

# Rendre les scripts exécutables
echo "🔧 Configuration des permissions..."
ssh $SERVER_USER@$SERVER_IP "chmod +x $SERVER_PATH/optimize_mistral.py $SERVER_PATH/diagnose_performance.py"

echo "✅ Déploiement terminé !"
echo ""
echo "🔗 Pour exécuter sur le serveur:"
echo "   ssh $SERVER_USER@$SERVER_IP"
echo "   cd $SERVER_PATH"
echo "   python3 optimize_mistral.py --analyze"
echo "   python3 optimize_mistral.py --all" 