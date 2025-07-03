# 🤖 API Llama.cpp Locale - Optimisée pour i5 + GTX 950M

Une API locale complète utilisant llama.cpp, optimisée spécifiquement pour votre configuration matérielle (Intel i5 + NVIDIA GTX 950M + 8GB RAM). Cette solution offre une interface web moderne avec coloration syntaxique pour le code et une utilisation optimisée de la RAM et VRAM.

## 🎯 Caractéristiques

### 🚀 Performance Optimisée
- **CPU i5** : Utilisation intelligente des cœurs disponibles
- **GPU GTX 950M** : Accélération CUDA avec 20 couches GPU
- **RAM 8GB + VRAM 4GB** : Gestion hybride optimisée
- **Quantisation Q4_K_M** : Équilibre parfait vitesse/qualité

### 🌐 Interface Web Moderne
- **Design responsive** : Fonctionne sur desktop et mobile
- **Coloration syntaxique** : Support automatique pour tous les langages
- **Streaming temps réel** : Réponses en temps réel
- **Export de conversations** : Sauvegarde au format JSON
- **Monitoring matériel** : Surveillance CPU, RAM, GPU en temps réel
- **Accès réseau local** : Accessible depuis tous les appareils du réseau

### 🔧 API Complète
- **REST API** : Compatible OpenAI
- **WebSocket** : Communication bidirectionnelle
- **Streaming** : Réponses progressives
- **Documentation automatique** : Swagger UI intégré

## 📋 Prérequis

### Matériel
- **CPU** : Intel i5 (ou équivalent)
- **GPU** : NVIDIA GTX 950M (4GB VRAM)
- **RAM** : 8GB minimum
- **Stockage** : 10GB d'espace libre

