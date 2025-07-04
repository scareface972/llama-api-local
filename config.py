import os
from typing import Dict, Any

class Config:
    """Configuration optimisée pour i5 + GTX 950M + 8GB RAM"""
    
    # Configuration matérielle
    HARDWARE_CONFIG = {
        "cpu_threads": 4,  # i5 typique
        "gpu_layers": 20,  # Optimisé pour 4GB VRAM
        "ram_gb": 8,
        "vram_gb": 4,
        "batch_size": 512,  # Optimisé pour la mémoire disponible
        "context_size": 8192,  # Augmenté pour utiliser plus de capacité du modèle
    }
    
    # Configuration llama.cpp
    LLAMA_CONFIG = {
        "model_path": "models/llama-2-7b-chat.gguf",
        "n_ctx": 8192,  # Augmenté pour utiliser plus de capacité
        "n_batch": 512,
        "n_gpu_layers": 20,
        "n_threads": 4,
        "n_threads_batch": 4,
        "rope_freq_base": 10000.0,
        "rope_freq_scale": 1.0,
        "mul_mat_q": True,
        "f16_kv": True,
        "logits_all": False,
        "vocab_only": False,
        "use_mmap": True,
        "use_mlock": False,
        "embedding": False,
        "lora_adapter": "",
        "lora_base": "",
        "n_keep": 0,
        "n_discard": -1,
        "n_predict": -1,
        "n_parallel": 1,
        "repeat_penalty": 1.1,
        "repeat_last_n": 64,
        "penalize_nl": True,
        "temp": 0.8,
        "top_k": 40,
        "top_p": 0.9,
        "tfs_z": 1.0,
        "typical_p": 1.0,
        "mirostat": 0,
        "mirostat_tau": 5.0,
        "mirostat_eta": 0.1,
        "grammar": "",
        "grammar_penalty": 1.0,
        "antiprompt": [],
        "logit_bias": {},
        "stop": ["</s>", "Human:", "Assistant:"],
        "stream": True,
        "seed": -1,
        "ignore_eos": False,
        "no_display_prompt": False,
        "interactive": False,
        "interactive_first": False,
        "multiline_input": False,
        "simple_io": False,
        "color": False,
        "mlock": False,
        "no_mmap": False,
        "mtest": False,
        "verbose_prompt": False,
        "m_eval": 0,
        "ctx_size": 8192,  # Augmenté pour utiliser plus de capacité
        "repeat_penalty": 1.1,
    }
    
    # Configuration API
    API_CONFIG = {
        "host": "0.0.0.0",
        "port": 8000,
        "debug": False,
        "workers": 1,
        "max_requests": 1000,
        "max_requests_jitter": 100,
        "timeout_keep_alive": 30,
    }
    
    # Configuration WebSocket
    WEBSOCKET_CONFIG = {
        "ping_interval": 20,
        "ping_timeout": 20,
        "max_message_size": 1024 * 1024,  # 1MB
    }
    
    # Configuration de sécurité
    SECURITY_CONFIG = {
        "cors_origins": ["*"],
        "cors_methods": ["*"],
        "cors_headers": ["*"],
        "rate_limit": 100,  # Requêtes par minute
        "max_tokens_per_request": 4096,
    }
    
    # Configuration des logs
    LOGGING_CONFIG = {
        "level": "INFO",
        "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        "file": "logs/api.log",
        "max_size": 10 * 1024 * 1024,  # 10MB
        "backup_count": 5,
    }
    
    # Configuration de la mémoire
    MEMORY_CONFIG = {
        "max_conversation_history": 10,
        "max_tokens_per_conversation": 8192,
        "cleanup_interval": 3600,  # 1 heure
    }
    
    # Configuration du modèle
    DEFAULT_MODEL = "llama-2-7b-chat.gguf"
    MODELS_DIR = os.path.dirname(os.path.abspath(__file__))
    MODEL_PATH = os.path.join(MODELS_DIR, DEFAULT_MODEL)

    # Configuration CUDA (désactivée par défaut)
    USE_CUDA = False
    CUDA_LAYERS = 0

    # Configuration de la génération
    MAX_TOKENS = 2048
    TEMPERATURE = 0.7
    TOP_P = 0.9
    TOP_K = 40
    REPEAT_PENALTY = 1.1

    # Configuration du contexte (augmenté pour utiliser plus de capacité)
    CONTEXT_SIZE = 8192  # 8K tokens au lieu de 4K
    
    @classmethod
    def get_llama_args(cls) -> Dict[str, Any]:
        """Retourne les arguments optimisés pour llama.cpp"""
        return cls.LLAMA_CONFIG.copy()
    
    @classmethod
    def get_api_config(cls) -> Dict[str, Any]:
        """Retourne la configuration de l'API"""
        return cls.API_CONFIG.copy()
    
    @classmethod
    def get_hardware_info(cls) -> Dict[str, Any]:
        """Retourne les informations matérielles"""
        return cls.HARDWARE_CONFIG.copy()
    
    @classmethod
    def optimize_for_hardware(cls) -> None:
        """Optimise la configuration en fonction du matériel détecté"""
        import psutil
        
        # Détection automatique du nombre de cœurs CPU
        cpu_count = psutil.cpu_count(logical=False)
        cls.HARDWARE_CONFIG["cpu_threads"] = max(1, cpu_count - 1)  # Garder un cœur libre
        
        # Ajustement de la taille du batch selon la RAM disponible
        ram_gb = psutil.virtual_memory().total / (1024**3)
        if ram_gb < 8:
            cls.HARDWARE_CONFIG["batch_size"] = 256
            cls.HARDWARE_CONFIG["context_size"] = 1024
        elif ram_gb < 16:
            cls.HARDWARE_CONFIG["batch_size"] = 512
            cls.HARDWARE_CONFIG["context_size"] = 2048
        else:
            cls.HARDWARE_CONFIG["batch_size"] = 1024
            cls.HARDWARE_CONFIG["context_size"] = 4096
        
        # Mise à jour de la configuration llama.cpp
        cls.LLAMA_CONFIG["n_threads"] = cls.HARDWARE_CONFIG["cpu_threads"]
        cls.LLAMA_CONFIG["n_batch"] = cls.HARDWARE_CONFIG["batch_size"]
        cls.LLAMA_CONFIG["n_ctx"] = cls.HARDWARE_CONFIG["context_size"]
        cls.LLAMA_CONFIG["n_gpu_layers"] = cls.HARDWARE_CONFIG["gpu_layers"] 