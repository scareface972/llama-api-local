# 🤖 API Llama.cpp - Installation Propre

Une API REST complète pour l'inference de modèles de langage avec llama.cpp, optimisée pour Ubuntu et facile à installer.

## 🎯 Caractéristiques

- **API REST** avec FastAPI
- **Interface web moderne** avec chat en temps réel
- **Support multi-modèles** (Llama-2, CodeLlama, Mistral, etc.)
- **Optimisations CPU** pour performances maximales
- **Service systemd** pour démarrage automatique
- **Interface réseau** accessible depuis d'autres appareils
- **Monitoring système** intégré

## 🚀 Installation Rapide

### 1. Désinstallation (si nécessaire)
```bash
# Si vous avez une installation précédente
./uninstall.sh
```

### 2. Installation propre
```bash
# Installation complète
./install_clean.sh
```

### 3. Téléchargement du modèle
```bash
# Téléchargement interactif d'un modèle
./download_model.sh
```

### 4. Démarrage du serveur
```bash
# Démarrage manuel
./start_server.sh

# Ou démarrage en service
sudo systemctl start llama-api
```

## 📋 Prérequis

- **OS** : Ubuntu 20.04+ (testé sur Ubuntu 24.04)
- **RAM** : 8GB minimum (16GB recommandé)
- **Espace disque** : 10GB minimum
- **CPU** : x86_64 avec support AVX2
- **Réseau** : Connexion internet pour télécharger les modèles

## 🔧 Scripts Disponibles

| Script | Description |
|--------|-------------|
| `install_clean.sh` | Installation complète et propre |
| `uninstall.sh` | Désinstallation complète |
| `download_model.sh` | Téléchargement interactif de modèles |
| `start_server.sh` | Démarrage du serveur |
| `network-info.sh` | Informations réseau |

## 🌐 Accès

Une fois le serveur démarré :

- **Interface Web** : http://localhost:8000
- **Documentation API** : http://localhost:8000/docs
- **Health Check** : http://localhost:8000/health
- **Accès réseau** : http://[VOTRE_IP]:8000

## 📦 Modèles Supportés

Le script `download_model.sh` propose plusieurs modèles :

1. **Llama-2-7B-Chat** (4.37 GB) - Recommandé pour débuter
2. **Llama-2-13B-Chat** (7.87 GB) - Plus performant, plus lent
3. **Llama-2-7B** (4.37 GB) - Modèle de base
4. **CodeLlama-7B-Instruct** (4.37 GB) - Spécialisé code
5. **Mistral-7B-Instruct** (4.37 GB) - Très performant
6. **Téléchargement personnalisé** - URL personnalisée

## 🛠️ Gestion du Service

```bash
# Démarrer le service
sudo systemctl start llama-api

# Arrêter le service
sudo systemctl stop llama-api

# Redémarrer le service
sudo systemctl restart llama-api

# Vérifier le statut
sudo systemctl status llama-api

# Voir les logs
sudo journalctl -u llama-api -f

# Activer le démarrage automatique
sudo systemctl enable llama-api
```

## 🔍 Dépannage

### Problèmes courants

1. **Port 8000 déjà utilisé**
   ```bash
   sudo lsof -i :8000
   sudo kill -9 [PID]
   ```

2. **Modèle non trouvé**
   ```bash
   ./download_model.sh
   ```

3. **Dépendances manquantes**
   ```bash
   ./install_clean.sh
   ```

4. **Permissions insuffisantes**
   ```bash
   chmod +x *.sh
   ```

### Logs et diagnostic

```bash
# Logs de l'application
tail -f logs/llama_api.log

# Logs système
sudo journalctl -u llama-api -f

# Informations système
./network-info.sh
```

## 🔒 Sécurité

- L'API est accessible sur le réseau local (0.0.0.0:8000)
- Configurez votre firewall si nécessaire
- Pour un accès externe, utilisez un reverse proxy avec authentification

## 📊 Performance

### Configuration recommandée
- **CPU** : 4+ cœurs
- **RAM** : 16GB
- **Espace disque** : SSD recommandé
- **Réseau** : 100Mbps minimum

### Optimisations automatiques
- Compilation optimisée pour votre CPU
- Gestion intelligente de la mémoire
- Quantisation Q4_K_M pour équilibre performance/taille

## 🤝 Contribution

Ce projet est maintenu par la communauté. Pour contribuer :

1. Fork le projet
2. Créez une branche pour votre fonctionnalité
3. Committez vos changements
4. Poussez vers la branche
5. Ouvrez une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.

## 🙏 Remerciements

- [llama.cpp](https://github.com/ggerganov/llama.cpp) - Moteur d'inference
- [FastAPI](https://fastapi.tiangolo.com/) - Framework web
- [TheBloke](https://huggingface.co/TheBloke) - Modèles quantifiés
- [Hugging Face](https://huggingface.co/) - Hébergement des modèles

---

**🎯 Votre API Llama.cpp est prête !** 

Pour commencer, exécutez simplement :
```bash
./install_clean.sh
```
