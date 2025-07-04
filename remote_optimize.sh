#!/bin/bash
# Script d'optimisation à distance

echo "🚀 Optimisation Mistral sur serveur distant..."

# Configuration
SERVER_USER="scare"  # À modifier
SERVER_IP="192.168.0.140"  # À modifier
SERVER_PATH="/home/scare/llama-api-local"  # Chemin sur le serveur

# Fonction d'aide
show_help() {
    echo "Usage: $0 [COMMANDE]"
    echo ""
    echo "Commandes disponibles:"
    echo "  analyze     - Analyser le système"
    echo "  optimize    - Créer une configuration optimisée"
    echo "  download    - Télécharger le modèle recommandé"
    echo "  all         - Exécuter toutes les optimisations"
    echo "  diagnose    - Diagnostic complet de performance"
    echo "  logs        - Voir les logs de performance"
    echo "  restart     - Redémarrer le serveur"
    echo "  status      - Vérifier l'état du serveur"
    echo ""
    echo "Exemples:"
    echo "  $0 analyze"
    echo "  $0 all"
    echo "  $0 diagnose"
}

# Vérification des arguments
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

COMMAND=$1

case $COMMAND in
    "analyze")
        echo "🔍 Analyse du système sur le serveur..."
        ssh $SERVER_USER@$SERVER_IP "cd $SERVER_PATH && python3 optimize_mistral.py --analyze"
        ;;
    
    "optimize")
        echo "⚙️ Création de la configuration optimisée..."
        ssh $SERVER_USER@$SERVER_IP "cd $SERVER_PATH && python3 optimize_mistral.py --optimize"
        ;;
    
    "download")
        echo "📥 Téléchargement du modèle..."
        ssh $SERVER_USER@$SERVER_IP "cd $SERVER_PATH && python3 optimize_mistral.py --download"
        ;;
    
    "all")
        echo "🚀 Exécution de toutes les optimisations..."
        ssh $SERVER_USER@$SERVER_IP "cd $SERVER_PATH && python3 optimize_mistral.py --all"
        ;;
    
    "diagnose")
        echo "🔍 Diagnostic complet de performance..."
        ssh $SERVER_USER@$SERVER_IP "cd $SERVER_PATH && python3 diagnose_performance.py"
        ;;
    
    "logs")
        echo "📋 Affichage des logs de performance..."
        ssh $SERVER_USER@$SERVER_IP "cd $SERVER_PATH && tail -20 logs/performance.log"
        ;;
    
    "restart")
        echo "🔄 Redémarrage du serveur..."
        ssh $SERVER_USER@$SERVER_IP "cd $SERVER_PATH && sudo systemctl restart llama-api"
        echo "⏳ Attente du redémarrage..."
        sleep 5
        ssh $SERVER_USER@$SERVER_IP "cd $SERVER_PATH && sudo systemctl status llama-api"
        ;;
    
    "status")
        echo "📊 État du serveur..."
        ssh $SERVER_USER@$SERVER_IP "cd $SERVER_PATH && sudo systemctl status llama-api"
        ;;
    
    *)
        echo "❌ Commande inconnue: $COMMAND"
        show_help
        exit 1
        ;;
esac

echo "✅ Commande terminée" 