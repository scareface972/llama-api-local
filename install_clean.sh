#!/bin/bash

echo "🚀 Installation propre de l'API Llama.cpp"
echo "========================================"

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

# Fonction de vérification d'erreur
check_error() {
    if [ $? -ne 0 ]; then
        print_error "$1"
        exit 1
    fi
}

# Vérification de l'utilisateur
if [ "$EUID" -eq 0 ]; then
    print_error "Ne pas exécuter ce script en tant que root"
    print_status "Utilisez un utilisateur normal avec sudo"
    exit 1
fi

print_status "Utilisateur: $(whoami)"
print_status "Répertoire: $(pwd)"

# ============================================================================
# ÉTAPE 1: MISE À JOUR DU SYSTÈME
# ============================================================================
print_status "ÉTAPE 1: Mise à jour du système..."
sudo apt update && sudo apt upgrade -y
check_error "Échec de la mise à jour du système"

# ============================================================================
# ÉTAPE 2: INSTALLATION DES DÉPENDANCES SYSTÈME
# ============================================================================
print_status "ÉTAPE 2: Installation des dépendances système..."

# Dépendances système essentielles
sudo apt install -y \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    python3 \
    python3-pip \
    python3-venv \
    libopenblas-dev \
    liblapack-dev \
    gfortran \
    libssl-dev \
    libffi-dev \
    pkg-config \
    htop

check_error "Échec de l'installation des dépendances système"

# ============================================================================
# ÉTAPE 3: CRÉATION DE L'ENVIRONNEMENT VIRTUEL
# ============================================================================
print_status "ÉTAPE 3: Configuration de l'environnement Python..."

# Suppression de l'ancien environnement si il existe
if [ -d "venv" ]; then
    print_warning "Environnement virtuel existe déjà, suppression..."
    rm -rf venv
fi

# Création d'un nouvel environnement virtuel
python3 -m venv venv
check_error "Échec de la création de l'environnement virtuel"

# Activation de l'environnement virtuel
source venv/bin/activate
check_error "Échec de l'activation de l'environnement virtuel"

# Vérification que l'environnement est activé
if [ -z "$VIRTUAL_ENV" ]; then
    print_error "L'environnement virtuel n'est pas activé"
    exit 1
fi

print_status "Environnement virtuel activé : $VIRTUAL_ENV"

# ============================================================================
# ÉTAPE 4: INSTALLATION DES DÉPENDANCES PYTHON
# ============================================================================
print_status "ÉTAPE 4: Installation des dépendances Python..."

# Mise à jour de pip
python -m pip install --upgrade pip
check_error "Échec de la mise à jour de pip"

# Installation des dépendances de base
python -m pip install --upgrade setuptools wheel
check_error "Échec de l'installation de setuptools/wheel"

# Installation séquentielle des dépendances
print_status "Installation séquentielle des dépendances..."

# 1. Numpy
print_status "1. Installation de numpy..."
python -m pip install "numpy>=1.24.0"
check_error "Échec de l'installation de numpy"

# 2. FastAPI et Uvicorn
print_status "2. Installation de FastAPI et Uvicorn..."
python -m pip install "fastapi>=0.104.1" "uvicorn[standard]>=0.24.0"
check_error "Échec de l'installation de FastAPI/Uvicorn"

# 3. Pydantic
print_status "3. Installation de Pydantic..."
python -m pip install "pydantic>=2.5.0"
check_error "Échec de l'installation de Pydantic"

# 4. Autres dépendances web
print_status "4. Installation des dépendances web..."
python -m pip install "python-multipart>=0.0.6" "jinja2>=3.1.2" "aiofiles>=23.2.1"
check_error "Échec de l'installation des dépendances web"

# 5. Psutil
print_status "5. Installation de psutil..."
python -m pip install "psutil>=5.9.6"
check_error "Échec de l'installation de psutil"

# 6. PyTorch (CPU uniquement pour simplifier)
print_status "6. Installation de PyTorch (CPU)..."
python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
check_error "Échec de l'installation de PyTorch"

# 7. Transformers
print_status "7. Installation de Transformers..."
python -m pip install "transformers>=4.36.0" "sentencepiece>=0.1.99"
check_error "Échec de l'installation de Transformers"

# 8. Llama-cpp-python (CPU uniquement)
print_status "8. Installation de llama-cpp-python..."
python -m pip install llama-cpp-python --no-cache-dir
check_error "Échec de l'installation de llama-cpp-python"

