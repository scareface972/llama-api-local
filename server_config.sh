#!/bin/bash
# Configuration du serveur distant

echo "⚙️ Configuration du serveur distant..."

# Demander les informations de connexion
read -p "👤 Nom d'utilisateur SSH (défaut: root): " SERVER_USER
SERVER_USER=${SERVER_USER:-root}

read -p "🌐 Adresse IP du serveur: " SERVER_IP
if [ -z "$SERVER_IP" ]; then
    echo "❌ Adresse IP requise"
    exit 1
fi

read -p "📁 Chemin sur le serveur (défaut: /opt/llama-api): " SERVER_PATH
SERVER_PATH=${SERVER_PATH:-/opt/llama-api}

# Créer le fichier de configuration
cat > server_config.env << EOF
# Configuration du serveur distant
SERVER_USER=$SERVER_USER
SERVER_IP=$SERVER_IP
SERVER_PATH=$SERVER_PATH
EOF

echo "✅ Configuration sauvegardée dans server_config.env"
echo ""
echo "📋 Configuration actuelle:"
echo "   • Utilisateur: $SERVER_USER"
echo "   • Serveur: $SERVER_IP"
echo "   • Chemin: $SERVER_PATH"
echo ""

# Tester la connexion
echo "🔍 Test de connexion SSH..."
if ssh -o ConnectTimeout=10 $SERVER_USER@$SERVER_IP "echo 'Connexion SSH OK'" 2>/dev/null; then
    echo "✅ Connexion SSH réussie"
    
    # Vérifier si le dossier existe
    if ssh $SERVER_USER@$SERVER_IP "[ -d $SERVER_PATH ]"; then
        echo "✅ Dossier $SERVER_PATH existe"
    else
        echo "⚠️ Dossier $SERVER_PATH n'existe pas"
        read -p "Créer le dossier ? (y/n): " CREATE_DIR
        if [[ $CREATE_DIR =~ ^[Yy]$ ]]; then
            ssh $SERVER_USER@$SERVER_IP "mkdir -p $SERVER_PATH"
            echo "✅ Dossier créé"
        fi
    fi
else
    echo "❌ Impossible de se connecter au serveur"
    echo "   Vérifiez:"
    echo "   • L'adresse IP du serveur"
    echo "   • Les clés SSH"
    echo "   • La connexion réseau"
    exit 1
fi

echo ""
echo "🚀 Prêt pour l'optimisation !"
echo "   Utilisez: ./remote_optimize.sh analyze" 