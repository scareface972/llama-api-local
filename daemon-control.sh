#!/bin/bash

# Script de contrôle pour le daemon Llama API
# Usage: ./daemon-control.sh [start|stop|restart|status|logs|monitor]

SERVICE_NAME="llama-api"
SERVICE_FILE="/etc/systemd/system/llama-api.service"

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
    echo -e "${BLUE}  Llama API Daemon Control${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Vérification des privilèges sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Ce script nécessite des privilèges sudo"
        exit 1
    fi
}

# Vérification de l'existence du service
check_service() {
    if [ ! -f "$SERVICE_FILE" ]; then
        print_error "Service $SERVICE_NAME non trouvé. Exécutez d'abord ./install.sh"
        exit 1
    fi
}

# Fonction de démarrage
start_service() {
    print_status "Démarrage du service $SERVICE_NAME..."
    systemctl start $SERVICE_NAME
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        print_status "Service démarré avec succès !"
        print_status "API accessible sur : http://localhost:8000"
    else
        print_error "Échec du démarrage du service"
        systemctl status $SERVICE_NAME
        exit 1
    fi
}

# Fonction d'arrêt
stop_service() {
    print_status "Arrêt du service $SERVICE_NAME..."
    systemctl stop $SERVICE_NAME
    
    if ! systemctl is-active --quiet $SERVICE_NAME; then
        print_status "Service arrêté avec succès !"
    else
        print_error "Échec de l'arrêt du service"
        exit 1
    fi
}

# Fonction de redémarrage
restart_service() {
    print_status "Redémarrage du service $SERVICE_NAME..."
    systemctl restart $SERVICE_NAME
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        print_status "Service redémarré avec succès !"
    else
        print_error "Échec du redémarrage du service"
        systemctl status $SERVICE_NAME
        exit 1
    fi
}

# Fonction de statut
show_status() {
    print_status "Statut du service $SERVICE_NAME :"
    echo ""
    systemctl status $SERVICE_NAME --no-pager -l
    
    echo ""
    print_status "Informations système :"
    echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
    echo "Memory Usage: $(free -h | grep Mem | awk '{print $3"/"$2}')"
    
    if command -v nvidia-smi &> /dev/null; then
        echo "GPU Usage: $(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)%"
        echo "GPU Memory: $(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits | sed 's/,/ \/ /')"
    fi
}

# Fonction d'affichage des logs
show_logs() {
    print_status "Logs du service $SERVICE_NAME (Ctrl+C pour quitter) :"
    echo ""
    journalctl -u $SERVICE_NAME -f
}

# Fonction de monitoring en temps réel
monitor_service() {
    print_status "Monitoring en temps réel (Ctrl+C pour quitter) :"
    echo ""
    
    while true; do
        clear
        print_header
        echo ""
        
        # Statut du service
        if systemctl is-active --quiet $SERVICE_NAME; then
            echo -e "${GREEN}● Service: ACTIF${NC}"
        else
            echo -e "${RED}● Service: INACTIF${NC}"
        fi
        
        echo ""
        
        # Informations système
        echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
        echo "Memory Usage: $(free -h | grep Mem | awk '{print $3"/"$2}')"
        
        if command -v nvidia-smi &> /dev/null; then
            echo "GPU Usage: $(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)%"
            echo "GPU Memory: $(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits | sed 's/,/ \/ /')"
        fi
        
        echo ""
        echo "Dernières lignes de log :"
        journalctl -u $SERVICE_NAME --no-pager -n 5
        
        echo ""
        echo "Appuyez sur Ctrl+C pour quitter..."
        sleep 2
    done
}

# Fonction d'installation
install_service() {
    print_status "Installation du service $SERVICE_NAME..."
    
    # Vérification de l'existence du fichier service
    if [ ! -f "llama-api.service" ]; then
        print_error "Fichier llama-api.service non trouvé"
        exit 1
    fi
    
    # Détection de l'utilisateur actuel
    CURRENT_USER=$(whoami)
    CURRENT_GROUP=$(id -gn)
    PROJECT_PATH=$(pwd)
    
    # Mise à jour du fichier service
    sed -i "s|User=ubuntu|User=$CURRENT_USER|g" llama-api.service
    sed -i "s|Group=ubuntu|Group=$CURRENT_GROUP|g" llama-api.service
    sed -i "s|/home/ubuntu/llama-api-local|$PROJECT_PATH|g" llama-api.service
    
    # Copie et activation
    cp llama-api.service $SERVICE_FILE
    systemctl daemon-reload
    systemctl enable $SERVICE_NAME
    
    print_status "Service installé et activé avec succès !"
}

# Fonction d'aide
show_help() {
    print_header
    echo ""
    echo "Usage: $0 [COMMANDE]"
    echo ""
    echo "Commandes disponibles :"
    echo "  start     - Démarrer le service"
    echo "  stop      - Arrêter le service"
    echo "  restart   - Redémarrer le service"
    echo "  status    - Afficher le statut du service"
    echo "  logs      - Afficher les logs en temps réel"
    echo "  monitor   - Monitoring en temps réel"
    echo "  install   - Installer le service systemd"
    echo "  help      - Afficher cette aide"
    echo ""
    echo "Exemples :"
    echo "  sudo $0 start"
    echo "  sudo $0 status"
    echo "  sudo $0 logs"
    echo ""
}

# Script principal
main() {
    case "${1:-help}" in
        start)
            check_sudo
            check_service
            start_service
            ;;
        stop)
            check_sudo
            check_service
            stop_service
            ;;
        restart)
            check_sudo
            check_service
            restart_service
            ;;
        status)
            check_service
            show_status
            ;;
        logs)
            check_service
            show_logs
            ;;
        monitor)
            check_service
            monitor_service
            ;;
        install)
            check_sudo
            install_service
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Commande inconnue: $1"
            show_help
            exit 1
            ;;
    esac
}

# Exécution du script principal
main "$@" 