# ============================================================================
# ÉTAPE 5: INSTALLATION DE LLAMA.CPP
# ============================================================================
print_status "ÉTAPE 5: Installation de llama.cpp..."

# Suppression de l'ancienne installation si elle existe
if [ -d "llama.cpp" ]; then
    print_warning "llama.cpp existe déjà, suppression..."
    rm -rf llama.cpp
fi

# Clonage de llama.cpp
git clone https://github.com/ggerganov/llama.cpp.git
check_error "Échec du clonage de llama.cpp"

cd llama.cpp

# Compilation avec CMake (nouvelle méthode)
print_status "Compilation avec CMake (nouvelle méthode)..."
mkdir -p build
cd build

# Configuration CMake avec optimisations
cmake .. -DLLAMA_BLAS=ON -DLLAMA_OPENBLAS=ON -DGGML_NATIVE=ON -DLLAMA_BUILD_SERVER=ON -DLLAMA_METAL=OFF -DLLAMA_CUBLAS=OFF
check_error "Échec de la configuration CMake"

# Compilation
make -j$(nproc)
check_error "Échec de la compilation de llama.cpp"

# Retour au répertoire principal
cd ../..

# ============================================================================
# ÉTAPE 6: CRÉATION DE LA STRUCTURE DU PROJET
# ============================================================================
print_status "ÉTAPE 6: Création de la structure du projet..."
mkdir -p models
mkdir -p logs
mkdir -p static
mkdir -p templates
mkdir -p config

# ============================================================================
# ÉTAPE 7: CRÉATION DES FICHIERS DE CONFIGURATION
# ============================================================================
print_status "ÉTAPE 7: Création des fichiers de configuration..."

# Création du fichier requirements.txt
cat > requirements.txt << 'EOF'
fastapi>=0.104.1
uvicorn[standard]>=0.24.0
pydantic>=2.5.0
python-multipart>=0.0.6
jinja2>=3.1.2
aiofiles>=23.2.1
psutil>=5.9.6
torch>=2.0.0
transformers>=4.36.0
sentencepiece>=0.1.99
llama-cpp-python>=0.2.0
numpy>=1.24.0
EOF

# Création du fichier de configuration
cat > config.py << 'EOF'
import os
from pathlib import Path

# Configuration de base
BASE_DIR = Path(__file__).parent
MODELS_DIR = BASE_DIR / "models"
LOGS_DIR = BASE_DIR / "logs"
STATIC_DIR = BASE_DIR / "static"
TEMPLATES_DIR = BASE_DIR / "templates"

# Configuration du serveur
HOST = "0.0.0.0"
PORT = 8000
WORKERS = 1
RELOAD = True

# Configuration du modèle
DEFAULT_MODEL = "llama-2-7b-chat.gguf"
MODEL_PATH = MODELS_DIR / DEFAULT_MODEL

# Configuration CUDA (désactivée par défaut)
USE_CUDA = False
CUDA_LAYERS = 0

# Configuration de la génération
MAX_TOKENS = 2048
TEMPERATURE = 0.7
TOP_P = 0.9
TOP_K = 40
REPEAT_PENALTY = 1.1

# Configuration des logs
LOG_LEVEL = "INFO"
LOG_FILE = LOGS_DIR / "llama_api.log"

# Création des répertoires si ils n'existent pas
for directory in [MODELS_DIR, LOGS_DIR, STATIC_DIR, TEMPLATES_DIR]:
    directory.mkdir(exist_ok=True)
EOF

# Création du fichier principal de l'API
cat > llama_api.py << 'EOF'
#!/usr/bin/env python3
"""
API Llama.cpp - Serveur FastAPI pour l'inference de modèles de langage
"""

import os
import sys
import logging
import asyncio
from pathlib import Path
from typing import Optional, Dict, Any, List
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI, HTTPException, Request, BackgroundTasks
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel, Field
import psutil

# Ajout du répertoire parent au path pour les imports
sys.path.append(str(Path(__file__).parent))

try:
    from llama_cpp import Llama
    from config import *
except ImportError as e:
    print(f"Erreur d'import: {e}")
    print("Vérifiez que toutes les dépendances sont installées")
    sys.exit(1)

