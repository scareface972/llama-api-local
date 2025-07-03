#!/bin/bash

echo "🌐 Informations Réseau - API Llama.cpp"
echo "====================================="

# Couleurs pour l'affichage
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction d'affichage avec couleur
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[NETWORK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Détection de l'adresse IP locale
print_header "Adresses IP disponibles :"
echo ""

# Récupération de toutes les interfaces réseau
INTERFACES=$(ip addr show | grep -E "^[0-9]+:" | awk '{print $2}' | sed 's/://')

for interface in $INTERFACES; do
    # Ignorer les interfaces loopback et docker
    if [[ "$interface" != "lo" && "$interface" != "docker"* ]]; then
        IP=$(ip addr show $interface 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
        if [ ! -z "$IP" ]; then
            echo "Interface: $interface"
            echo "  IP: $IP"
            echo "  URL API: http://$IP:8000"
            echo "  URL Interface Web: http://$IP:8000"
            echo "  URL Documentation: http://$IP:8000/docs"
            echo ""
        fi
    fi
done

# Vérification du statut du service
print_header "Statut du service :"
if systemctl is-active --quiet llama-api; then
    print_info "✅ Service llama-api est ACTIF"
    print_info "🌐 API accessible sur le réseau local"
else
    print_warning "⚠️  Service llama-api n'est pas actif"
    print_info "Démarrez le service avec : sudo systemctl start llama-api"
fi

# Vérification du port
print_header "Vérification du port 8000 :"
if netstat -tlnp 2>/dev/null | grep -q ":8000 "; then
    print_info "✅ Port 8000 est ouvert et en écoute"
    netstat -tlnp 2>/dev/null | grep ":8000 "
else
    print_warning "⚠️  Port 8000 n'est pas en écoute"
fi

# Vérification du firewall
print_header "Configuration du firewall :"
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "8000/tcp"; then
        print_info "✅ Port 8000 autorisé dans UFW"
    else
        print_warning "⚠️  Port 8000 non autorisé dans UFW"
        print_info "Autorisez avec : sudo ufw allow 8000/tcp"
    fi
else
    print_warning "UFW non installé ou non configuré"
fi

# Instructions d'accès
echo ""
print_header "Instructions d'accès :"
echo ""
echo "📱 Depuis un appareil sur le même réseau :"
echo "   1. Connectez-vous au même réseau WiFi/LAN"
echo "   2. Ouvrez un navigateur"
echo "   3. Tapez une des URLs ci-dessus"
echo ""
echo "🔧 Exemple d'utilisation :"
echo "   • Interface Web: http://192.168.1.100:8000"
echo "   • API REST: http://192.168.1.100:8000/v1/chat/completions"
echo "   • Documentation: http://192.168.1.100:8000/docs"
echo "   • Health Check: http://192.168.1.100:8000/health"
echo ""

# Test de connectivité
print_header "Test de connectivité :"
echo "Testez la connectivité avec :"
echo "curl http://$(hostname -I | awk '{print $1}'):8000/health"
echo ""

# Informations de sécurité
print_header "Sécurité :"
echo "⚠️  IMPORTANT : L'API est accessible sur le réseau local"
echo "   • Assurez-vous que votre réseau est sécurisé"
echo "   • Changez le port si nécessaire dans config.py"
echo "   • Configurez un firewall approprié"
echo "   • Utilisez HTTPS en production"
echo ""

# Commandes utiles
print_header "Commandes utiles :"
echo "• Démarrer le service : sudo systemctl start llama-api"
echo "• Arrêter le service : sudo systemctl stop llama-api"
echo "• Voir les logs : sudo journalctl -u llama-api -f"
echo "• Statut du service : sudo systemctl status llama-api"
echo "• Ouvrir le port firewall : sudo ufw allow 8000/tcp"
echo "• Voir les processus sur le port 8000 : sudo lsof -i :8000"
echo ""

print_info "🌐 Votre API Llama.cpp est prête pour l'accès réseau local !" 