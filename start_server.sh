#!/bin/bash

echo "🚀 Démarrage de l'API Llama.cpp optimisée"
echo "========================================="

# Vérification de l'environnement virtuel
if [ ! -d "venv" ]; then
    echo "❌ Environnement virtuel non trouvé"
    echo "🔧 Exécutez d'abord : ./install.sh"
    exit 1
fi

# Activation de l'environnement virtuel
echo "🐍 Activation de l'environnement virtuel..."
source venv/bin/activate

# Vérification des dépendances
echo "📦 Vérification des dépendances..."
if ! python -c "import fastapi, uvicorn, llama_cpp" 2>/dev/null; then
    echo "❌ Dépendances manquantes"
    echo "🔧 Exécutez : pip install -r requirements.txt"
    exit 1
fi

# Vérification du modèle
echo "🤖 Vérification du modèle..."
if [ ! -f "models/llama-2-7b-chat.gguf" ]; then
    echo "❌ Modèle non trouvé"
    echo "📥 Exécutez d'abord : ./download_model.sh"
    exit 1
fi

# Vérification de llama.cpp
if [ ! -d "llama.cpp" ]; then
    echo "❌ llama.cpp non trouvé"
    echo "🔧 Exécutez d'abord : ./install.sh"
    exit 1
fi

# Vérification de la compilation
if [ ! -f "llama.cpp/main" ]; then
    echo "⚠️  llama.cpp non compilé, compilation en cours..."
    cd llama.cpp
    make clean
    make LLAMA_CUBLAS=1 LLAMA_AVX=1 LLAMA_AVX2=1 LLAMA_F16C=1 LLAMA_FMA=1 LLAMA_BLAS=1 LLAMA_OPENBLAS=1 -j$(nproc)
    cd ..
fi

# Vérification de CUDA
echo "🎮 Vérification de CUDA..."
if command -v nvidia-smi &> /dev/null; then
    echo "✅ NVIDIA GPU détecté"
    nvidia-smi --query-gpu=name,memory.total,memory.free --format=csv,noheader,nounits
else
    echo "⚠️  NVIDIA GPU non détecté, utilisation CPU uniquement"
fi

# Vérification de la mémoire
echo "💾 Vérification de la mémoire..."
TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
AVAILABLE_RAM=$(free -g | awk '/^Mem:/{print $7}')
echo "📊 RAM totale: ${TOTAL_RAM}GB, Disponible: ${AVAILABLE_RAM}GB"

if [ $AVAILABLE_RAM -lt 4 ]; then
    echo "⚠️  Attention: Moins de 4GB de RAM disponible"
    echo "💡 Fermez d'autres applications pour de meilleures performances"
fi

# Création des répertoires nécessaires
echo "📁 Création des répertoires..."
mkdir -p logs
mkdir -p static
mkdir -p templates

# Vérification des permissions
echo "🔐 Vérification des permissions..."
chmod +x llama_api.py
chmod +x config.py

# Affichage de la configuration
echo ""
echo "⚙️  Configuration détectée :"
echo "   • Modèle: llama-2-7b-chat.gguf"
echo "   • API: FastAPI + Uvicorn"
echo "   • Interface: Web moderne avec coloration syntaxique"
echo "   • Optimisations: i5 + GTX 950M + 8GB RAM"
echo ""

# Démarrage du serveur
echo "🌐 Démarrage du serveur..."
echo "📡 L'API sera accessible sur : http://localhost:8000"
echo "📖 Documentation API : http://localhost:8000/docs"
echo "🔧 Interface web : http://localhost:8000"
echo ""
echo "🛑 Pour arrêter le serveur, appuyez sur Ctrl+C"
echo ""

# Démarrage avec uvicorn
python llama_api.py 