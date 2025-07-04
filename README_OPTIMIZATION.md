# 🚀 Guide d'Optimisation Mistral - Serveur Distant

## 📋 Vue d'ensemble

Ce guide vous permet d'optimiser Mistral sur votre serveur distant via SSH. Le système inclut :
- **Analyse automatique** de votre matériel
- **Configuration optimisée** pour votre setup
- **Système de logs avancé** pour diagnostiquer les performances
- **Téléchargement automatique** du bon modèle

## 🛠️ Installation

### 1. Configuration du serveur
```bash
# Configurer la connexion SSH
./server_config.sh
```

Suivez les instructions pour configurer :
- Nom d'utilisateur SSH
- Adresse IP du serveur
- Chemin sur le serveur

### 2. Déploiement des fichiers
```bash
# Déployer les scripts d'optimisation
./deploy_to_server.sh
```

## 🚀 Utilisation

### Analyse du système
```bash
# Analyser votre matériel et obtenir des recommandations
./remote_optimize.sh analyze
```

### Optimisation complète
```bash
# Exécuter toutes les optimisations automatiquement
./remote_optimize.sh all
```

### Diagnostic de performance
```bash
# Diagnostic complet avec rapport détaillé
./remote_optimize.sh diagnose
```

### Surveillance des logs
```bash
# Voir les logs de performance en temps réel
./remote_optimize.sh logs
```

### Gestion du serveur
```bash
# Redémarrer le serveur
./remote_optimize.sh restart

# Vérifier l'état du serveur
./remote_optimize.sh status
```

## 📊 Commandes Disponibles

| Commande | Description |
|----------|-------------|
| `analyze` | Analyse le système et génère des recommandations |
| `optimize` | Crée une configuration optimisée |
| `download` | Télécharge le modèle recommandé |
| `all` | Exécute toutes les optimisations |
| `diagnose` | Diagnostic complet de performance |
| `logs` | Affiche les logs de performance |
| `restart` | Redémarre le serveur |
| `status` | Vérifie l'état du serveur |

## 🔍 Système de Logs

Le système génère 4 types de logs sur le serveur :

### 1. `logs/api.log` - Logs généraux
```
2024-01-15 10:30:15 - INFO - 🚀 REQUEST_START [uuid] - Modèle: mistral-7b-instruct
2024-01-15 10:30:18 - INFO - ✅ REQUEST_END [uuid] - Temps: 3.45s - Tokens: 156
```

### 2. `logs/performance.log` - Métriques de performance
```
2024-01-15 10:30:18 - PERF [uuid] - ResponseTime:3.450s - Tokens:156
```

### 3. `logs/errors.log` - Erreurs détaillées
```
2024-01-15 10:30:15 - ERROR - ❌ ERROR [uuid] - chat_completion - Model not loaded
```

### 4. `logs/system.log` - État du système
```
2024-01-15 10:30:15 - SYSTEM_STATUS - {"cpu_percent": 45.2, "memory_percent": 78.5}
```

## ⚡ Optimisations Automatiques

### Basées sur la RAM
- **< 8GB** : Modèle 3B, contexte 2048, batch 256
- **8-12GB** : Modèle 7B, contexte 4096, batch 512
- **> 16GB** : Modèle 13B, contexte 8192, batch 1024

### Basées sur le GPU
- **GTX 950M (4GB)** : n_gpu_layers=32, f16_kv=True
- **GPU 8GB+** : n_gpu_layers=-1 (toutes les couches)
- **CPU uniquement** : Optimisations CPU uniquement

### Basées sur le CPU
- **i5 4 cœurs** : n_threads=4, mul_mat_q=True
- **8+ cœurs** : n_threads=n-1 (réserve un cœur)

## 📈 Diagnostic de Performance

Le diagnostic génère un rapport complet avec :

### Informations système
- CPU : nombre de cœurs, fréquence, utilisation
- RAM : totale, utilisée, disponible
- GPU : modèle, VRAM, température, utilisation
- Disque : espace libre, utilisation

### Analyse des performances
- Temps de réponse moyen/min/max
- Tokens par seconde
- Distribution des performances
- Requêtes par heure

### Détection de problèmes
- Mémoire insuffisante
- CPU surchargé
- Disque plein
- Modèle manquant
- Performances lentes

### Recommandations
- Optimisations spécifiques à votre matériel
- Actions à effectuer
- Priorités (high/medium/low)

## 🔧 Configuration Manuelle

Si vous voulez ajuster manuellement :

### 1. Se connecter au serveur
```bash
ssh root@your-server-ip
cd /opt/llama-api
```

### 2. Modifier la configuration
```bash
nano config.py
```

### 3. Redémarrer le serveur
```bash
sudo systemctl restart llama-api
```

## 🐛 Dépannage

### Problème de connexion SSH
```bash
# Tester la connexion
ssh -o ConnectTimeout=10 root@your-server-ip "echo 'test'"

# Vérifier les clés SSH
ls -la ~/.ssh/
```

### Problème de permissions
```bash
# Sur le serveur
chmod +x /opt/llama-api/*.py
chown -R root:root /opt/llama-api/
```

### Problème de dépendances
```bash
# Sur le serveur
pip3 install psutil requests
```

### Problème de modèle
```bash
# Vérifier les modèles disponibles
ls -la /opt/llama-api/models/

# Télécharger un modèle spécifique
python3 optimize_mistral.py --download
```

## 📞 Support

En cas de problème :

1. **Vérifiez les logs** : `./remote_optimize.sh logs`
2. **Diagnostiquez** : `./remote_optimize.sh diagnose`
3. **Vérifiez l'état** : `./remote_optimize.sh status`

## 🎯 Résultats Attendus

Après optimisation, vous devriez voir :
- **Temps de réponse** : 2-5 secondes (au lieu de 10+)
- **Tokens par seconde** : 50-100 (selon votre matériel)
- **Utilisation mémoire** : 70-85% (stable)
- **Utilisation GPU** : 80-95% (si disponible)

## 🔄 Mise à jour

Pour mettre à jour les scripts :
```bash
# Redéployer
./deploy_to_server.sh

# Redémarrer le serveur
./remote_optimize.sh restart
``` 