# Configuration des logs
logging.basicConfig(
    level=getattr(logging, LOG_LEVEL),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Variables globales
llm: Optional[Llama] = None
model_loaded = False

class ChatRequest(BaseModel):
    message: str = Field(..., description="Message de l'utilisateur")
    system_prompt: Optional[str] = Field(None, description="Prompt système optionnel")
    max_tokens: Optional[int] = Field(MAX_TOKENS, description="Nombre maximum de tokens")
    temperature: Optional[float] = Field(TEMPERATURE, description="Température pour la génération")
    top_p: Optional[float] = Field(TOP_P, description="Top-p sampling")
    top_k: Optional[int] = Field(TOP_K, description="Top-k sampling")
    repeat_penalty: Optional[float] = Field(REPEAT_PENALTY, description="Pénalité de répétition")

class ChatResponse(BaseModel):
    response: str
    tokens_used: int
    model_info: Dict[str, Any]

class HealthResponse(BaseModel):
    status: str
    model_loaded: bool
    system_info: Dict[str, Any]

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestion du cycle de vie de l'application"""
    global llm, model_loaded
    
    logger.info("Démarrage de l'API Llama.cpp...")
    
    # Chargement du modèle en arrière-plan
    asyncio.create_task(load_model_async())
    
    yield
    
    logger.info("Arrêt de l'API Llama.cpp...")
    if llm:
        del llm

# Création de l'application FastAPI
app = FastAPI(
    title="API Llama.cpp",
    description="API REST pour l'inference de modèles de langage avec llama.cpp",
    version="1.0.0",
    lifespan=lifespan
)

# Montage des fichiers statiques et templates
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")
templates = Jinja2Templates(directory=TEMPLATES_DIR)

async def load_model_async():
    """Chargement asynchrone du modèle"""
    global llm, model_loaded
    
    try:
        logger.info("Chargement du modèle en cours...")
        
        if not MODEL_PATH.exists():
            logger.error(f"Modèle non trouvé: {MODEL_PATH}")
            return
        
        # Configuration du modèle
        model_config = {
            "model_path": str(MODEL_PATH),
            "n_ctx": 4096,
            "n_batch": 512,
            "n_threads": os.cpu_count(),
            "verbose": False
        }
        
        # Ajout de la configuration CUDA si disponible
        if USE_CUDA:
            model_config.update({
                "n_gpu_layers": CUDA_LAYERS,
                "main_gpu": 0
            })
            logger.info("Configuration CUDA activée")
        
        llm = Llama(**model_config)
        model_loaded = True
        logger.info("✅ Modèle chargé avec succès")
        
    except Exception as e:
        logger.error(f"Erreur lors du chargement du modèle: {e}")
        model_loaded = False

@app.get("/", response_class=HTMLResponse)
async def root(request: Request):
    """Page d'accueil"""
    return templates.TemplateResponse("index.html", {"request": request})

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Vérification de l'état du serveur"""
    system_info = {
        "cpu_count": psutil.cpu_count(),
        "memory_total": psutil.virtual_memory().total,
        "memory_available": psutil.virtual_memory().available,
        "disk_usage": psutil.disk_usage('/').percent
    }
    
    return HealthResponse(
        status="healthy" if model_loaded else "loading",
        model_loaded=model_loaded,
        system_info=system_info
    )

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """Endpoint de chat avec le modèle"""
    global llm, model_loaded
    
    if not model_loaded or llm is None:
        raise HTTPException(status_code=503, detail="Modèle non encore chargé")
    
    try:
        # Préparation du prompt
        if request.system_prompt:
            full_prompt = f"[INST] <<SYS>>\n{request.system_prompt}\n<</SYS>>\n\n{request.message} [/INST]"
        else:
            full_prompt = f"[INST] {request.message} [/INST]"
        
        # Génération de la réponse
        response = llm(
            full_prompt,
            max_tokens=request.max_tokens,
            temperature=request.temperature,
            top_p=request.top_p,
            top_k=request.top_k,
            repeat_penalty=request.repeat_penalty,
            stop=["[INST]", "</s>"]
        )
        
        # Extraction de la réponse
        generated_text = response['choices'][0]['text'].strip()
        tokens_used = response['usage']['total_tokens']
        
        # Informations sur le modèle
        model_info = {
            "model_name": MODEL_PATH.name,
            "context_length": response['usage']['prompt_tokens'] + response['usage']['completion_tokens'],
            "generation_time": response.get('generation_time', 0)
        }
        
        return ChatResponse(
            response=generated_text,
            tokens_used=tokens_used,
            model_info=model_info
        )
        
    except Exception as e:
        logger.error(f"Erreur lors de la génération: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur de génération: {str(e)}")

@app.get("/models")
async def list_models():
    """Liste des modèles disponibles"""
    models = []
    for model_file in MODELS_DIR.glob("*.gguf"):
        models.append({
            "name": model_file.name,
            "size": model_file.stat().st_size,
            "path": str(model_file)
        })
    return {"models": models}

@app.get("/system/info")
async def system_info():
    """Informations système"""
    return {
        "cpu_count": psutil.cpu_count(),
        "memory": {
            "total": psutil.virtual_memory().total,
            "available": psutil.virtual_memory().available,
            "percent": psutil.virtual_memory().percent
        },
        "disk": {
            "total": psutil.disk_usage('/').total,
            "free": psutil.disk_usage('/').free,
            "percent": psutil.disk_usage('/').percent
        },
        "model_loaded": model_loaded
    }

if __name__ == "__main__":
    logger.info(f"Démarrage du serveur sur {HOST}:{PORT}")
    uvicorn.run(
        "llama_api:app",
        host=HOST,
        port=PORT,
        reload=RELOAD,
        workers=WORKERS
    )
EOF

# Création du template HTML
mkdir -p templates
cat > templates/index.html << 'EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>API Llama.cpp</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 2.5em;
            font-weight: 300;
        }
        .header p {
            margin: 10px 0 0 0;
            opacity: 0.9;
            font-size: 1.1em;
        }
        .content {
            padding: 30px;
        }
        .chat-container {
            display: flex;
            flex-direction: column;
            height: 500px;
            border: 2px solid #e1e5e9;
            border-radius: 10px;
            overflow: hidden;
        }
        .chat-messages {
            flex: 1;
            overflow-y: auto;
            padding: 20px;
            background: #f8f9fa;
        }
        .message {
            margin-bottom: 15px;
            padding: 15px;
            border-radius: 10px;
            max-width: 80%;
        }
        .message.user {
            background: #007bff;
            color: white;
            margin-left: auto;
        }
        .message.assistant {
            background: white;
            border: 1px solid #e1e5e9;
        }
        .chat-input {
            display: flex;
            padding: 20px;
            background: white;
            border-top: 1px solid #e1e5e9;
        }
        .chat-input input {
            flex: 1;
            padding: 15px;
            border: 2px solid #e1e5e9;
            border-radius: 25px;
            font-size: 16px;
            outline: none;
        }
        .chat-input input:focus {
            border-color: #667eea;
        }
        .chat-input button {
            margin-left: 10px;
            padding: 15px 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 25px;
            cursor: pointer;
            font-size: 16px;
            transition: transform 0.2s;
        }
        .chat-input button:hover {
            transform: translateY(-2px);
        }
        .chat-input button:disabled {
            opacity: 0.6;
            cursor: not-allowed;
            transform: none;
        }
        .status {
            text-align: center;
            margin-bottom: 20px;
            padding: 10px;
            border-radius: 5px;
            font-weight: bold;
        }
        .status.loading {
            background: #fff3cd;
            color: #856404;
            border: 1px solid #ffeaa7;
        }
        .status.ready {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .status.error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .info-panel {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            margin-top: 20px;
        }
        .info-panel h3 {
            margin-top: 0;
            color: #495057;
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
        }
        .info-item {
            background: white;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #667eea;
        }
        .info-label {
            font-weight: bold;
            color: #495057;
            font-size: 0.9em;
        }
        .info-value {
            font-size: 1.1em;
            color: #212529;
            margin-top: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🤖 API Llama.cpp</h1>
            <p>Interface de chat avec modèle de langage local</p>
        </div>
        
        <div class="content">
            <div id="status" class="status loading">
                🔄 Chargement du modèle en cours...
            </div>
            
            <div class="chat-container">
                <div id="messages" class="chat-messages">
                    <div class="message assistant">
                        👋 Bonjour ! Je suis votre assistant IA local. Posez-moi vos questions !
                    </div>
                </div>
                <div class="chat-input">
                    <input type="text" id="messageInput" placeholder="Tapez votre message..." disabled>
                    <button id="sendButton" disabled>Envoyer</button>
                </div>
            </div>
            
            <div class="info-panel">
                <h3>📊 Informations système</h3>
                <div id="systemInfo" class="info-grid">
                    <div class="info-item">
                        <div class="info-label">État du modèle</div>
                        <div class="info-value">Chargement...</div>
                    </div>
                    <div class="info-item">
                        <div class="info-label">CPU</div>
                        <div class="info-value">-</div>
                    </div>
                    <div class="info-item">
                        <div class="info-label">Mémoire</div>
                        <div class="info-value">-</div>
                    </div>
                    <div class="info-item">
                        <div class="info-label">Disque</div>
                        <div class="info-value">-</div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        let isModelReady = false;
        
        // Vérification de l'état du serveur
        async function checkHealth() {
            try {
                const response = await fetch('/health');
                const data = await response.json();
                
                if (data.model_loaded) {
                    document.getElementById('status').className = 'status ready';
                    document.getElementById('status').textContent = '✅ Modèle prêt !';
                    document.getElementById('messageInput').disabled = false;
                    document.getElementById('sendButton').disabled = false;
                    isModelReady = true;
                } else {
                    document.getElementById('status').className = 'status loading';
                    document.getElementById('status').textContent = '🔄 Chargement du modèle en cours...';
                }
                
                // Mise à jour des informations système
                updateSystemInfo(data.system_info);
                
            } catch (error) {
                document.getElementById('status').className = 'status error';
                document.getElementById('status').textContent = '❌ Erreur de connexion au serveur';
            }
        }
        
        // Mise à jour des informations système
        function updateSystemInfo(info) {
            const cpuElement = document.querySelector('.info-item:nth-child(2) .info-value');
            const memoryElement = document.querySelector('.info-item:nth-child(3) .info-value');
            const diskElement = document.querySelector('.info-item:nth-child(4) .info-value');
            
            cpuElement.textContent = `${info.cpu_count} cœurs`;
            memoryElement.textContent = `${Math.round(info.memory_available / 1024 / 1024 / 1024)} GB libres`;
            diskElement.textContent = `${Math.round(info.disk_usage)}% utilisé`;
        }
        
        // Envoi de message
        async function sendMessage() {
            if (!isModelReady) return;
            
            const input = document.getElementById('messageInput');
            const message = input.value.trim();
            
            if (!message) return;
            
            // Ajout du message utilisateur
            addMessage(message, 'user');
            input.value = '';
            
            // Désactivation de l'interface
            document.getElementById('sendButton').disabled = true;
            document.getElementById('messageInput').disabled = true;
            
            try {
                const response = await fetch('/chat', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        message: message,
                        max_tokens: 2048,
                        temperature: 0.7
                    })
                });
                
                const data = await response.json();
                
                if (response.ok) {
                    addMessage(data.response, 'assistant');
                } else {
                    addMessage(`❌ Erreur: ${data.detail}`, 'assistant');
                }
                
            } catch (error) {
                addMessage(`❌ Erreur de connexion: ${error.message}`, 'assistant');
            } finally {
                // Réactivation de l'interface
                document.getElementById('sendButton').disabled = false;
                document.getElementById('messageInput').disabled = false;
                document.getElementById('messageInput').focus();
            }
        }
        
        // Ajout d'un message dans le chat
        function addMessage(text, type) {
            const messagesDiv = document.getElementById('messages');
            const messageDiv = document.createElement('div');
            messageDiv.className = `message ${type}`;
            messageDiv.textContent = text;
            messagesDiv.appendChild(messageDiv);
            messagesDiv.scrollTop = messagesDiv.scrollHeight;
        }
        
        // Événements
        document.getElementById('sendButton').addEventListener('click', sendMessage);
        document.getElementById('messageInput').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                sendMessage();
            }
        });
        
        // Vérification périodique de l'état
        checkHealth();
        setInterval(checkHealth, 5000);
        
        // Récupération des informations système
        async function updateSystemInfo() {
            try {
                const response = await fetch('/system/info');
                const data = await response.json();
                updateSystemInfo(data);
            } catch (error) {
                console.error('Erreur lors de la récupération des informations système:', error);
            }
        }
        
        // Mise à jour des informations système toutes les 10 secondes
        setInterval(updateSystemInfo, 10000);
    </script>
