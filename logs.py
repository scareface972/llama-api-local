#!/usr/bin/env python3
"""
Système de logs avancé pour l'API Llama.cpp
"""

import logging
import time
import psutil
import os
from datetime import datetime
from typing import Dict, Any, Optional
from pathlib import Path

class PerformanceLogger:
    """Logger spécialisé pour les performances"""
    
    def __init__(self, log_dir: str = "logs"):
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(exist_ok=True)
        
        # Configuration des logs
        self.setup_loggers()
        
    def setup_loggers(self):
        """Configure les différents loggers"""
        
        # Logger principal
        self.main_logger = logging.getLogger('llama_api')
        self.main_logger.setLevel(logging.INFO)
        
        # Handler pour fichier principal
        main_handler = logging.FileHandler(self.log_dir / 'api.log')
        main_handler.setLevel(logging.INFO)
        main_formatter = logging.Formatter(
            '%(asctime)s - %(levelname)s - %(message)s'
        )
        main_handler.setFormatter(main_formatter)
        self.main_logger.addHandler(main_handler)
        
        # Logger de performance
        self.perf_logger = logging.getLogger('performance')
        self.perf_logger.setLevel(logging.INFO)
        
        # Handler pour performances
        perf_handler = logging.FileHandler(self.log_dir / 'performance.log')
        perf_handler.setLevel(logging.INFO)
        perf_formatter = logging.Formatter(
            '%(asctime)s - %(message)s'
        )
        perf_handler.setFormatter(perf_formatter)
        self.perf_logger.addHandler(perf_handler)
        
        # Logger d'erreurs
        self.error_logger = logging.getLogger('errors')
        self.error_logger.setLevel(logging.ERROR)
        
        # Handler pour erreurs
        error_handler = logging.FileHandler(self.log_dir / 'errors.log')
        error_handler.setLevel(logging.ERROR)
        error_formatter = logging.Formatter(
            '%(asctime)s - %(levelname)s - %(message)s\n%(exc_info)s\n'
        )
        error_handler.setFormatter(error_formatter)
        self.error_logger.addHandler(error_handler)
        
        # Logger système
        self.system_logger = logging.getLogger('system')
        self.system_logger.setLevel(logging.INFO)
        
        # Handler pour système
        system_handler = logging.FileHandler(self.log_dir / 'system.log')
        system_handler.setLevel(logging.INFO)
        system_formatter = logging.Formatter(
            '%(asctime)s - %(message)s'
        )
        system_handler.setFormatter(system_formatter)
        self.system_logger.addHandler(system_handler)
    
    def log_request_start(self, request_id: str, user_message: str, model: str):
        """Log le début d'une requête"""
        self.main_logger.info(f"🚀 REQUEST_START [{request_id}] - Modèle: {model}")
        self.main_logger.info(f"📝 Message utilisateur: {user_message[:100]}...")
        
        # Log système avant génération
        self.log_system_status(request_id, "before_generation")
    
    def log_request_end(self, request_id: str, response_time: float, tokens_generated: int):
        """Log la fin d'une requête"""
        self.main_logger.info(f"✅ REQUEST_END [{request_id}] - Temps: {response_time:.2f}s - Tokens: {tokens_generated}")
        
        # Log performance
        self.perf_logger.info(f"PERF [{request_id}] - ResponseTime:{response_time:.3f}s - Tokens:{tokens_generated}")
        
        # Log système après génération
        self.log_system_status(request_id, "after_generation")
    
    def log_system_status(self, request_id: str, stage: str):
        """Log l'état du système"""
        try:
            cpu_percent = psutil.cpu_percent(interval=0.1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            
            status = {
                "request_id": request_id,
                "stage": stage,
                "timestamp": datetime.now().isoformat(),
                "cpu_percent": cpu_percent,
                "memory_percent": memory.percent,
                "memory_used_gb": round(memory.used / (1024**3), 2),
                "memory_total_gb": round(memory.total / (1024**3), 2),
                "disk_percent": disk.percent,
                "disk_free_gb": round(disk.free / (1024**3), 2)
            }
            
            self.system_logger.info(f"SYSTEM_STATUS - {status}")
            
        except Exception as e:
            self.error_logger.error(f"Erreur lors du log système: {e}")
    
    def log_error(self, request_id: str, error: Exception, context: str = ""):
        """Log une erreur"""
        self.error_logger.error(
            f"❌ ERROR [{request_id}] - {context} - {str(error)}",
            exc_info=True
        )
    
    def log_model_load(self, model_path: str, load_time: float):
        """Log le chargement du modèle"""
        self.main_logger.info(f"📦 MODEL_LOAD - {model_path} - Temps: {load_time:.2f}s")
        self.perf_logger.info(f"MODEL_LOAD - LoadTime:{load_time:.3f}s - Path:{model_path}")
    
    def log_configuration(self, config: Dict[str, Any]):
        """Log la configuration utilisée"""
        self.main_logger.info(f"⚙️ CONFIG - {config}")
    
    def get_performance_stats(self, hours: int = 24) -> Dict[str, Any]:
        """Récupère les statistiques de performance"""
        try:
            perf_file = self.log_dir / 'performance.log'
            if not perf_file.exists():
                return {"error": "Fichier de performance non trouvé"}
            
            stats = {
                "total_requests": 0,
                "avg_response_time": 0,
                "total_tokens": 0,
                "requests_per_hour": 0
            }
            
            response_times = []
            tokens_list = []
            
            with open(perf_file, 'r') as f:
                for line in f:
                    if 'PERF' in line:
                        stats["total_requests"] += 1
                        
                        # Extraction des données
                        if 'ResponseTime:' in line and 'Tokens:' in line:
                            try:
                                parts = line.split('ResponseTime:')[1].split(' - Tokens:')
                                response_time = float(parts[0])
                                tokens = int(parts[1])
                                
                                response_times.append(response_time)
                                tokens_list.append(tokens)
                                stats["total_tokens"] += tokens
                            except:
                                continue
            
            if response_times:
                stats["avg_response_time"] = sum(response_times) / len(response_times)
                stats["min_response_time"] = min(response_times)
                stats["max_response_time"] = max(response_times)
            
            if tokens_list:
                stats["avg_tokens_per_request"] = sum(tokens_list) / len(tokens_list)
            
            # Calcul des requêtes par heure
            stats["requests_per_hour"] = stats["total_requests"] / hours
            
            return stats
            
        except Exception as e:
            return {"error": f"Erreur lors du calcul des stats: {e}"}

# Instance globale
performance_logger = PerformanceLogger() 