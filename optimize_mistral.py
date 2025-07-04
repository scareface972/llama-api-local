#!/usr/bin/env python3
"""
Optimisations spécifiques pour Mistral
"""

import os
import json
import subprocess
import psutil
from typing import Dict, Any

class MistralOptimizer:
    """Optimiseur pour Mistral"""
    
    def __init__(self):
        self.config_file = "config.py"
        self.backup_file = "config_backup.py"
        
    def analyze_system(self) -> Dict[str, Any]:
        """Analyse le système pour optimisations"""
        cpu_count = psutil.cpu_count()
        memory_gb = psutil.virtual_memory().total / (1024**3)
        
        # Détection GPU
        gpu_info = self.detect_gpu()
        
        return {
            "cpu_count": cpu_count,
            "memory_gb": round(memory_gb, 2),
            "gpu_info": gpu_info,
            "recommendations": self.get_recommendations(cpu_count, memory_gb, gpu_info)
        }
    
    def detect_gpu(self) -> Dict[str, Any]:
        """Détecte le GPU disponible"""
        try:
            # Vérification CUDA
            result = subprocess.run(['nvidia-smi', '--query-gpu=name,memory.total,memory.free', '--format=csv,noheader,nounits'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                gpu_info = []
                for line in lines:
                    if line.strip():
                        parts = line.split(', ')
                        if len(parts) >= 3:
                            gpu_info.append({
                                "name": parts[0],
                                "total_memory_mb": int(parts[1]),
                                "free_memory_mb": int(parts[2])
                            })
                return {"type": "cuda", "gpus": gpu_info}
        except:
            pass
        
        # Vérification OpenCL
        try:
            result = subprocess.run(['clinfo'], capture_output=True, text=True)
            if result.returncode == 0:
                return {"type": "opencl", "available": True}
        except:
            pass
        
        return {"type": "cpu_only", "available": False}
    
    def get_recommendations(self, cpu_count: int, memory_gb: float, gpu_info: Dict) -> Dict[str, Any]:
        """Génère des recommandations d'optimisation"""
        recommendations = {
            "model_size": "7B",  # Par défaut
            "context_size": 4096,
            "batch_size": 512,
            "threads": cpu_count,
            "gpu_layers": 0,
            "memory_optimization": "balanced"
        }
        
        # Optimisations basées sur la RAM
        if memory_gb >= 16:
            recommendations["model_size"] = "13B"
            recommendations["context_size"] = 8192
            recommendations["batch_size"] = 1024
        elif memory_gb >= 12:
            recommendations["model_size"] = "7B"
            recommendations["context_size"] = 6144
            recommendations["batch_size"] = 768
        elif memory_gb >= 8:
            recommendations["model_size"] = "7B"
            recommendations["context_size"] = 4096
            recommendations["batch_size"] = 512
        else:
            recommendations["model_size"] = "3B"
            recommendations["context_size"] = 2048
            recommendations["batch_size"] = 256
            recommendations["memory_optimization"] = "aggressive"
        
        # Optimisations GPU
        if gpu_info["type"] == "cuda":
            gpu_memory_gb = sum(gpu["total_memory_mb"] for gpu in gpu_info["gpus"]) / 1024
            if gpu_memory_gb >= 8:
                recommendations["gpu_layers"] = -1  # Toutes les couches
                recommendations["batch_size"] *= 2
            elif gpu_memory_gb >= 4:
                recommendations["gpu_layers"] = 32
                recommendations["batch_size"] = int(recommendations["batch_size"] * 1.5)
            elif gpu_memory_gb >= 2:
                recommendations["gpu_layers"] = 16
            else:
                recommendations["gpu_layers"] = 8
        
        # Optimisations CPU
        if cpu_count >= 8:
            recommendations["threads"] = cpu_count - 1
        elif cpu_count >= 4:
            recommendations["threads"] = cpu_count
        else:
            recommendations["threads"] = cpu_count
            recommendations["batch_size"] = max(128, recommendations["batch_size"] // 2)
        
        return recommendations
    
    def create_optimized_config(self, recommendations: Dict[str, Any]):
        """Crée une configuration optimisée"""
        
        # Sauvegarde de la config actuelle
        if os.path.exists(self.config_file):
            os.rename(self.config_file, self.backup_file)
        
        config_content = f'''#!/usr/bin/env python3
"""
Configuration optimisée pour Mistral
Générée automatiquement par MistralOptimizer
"""

import os
import psutil

class Config:
    """Configuration optimisée pour Mistral"""
    
    # Configuration matérielle
    HARDWARE_CONFIG = {{
        "cpu_count": {recommendations['threads']},
        "memory_gb": {psutil.virtual_memory().total / (1024**3):.1f},
        "gpu_layers": {recommendations['gpu_layers']},
        "batch_size": {recommendations['batch_size']},
        "context_size": {recommendations['context_size']}
    }}
    
    # Configuration Llama.cpp optimisée
    LLAMA_CONFIG = {{
        "model_path": "models/mistral-{recommendations['model_size']}-instruct-v0.2.Q4_K_M.gguf",
        "n_ctx": {recommendations['context_size']},
        "n_batch": {recommendations['batch_size']},
        "n_gpu_layers": {recommendations['gpu_layers']},
        "n_threads": {recommendations['threads']},
        "n_threads_batch": {recommendations['threads']},
        "rope_freq_base": 10000.0,
        "rope_freq_scale": 1.0,
        "mul_mat_q": True,
        "f16_kv": True,
        "logits_all": False,
        "vocab_only": False,
        "use_mmap": True,
        "use_mlock": False,
        "embedding": False,
        "lora_adapter": None,
        "lora_base": None,
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
        "grammar": None,
        "grammar_penalty": 1.0,
        "antiprompt": [],
        "logit_bias": None,
        "stop": ["</s>", "[/INST]", "[INST]"],
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
    }}
    
    # Configuration API
    API_CONFIG = {{
        "host": "0.0.0.0",
        "port": 8000,
        "debug": False,
        "workers": 1,
        "max_requests": 100,
        "timeout": 300
    }}
    
    # Configuration de sécurité
    SECURITY_CONFIG = {{
        "cors_origins": ["*"],
        "cors_methods": ["GET", "POST", "PUT", "DELETE"],
        "cors_headers": ["*"],
        "rate_limit": 100,
        "rate_limit_window": 3600
    }}
    
    # Configuration de logging
    LOGGING_CONFIG = {{
        "level": "INFO",
        "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        "file": "logs/llama_api.log",
        "max_size": "10MB",
        "backup_count": 5
    }}
    
    # Optimisations mémoire
    MEMORY_CONFIG = {{
        "optimization_level": "{recommendations['memory_optimization']}",
        "enable_mmap": True,
        "enable_mlock": False,
        "gpu_memory_fraction": 0.8,
        "cpu_memory_fraction": 0.7
    }}
    
    @classmethod
    def optimize_for_hardware(cls):
        """Optimise la configuration pour le matériel"""
        # Ajustements automatiques basés sur le matériel
        memory_gb = psutil.virtual_memory().total / (1024**3)
        
        if memory_gb < 8:
            # Mode économique
            cls.LLAMA_CONFIG["n_batch"] = max(128, cls.LLAMA_CONFIG["n_batch"] // 2)
            cls.LLAMA_CONFIG["n_ctx"] = min(2048, cls.LLAMA_CONFIG["n_ctx"])
            cls.MEMORY_CONFIG["gpu_memory_fraction"] = 0.6
        elif memory_gb >= 16:
            # Mode performance
            cls.LLAMA_CONFIG["n_batch"] = min(2048, cls.LLAMA_CONFIG["n_batch"] * 2)
            cls.LLAMA_CONFIG["n_ctx"] = min(16384, cls.LLAMA_CONFIG["n_ctx"] * 2)
            cls.MEMORY_CONFIG["gpu_memory_fraction"] = 0.9
    
    @classmethod
    def get_llama_args(cls) -> dict:
        """Retourne les arguments pour llama.cpp"""
        return cls.LLAMA_CONFIG
    
    @classmethod
    def get_api_config(cls) -> dict:
        """Retourne la configuration API"""
        return cls.API_CONFIG
    
    @classmethod
    def get_hardware_info(cls) -> dict:
        """Retourne les informations matérielles"""
        return cls.HARDWARE_CONFIG
'''
        
        with open(self.config_file, 'w') as f:
            f.write(config_content)
        
        print(f"✅ Configuration optimisée créée: {self.config_file}")
        print(f"📋 Recommandations appliquées:")
        for key, value in recommendations.items():
            print(f"   • {key}: {value}")
    
    def download_optimized_model(self, model_size: str = "7B"):
        """Télécharge le modèle Mistral optimisé"""
        models_dir = "models"
        os.makedirs(models_dir, exist_ok=True)
        
        model_urls = {
            "3B": "https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf",
            "7B": "https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf",
            "13B": "https://huggingface.co/TheBloke/Mistral-13B-Instruct-v0.2-GGUF/resolve/main/mistral-13b-instruct-v0.2.Q4_K_M.gguf"
        }
        
        if model_size not in model_urls:
            print(f"❌ Taille de modèle non supportée: {model_size}")
            return False
        
        model_url = model_urls[model_size]
        model_filename = f"mistral-{model_size}-instruct-v0.2.Q4_K_M.gguf"
        model_path = os.path.join(models_dir, model_filename)
        
        if os.path.exists(model_path):
            print(f"✅ Modèle déjà présent: {model_path}")
            return True
        
        print(f"📥 Téléchargement du modèle {model_size}...")
        print(f"🔗 URL: {model_url}")
        
        try:
            import requests
            response = requests.get(model_url, stream=True)
            response.raise_for_status()
            
            total_size = int(response.headers.get('content-length', 0))
            downloaded = 0
            
            with open(model_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
                        downloaded += len(chunk)
                        if total_size > 0:
                            percent = (downloaded / total_size) * 100
                            print(f"📊 Progression: {percent:.1f}%", end='\\r')
            
            print(f"\\n✅ Modèle téléchargé: {model_path}")
            return True
            
        except Exception as e:
            print(f"❌ Erreur lors du téléchargement: {e}")
            return False
    
    def create_optimization_script(self):
        """Crée un script d'optimisation"""
        script_content = '''#!/bin/bash
# Script d'optimisation Mistral

echo "🚀 Optimisation Mistral pour votre système..."

# Analyse du système
python3 optimize_mistral.py --analyze

# Création de la configuration optimisée
python3 optimize_mistral.py --optimize

# Téléchargement du modèle recommandé
python3 optimize_mistral.py --download

echo "✅ Optimisation terminée !"
echo "🔄 Redémarrez le serveur pour appliquer les changements"
'''
        
        with open("optimize_mistral.sh", 'w') as f:
            f.write(script_content)
        
        os.chmod("optimize_mistral.sh", 0o755)
        print("✅ Script d'optimisation créé: optimize_mistral.sh")

def main():
    """Fonction principale"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Optimiseur Mistral")
    parser.add_argument("--analyze", action="store_true", help="Analyse le système")
    parser.add_argument("--optimize", action="store_true", help="Crée une configuration optimisée")
    parser.add_argument("--download", action="store_true", help="Télécharge le modèle recommandé")
    parser.add_argument("--all", action="store_true", help="Exécute toutes les optimisations")
    
    args = parser.parse_args()
    
    optimizer = MistralOptimizer()
    
    if args.analyze or args.all:
        print("🔍 Analyse du système...")
        analysis = optimizer.analyze_system()
        print(json.dumps(analysis, indent=2))
    
    if args.optimize or args.all:
        print("⚙️ Création de la configuration optimisée...")
        analysis = optimizer.analyze_system()
        optimizer.create_optimized_config(analysis["recommendations"])
        optimizer.create_optimization_script()
    
    if args.download or args.all:
        print("📥 Téléchargement du modèle...")
        analysis = optimizer.analyze_system()
        model_size = analysis["recommendations"]["model_size"]
        optimizer.download_optimized_model(model_size)

if __name__ == "__main__":
    main() 