</body>
</html>
EOF

# ============================================================================
# ÉTAPE 8: CONFIGURATION DES PERMISSIONS
# ============================================================================
print_status "ÉTAPE 8: Configuration des permissions..."
chmod +x *.sh
chmod +x llama_api.py

# ============================================================================
# ÉTAPE 9: CONFIGURATION DU SERVICE SYSTEMD
# ============================================================================
print_status "ÉTAPE 9: Configuration du service systemd..."

# Détection de l'utilisateur et du chemin
CURRENT_USER=$(whoami)
CURRENT_GROUP=$(id -gn)
PROJECT_PATH=$(pwd)

# Création du fichier service
cat > llama-api.service << EOF
[Unit]
Description=Llama.cpp API Server
After=network.target

[Service]
Type=simple
User=$CURRENT_USER
Group=$CURRENT_GROUP
WorkingDirectory=$PROJECT_PATH
Environment=PATH=$PROJECT_PATH/venv/bin
ExecStart=$PROJECT_PATH/venv/bin/python $PROJECT_PATH/llama_api.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Copie du fichier service vers systemd
sudo cp llama-api.service /etc/systemd/system/
check_error "Échec de la copie du fichier service"

# Rechargement de systemd
sudo systemctl daemon-reload
check_error "Échec du rechargement de systemd"