### Logiciel
- **OS** : Ubuntu 20.04+ (recommandé)
- **Python** : 3.8+
- **CUDA** : 11.8+ (pour l'accélération GPU)

## 🚀 Installation Rapide

### 1. Clonage et Installation
```bash
# Cloner le projet
git clone https://github.com/scareface972/llama-api-local.git
cd llma-api

# Installation automatique (Ubuntu)
chmod +x install.sh
./install.sh
```

### 2. Téléchargement du Modèle
```bash
# Téléchargement automatique du modèle optimisé
chmod +x download_model.sh
./download_model.sh
```

### 3. Démarrage du Serveur
```bash
# Démarrage avec vérifications automatiques
chmod +x start_server.sh
./start_server.sh
```

### 4. Accès à l'Interface
- **Interface Web** : http://localhost:8000
- **Documentation API** : http://localhost:8000/docs
- **Health Check** : http://localhost:8000/health

## 🌐 Accès Réseau Local

### Configuration Automatique
L'API est configurée pour être accessible sur le réseau local avec `host: "0.0.0.0"`.

### Vérification de l'Accès Réseau
```bash
# Afficher les informations réseau
chmod +x network-info.sh
./network-info.sh
```

### Accès depuis d'Autres Appareils
1. **Connectez-vous au même réseau WiFi/LAN**
2. **Ouvrez un navigateur**
3. **Tapez l'URL** : `http://[ADRESSE_IP_SERVEUR]:8000`

### Exemples d'URLs
- **Interface Web** : `http://192.168.1.100:8000`
- **API REST** : `http://192.168.1.100:8000/v1/chat/completions`
- **Documentation** : `http://192.168.1.100:8000/docs`
- **Health Check** : `http://192.168.1.100:8000/health`

### Configuration du Firewall
```bash
# Autoriser le port 8000
sudo ufw allow 8000/tcp

# Vérifier le statut
sudo ufw status
```

### Sécurité Réseau
⚠️ **IMPORTANT** : L'API est accessible sur le réseau local
- Assurez-vous que votre réseau est sécurisé
- Changez le port si nécessaire dans config.py
- Configurez un firewall approprié
- Utilisez HTTPS en production

## 📁 Structure du Projet

```
llma-api/
├── 📄 install.sh              # Script d'installation automatique
├── 📄 uninstall.sh            # Script de désinstallation
├── 📄 download_model.sh       # Téléchargement du modèle
├── 📄 start_server.sh         # Démarrage du serveur
├── 📄 daemon-control.sh       # Contrôle du service systemd
├── 📄 network-info.sh         # Informations réseau ✨ NOUVEAU
├── 📄 requirements.txt        # Dépendances Python
├── 📄 config.py              # Configuration optimisée
├── 📄 llama_api.py           # API FastAPI principale
├── 📄 README.md              # Documentation
├── 📁 models/                # Modèles IA
│   └── llama-2-7b-chat.gguf  # Modèle principal
├── 📁 templates/             # Templates HTML
│   └── index.html            # Interface web
├── 📁 static/                # Fichiers statiques
├── 📁 logs/                  # Logs de l'application
└── 📁 llama.cpp/             # Bibliothèque llama.cpp
```

## ⚙️ Configuration Optimisée

### Paramètres Matériels
```python
HARDWARE_CONFIG = {
    "cpu_threads": 4,        # Cœurs i5 optimisés
    "gpu_layers": 20,        # Couches GPU pour GTX 950M
    "ram_gb": 8,            # RAM système
    "vram_gb": 4,           # VRAM GPU
    "batch_size": 512,      # Batch optimisé
    "context_size": 2048,   # Contexte adapté
}
```

### Optimisations Automatiques
- **Détection CPU** : Nombre de cœurs automatique
- **Gestion RAM** : Ajustement selon la mémoire disponible
- **Optimisation GPU** : Utilisation maximale de la VRAM
- **Quantisation** : Q4_K_M pour équilibre performance/mémoire

## 🌐 Utilisation de l'API

### Interface Web
1. Ouvrez http://localhost:8000 (ou l'IP du serveur)
2. Tapez votre message dans la zone de texte
3. Utilisez Ctrl+Enter pour envoyer rapidement
4. Ajustez les paramètres dans la sidebar

### API REST
```bash
# Conversation simple
curl -X POST "http://localhost:8000/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Bonjour !"}],
    "temperature": 0.8,
    "max_tokens": 2048
  }'

# Streaming
curl -X POST "http://localhost:8000/v1/chat/completions/stream" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Explique-moi Python"}],
    "stream": true
  }'
```

### WebSocket
```javascript
const ws = new WebSocket('ws://localhost:8000/ws/chat');
ws.send(JSON.stringify({
    messages: [{role: "user", content: "Hello!"}],
    temperature: 0.8
}));
```

## 🎨 Fonctionnalités de l'Interface

### Coloration Syntaxique
- **Support automatique** : Python, JavaScript, C++, etc.
- **Thème sombre** : Prism.js avec thème Tomorrow
- **Copie facile** : Bouton de copie intégré

### Paramètres Avancés
- **Température** : 0.0 - 2.0 (contrôle de la créativité)
- **Tokens max** : 256 - 4096 (longueur des réponses)
- **Prompt système** : Instructions personnalisées

### Monitoring Temps Réel
- **CPU** : Utilisation en pourcentage
- **RAM** : Mémoire système utilisée
- **Modèle** : État de chargement
- **Temps de réponse** : Latence en millisecondes

## 🔧 Dépannage

### Problèmes Courants

#### Modèle non trouvé
```bash
# Vérifiez que le modèle est téléchargé
ls -la models/
# Si absent, relancez le téléchargement
./download_model.sh
```

#### Erreur CUDA
```bash
# Vérifiez l'installation CUDA
nvidia-smi
# Réinstallez si nécessaire
sudo apt install nvidia-cuda-toolkit
```

#### Mémoire insuffisante
```bash
# Vérifiez la RAM disponible
free -h
# Fermez d'autres applications
# Ou réduisez batch_size dans config.py
```

#### Port déjà utilisé
```bash
# Changez le port dans config.py
# Ou tuez le processus existant
sudo lsof -ti:8000 | xargs kill -9
```

#### Problèmes d'accès réseau
```bash
# Vérifiez les informations réseau
./network-info.sh

# Ouvrez le port firewall
sudo ufw allow 8000/tcp

# Vérifiez le statut du service
sudo systemctl status llama-api
```

### Logs et Debug
```bash
# Consultez les logs
tail -f logs/api.log

# Mode debug
export LOG_LEVEL=DEBUG
./start_server.sh

# Logs du service systemd
sudo journalctl -u llama-api -f
```

## 📊 Performances

### Benchmarks (Configuration i5 + GTX 950M)
- **Chargement modèle** : ~30 secondes
- **Première réponse** : ~2-5 secondes
- **Réponses suivantes** : ~1-3 secondes
- **Utilisation RAM** : ~6-7GB
- **Utilisation VRAM** : ~3.5GB

### Optimisations Appliquées
- **MMAP** : Chargement mémoire optimisé
- **F16 KV Cache** : Réduction utilisation VRAM
- **Batch Processing** : Traitement par lots
- **Thread Pooling** : Utilisation CPU optimisée

## 🔒 Sécurité

### Configuration Sécurisée
- **CORS** : Configuré pour développement local
- **Rate Limiting** : 100 requêtes/minute
- **Input Validation** : Validation Pydantic
- **Error Handling** : Gestion d'erreurs robuste

### Production
```bash
# Pour la production, modifiez config.py
SECURITY_CONFIG = {
    "cors_origins": ["https://votre-domaine.com"],
    "rate_limit": 50,
    "max_tokens_per_request": 2048,
}
```

## 🤝 Contribution

### Développement Local
```bash
# Installation développement
pip install -r requirements.txt
pip install -e .

# Tests
python -m pytest tests/

# Linting
flake8 llama_api.py config.py
```

### Ajout de Modèles
1. Téléchargez le modèle GGUF
2. Placez-le dans `models/`
3. Mettez à jour `config.py`
4. Redémarrez le serveur

## 📝 Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.

## 🙏 Remerciements

- **llama.cpp** : Georgi Gerganov et la communauté
- **FastAPI** : Sebastián Ramírez
- **Hugging Face** : Modèles et infrastructure
- **TheBloke** : Modèles quantifiés

## 📞 Support

Pour toute question ou problème :
1. Consultez la section dépannage
2. Vérifiez les logs dans `logs/api.log`
3. Utilisez `./network-info.sh` pour les problèmes réseau
4. Ouvrez une issue sur GitHub

---

**🎉 Votre IA locale est prête ! Profitez de conversations intelligentes sans dépendance externe.** 
