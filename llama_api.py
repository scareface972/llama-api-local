import asyncio
import json
import logging
import os
import sys
import time
from typing import Dict, List, Optional, Any, AsyncGenerator
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel, Field
import psutil

# Ajout du chemin vers llama.cpp
sys.path.append('./llama.cpp')

from config import Config

# Configuration du logging
logging.basicConfig(
    level=getattr(logging, Config.LOGGING_CONFIG["level"]),
    format=Config.LOGGING_CONFIG["format"],
    handlers=[
        logging.FileHandler(Config.LOGGING_CONFIG["file"]),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Modèles Pydantic
class ChatMessage(BaseModel):
    role: str = Field(..., description="Rôle de l'utilisateur (user/assistant)")
    content: str = Field(..., description="Contenu du message")

class ChatRequest(BaseModel):
    messages: List[ChatMessage] = Field(..., description="Historique des messages")
    model: str = Field(default="llama-2-7b-chat", description="Modèle à utiliser")
    temperature: float = Field(default=0.8, ge=0.0, le=2.0, description="Température de génération")
    max_tokens: int = Field(default=2048, ge=1, le=4096, description="Nombre maximum de tokens")
    stream: bool = Field(default=True, description="Activer le streaming")
    system_prompt: Optional[str] = Field(default=None, description="Prompt système")

class ChatResponse(BaseModel):
    id: str
    object: str = "chat.completion"
    created: int
    model: str
    choices: List[Dict[str, Any]]
    usage: Dict[str, int]

class HealthResponse(BaseModel):
    status: str
    model_loaded: bool
    hardware_info: Dict[str, Any]
    memory_usage: Dict[str, Any]

# Variables globales
llama_model = None
conversation_history: Dict[str, List[ChatMessage]] = {}

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestion du cycle de vie de l'application"""
    global llama_model
    
    # Optimisation de la configuration
    Config.optimize_for_hardware()
    
    # Chargement du modèle
    try:
        logger.info("🚀 Chargement du modèle llama.cpp...")
        llama_model = load_llama_model()
        logger.info("✅ Modèle chargé avec succès")
    except Exception as e:
        logger.error(f"❌ Erreur lors du chargement du modèle: {e}")
        llama_model = None
    
    yield
    
    # Nettoyage
    if llama_model:
        del llama_model
        logger.info("🧹 Modèle déchargé")

def load_llama_model():
    """Charge le modèle llama.cpp avec la configuration optimisée"""
    try:
        from llama_cpp import Llama
        
        config = Config.get_llama_args()
        model_path = config["model_path"]
        
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Modèle non trouvé: {model_path}")
        
        logger.info(f"📦 Chargement du modèle: {model_path}")
        logger.info(f"⚙️ Configuration: {config}")
        
        model = Llama(
            model_path=model_path,
            n_ctx=config["n_ctx"],
            n_batch=config["n_batch"],
            n_gpu_layers=config["n_gpu_layers"],
            n_threads=config["n_threads"],
            n_threads_batch=config["n_threads_batch"],
            rope_freq_base=config["rope_freq_base"],
            rope_freq_scale=config["rope_freq_scale"],
            mul_mat_q=config["mul_mat_q"],
            f16_kv=config["f16_kv"],
            logits_all=config["logits_all"],
            vocab_only=config["vocab_only"],
            use_mmap=config["use_mmap"],
            use_mlock=config["use_mlock"],
            embedding=config["embedding"],
            lora_adapter=config["lora_adapter"] if config["lora_adapter"] else None,
            lora_base=config["lora_base"] if config["lora_base"] else None,
            n_keep=config["n_keep"],
            n_discard=config["n_discard"],
            n_predict=config["n_predict"],
            n_parallel=config["n_parallel"],
            repeat_penalty=config["repeat_penalty"],
            repeat_last_n=config["repeat_last_n"],
            penalize_nl=config["penalize_nl"],
            temp=config["temp"],
            top_k=config["top_k"],
            top_p=config["top_p"],
            tfs_z=config["tfs_z"],
            typical_p=config["typical_p"],
            mirostat=config["mirostat"],
            mirostat_tau=config["mirostat_tau"],
            mirostat_eta=config["mirostat_eta"],
            grammar=config["grammar"] if config["grammar"] else None,
            grammar_penalty=config["grammar_penalty"],
            antiprompt=config["antiprompt"],
            logit_bias=config["logit_bias"],
            stop=config["stop"],
            stream=config["stream"],
            seed=config["seed"],
            ignore_eos=config["ignore_eos"],
            no_display_prompt=config["no_display_prompt"],
            interactive=config["interactive"],
            interactive_first=config["interactive_first"],
            multiline_input=config["multiline_input"],
            simple_io=config["simple_io"],
            color=config["color"],
            mlock=config["mlock"],
            no_mmap=config["no_mmap"],
            mtest=config["mtest"],
            verbose_prompt=config["verbose_prompt"],
            m_eval=config["m_eval"],
        )
        
        return model
        
    except ImportError:
        logger.error("❌ llama-cpp-python non installé. Exécutez: pip install llama-cpp-python")
        return None
    except Exception as e:
        logger.error(f"❌ Erreur lors du chargement du modèle: {e}")
        return None

# Création de l'application FastAPI
app = FastAPI(
    title="Llama.cpp API",
    description="API locale pour llama.cpp optimisée pour i5 + GTX 950M",
    version="1.0.0",
    lifespan=lifespan
)

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=Config.SECURITY_CONFIG["cors_origins"],
    allow_credentials=True,
    allow_methods=Config.SECURITY_CONFIG["cors_methods"],
    allow_headers=Config.SECURITY_CONFIG["cors_headers"],
)

# Montage des fichiers statiques
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

def get_hardware_info() -> Dict[str, Any]:
    """Récupère les informations matérielles"""
    return {
        "cpu_count": psutil.cpu_count(),
        "cpu_percent": psutil.cpu_percent(interval=1),
        "memory_total": psutil.virtual_memory().total,
        "memory_available": psutil.virtual_memory().available,
        "memory_percent": psutil.virtual_memory().percent,
        "disk_usage": psutil.disk_usage('/').percent,
        "config": Config.get_hardware_info()
    }

@app.get("/", response_class=HTMLResponse)
async def root(request):
    """Page d'accueil avec interface web"""
    return templates.TemplateResponse("index.html", {"request": request})

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Vérification de l'état de l'API"""
    return HealthResponse(
        status="healthy" if llama_model else "unhealthy",
        model_loaded=llama_model is not None,
        hardware_info=get_hardware_info(),
        memory_usage={
            "ram_used_gb": round(psutil.virtual_memory().used / (1024**3), 2),
            "ram_total_gb": round(psutil.virtual_memory().total / (1024**3), 2),
            "ram_percent": psutil.virtual_memory().percent
        }
    )

@app.post("/v1/chat/completions", response_model=ChatResponse)
async def chat_completions(request: ChatRequest):
    """Endpoint principal pour les conversations"""
    if not llama_model:
        raise HTTPException(status_code=503, detail="Modèle non chargé")
    
    try:
        # Préparation des messages
        messages = []
        for msg in request.messages:
            messages.append({"role": msg.role, "content": msg.content})
        
        # Ajout du prompt système si fourni
        if request.system_prompt:
            messages.insert(0, {"role": "system", "content": request.system_prompt})
        
        # Génération de la réponse
        response = llama_model.create_chat_completion(
            messages=messages,
            temperature=request.temperature,
            max_tokens=request.max_tokens,
            stream=request.stream,
            stop=Config.LLAMA_CONFIG["stop"]
        )
        
        return ChatResponse(
            id=f"chatcmpl-{int(time.time())}",
            created=int(time.time()),
            model=request.model,
            choices=response["choices"],
            usage=response.get("usage", {"prompt_tokens": 0, "completion_tokens": 0, "total_tokens": 0})
        )
        
    except Exception as e:
        logger.error(f"Erreur lors de la génération: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/v1/chat/completions/stream")
async def chat_completions_stream(request: ChatRequest):
    """Endpoint pour le streaming des réponses"""
    if not llama_model:
        raise HTTPException(status_code=503, detail="Modèle non chargé")
    
    async def generate_stream():
        try:
            messages = []
            for msg in request.messages:
                messages.append({"role": msg.role, "content": msg.content})
            
            if request.system_prompt:
                messages.insert(0, {"role": "system", "content": request.system_prompt})
            
            response = llama_model.create_chat_completion(
                messages=messages,
                temperature=request.temperature,
                max_tokens=request.max_tokens,
                stream=True,
                stop=Config.LLAMA_CONFIG["stop"]
            )
            
            for chunk in response:
                yield f"data: {json.dumps(chunk)}\n\n"
            
            yield "data: [DONE]\n\n"
            
        except Exception as e:
            logger.error(f"Erreur lors du streaming: {e}")
            yield f"data: {json.dumps({'error': str(e)})}\n\n"
    
    return StreamingResponse(
        generate_stream(),
        media_type="text/plain",
        headers={"Cache-Control": "no-cache", "Connection": "keep-alive"}
    )

@app.websocket("/ws/chat")
async def websocket_chat(websocket: WebSocket):
    """WebSocket pour les conversations en temps réel"""
    await websocket.accept()
    
    if not llama_model:
        await websocket.send_text(json.dumps({"error": "Modèle non chargé"}))
        return
    
    try:
        while True:
            data = await websocket.receive_text()
            request_data = json.loads(data)
            
            messages = request_data.get("messages", [])
            temperature = request_data.get("temperature", 0.8)
            max_tokens = request_data.get("max_tokens", 2048)
            
            # Génération de la réponse
            response = llama_model.create_chat_completion(
                messages=messages,
                temperature=temperature,
                max_tokens=max_tokens,
                stream=True,
                stop=Config.LLAMA_CONFIG["stop"]
            )
            
            # Envoi des chunks via WebSocket
            for chunk in response:
                await websocket.send_text(json.dumps(chunk))
            
            await websocket.send_text(json.dumps({"done": True}))
            
    except WebSocketDisconnect:
        logger.info("WebSocket déconnecté")
    except Exception as e:
        logger.error(f"Erreur WebSocket: {e}")
        await websocket.send_text(json.dumps({"error": str(e)}))

@app.get("/models")
async def list_models():
    """Liste des modèles disponibles"""
    models_dir = "models"
    if not os.path.exists(models_dir):
        return {"models": []}
    
    models = []
    for file in os.listdir(models_dir):
        if file.endswith(('.gguf', '.bin')):
            file_path = os.path.join(models_dir, file)
            size_mb = os.path.getsize(file_path) / (1024 * 1024)
            models.append({
                "id": file,
                "name": file.replace('.gguf', '').replace('.bin', ''),
                "size_mb": round(size_mb, 2),
                "format": file.split('.')[-1]
            })
    
    return {"models": models}

if __name__ == "__main__":
    config = Config.get_api_config()
    uvicorn.run(
        "llama_api:app",
        host=config["host"],
        port=config["port"],
        reload=config["debug"],
        workers=config["workers"],
        log_level=Config.LOGGING_CONFIG["level"].lower()
    ) 