# Activation du service
sudo systemctl enable llama-api.service
check_error "Échec de l'activation du service"

print_status "✅ Service systemd configuré et activé"

# ============================================================================
# ÉTAPE 10: CONFIGURATION DU FIREWALL
# ============================================================================
print_status "ÉTAPE 10: Configuration du firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw allow 8000/tcp
    print_status "✅ Port 8000 ouvert dans le firewall"
else
    print_warning "UFW non installé, configurez manuellement le port 8000"
fi

# ============================================================================
# ÉTAPE 11: VÉRIFICATION FINALE
# ============================================================================
print_status "ÉTAPE 11: Vérification finale..."

# Vérification de l'environnement virtuel
if [ -d "venv" ] && [ -f "venv/bin/activate" ]; then
    print_status "✅ Environnement virtuel créé"
else
    print_error "❌ Environnement virtuel manquant"
    exit 1
fi

# Vérification de llama.cpp
if [ -d "llama.cpp" ] && [ -f "llama.cpp/build/main" ]; then
    print_status "✅ llama.cpp compilé"
else
    print_error "❌ llama.cpp manquant ou non compilé"
    exit 1
fi

# Vérification des dépendances Python
source venv/bin/activate
python -c "
import sys
packages = ['fastapi', 'uvicorn', 'pydantic', 'numpy', 'torch', 'transformers', 'llama_cpp']
missing = []
for pkg in packages:
    try:
        __import__(pkg)
        print(f'✅ {pkg} installé')
    except ImportError:
        missing.append(pkg)
        print(f'❌ {pkg} manquant')

if missing:
    print(f'\\n❌ Packages manquants: {missing}')
    sys.exit(1)
else:
    print('\\n✅ Toutes les dépendances sont installées')
"

if [ $? -eq 0 ]; then
    print_status "✅ Installation terminée avec succès !"
else
    print_error "❌ Certaines dépendances sont manquantes"
    exit 1
fi

# ============================================================================
# FINALISATION
# ============================================================================
echo ""
echo "🎉 INSTALLATION PROPRE TERMINÉE AVEC SUCCÈS !"
echo "============================================="
echo ""
echo "📋 Prochaines étapes :"
echo "1. Télécharger le modèle : ./download_model.sh"
echo "2. Tester le serveur : ./start_server.sh"
echo "3. Ou démarrer le service : sudo systemctl start llama-api"
echo "4. Vérifier le statut : sudo systemctl status llama-api"
echo "5. Voir les logs : sudo journalctl -u llama-api -f"
echo ""
echo "🌐 URLs d'accès :"
echo "   • Interface Web : http://localhost:8000"
echo "   • Documentation API : http://localhost:8000/docs"
echo "   • Health Check : http://localhost:8000/health"
echo ""
echo "🔧 Commandes utiles :"
echo "   • Démarrer : sudo systemctl start llama-api"
echo "   • Arrêter : sudo systemctl stop llama-api"
echo "   • Redémarrer : sudo systemctl restart llama-api"
echo "   • Statut : sudo systemctl status llama-api"
echo "   • Logs : sudo journalctl -u llama-api -f"
echo ""
echo "🎯 Votre API Llama.cpp est prête !" 