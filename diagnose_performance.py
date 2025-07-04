#!/usr/bin/env python3
"""
Diagnostic de performance pour Mistral
"""

import os
import sys
import time
import json
import psutil
import subprocess
from pathlib import Path
from typing import Dict, Any, List

class PerformanceDiagnostic:
    """Diagnostic de performance pour Mistral"""
    
    def __init__(self):
        self.logs_dir = Path("logs")
        self.models_dir = Path("models")
        
    def run_full_diagnostic(self) -> Dict[str, Any]:
        """Exécute un diagnostic complet"""
        print("🔍 Diagnostic complet de performance Mistral...")
        
        results = {
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "system_info": self.get_system_info(),
            "model_info": self.get_model_info(),
            "performance_analysis": self.analyze_performance(),
            "optimization_recommendations": self.get_optimization_recommendations(),
            "logs_analysis": self.analyze_logs(),
            "issues": self.detect_issues()
        }
        
        return results
    
    def get_system_info(self) -> Dict[str, Any]:
        """Récupère les informations système"""
        print("📊 Collecte des informations système...")
        
        # CPU
        cpu_info = {
            "count": psutil.cpu_count(),
            "count_logical": psutil.cpu_count(logical=True),
            "percent": psutil.cpu_percent(interval=1),
            "freq": psutil.cpu_freq()._asdict() if psutil.cpu_freq() else None
        }
        
        # Mémoire
        memory = psutil.virtual_memory()
        memory_info = {
            "total_gb": round(memory.total / (1024**3), 2),
            "available_gb": round(memory.available / (1024**3), 2),
            "used_gb": round(memory.used / (1024**3), 2),
            "percent": memory.percent
        }
        
        # Disque
        disk = psutil.disk_usage('/')
        disk_info = {
            "total_gb": round(disk.total / (1024**3), 2),
            "free_gb": round(disk.free / (1024**3), 2),
            "used_gb": round(disk.used / (1024**3), 2),
            "percent": disk.percent
        }
        
        # GPU
        gpu_info = self.detect_gpu()
        
        return {
            "cpu": cpu_info,
            "memory": memory_info,
            "disk": disk_info,
            "gpu": gpu_info
        }
    
    def detect_gpu(self) -> Dict[str, Any]:
        """Détecte le GPU"""
        try:
            result = subprocess.run(['nvidia-smi', '--query-gpu=name,memory.total,memory.used,memory.free,temperature.gpu,utilization.gpu', '--format=csv,noheader,nounits'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                gpus = []
                for line in lines:
                    if line.strip():
                        parts = line.split(', ')
                        if len(parts) >= 6:
                            gpus.append({
                                "name": parts[0],
                                "memory_total_mb": int(parts[1]),
                                "memory_used_mb": int(parts[2]),
                                "memory_free_mb": int(parts[3]),
                                "temperature": int(parts[4]),
                                "utilization": int(parts[5])
                            })
                return {"type": "cuda", "gpus": gpus}
        except:
            pass
        
        return {"type": "cpu_only", "available": False}
    
    def get_model_info(self) -> Dict[str, Any]:
        """Récupère les informations sur le modèle"""
        print("📦 Analyse des modèles...")
        
        if not self.models_dir.exists():
            return {"error": "Dossier models non trouvé"}
        
        models = []
        total_size_gb = 0
        
        for model_file in self.models_dir.glob("*.gguf"):
            size_mb = model_file.stat().st_size / (1024 * 1024)
            size_gb = size_mb / 1024
            total_size_gb += size_gb
            
            models.append({
                "name": model_file.name,
                "size_mb": round(size_mb, 2),
                "size_gb": round(size_gb, 2),
                "modified": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(model_file.stat().st_mtime))
            })
        
        return {
            "models": models,
            "total_size_gb": round(total_size_gb, 2),
            "count": len(models)
        }
    
    def analyze_performance(self) -> Dict[str, Any]:
        """Analyse les performances depuis les logs"""
        print("📈 Analyse des performances...")
        
        if not self.logs_dir.exists():
            return {"error": "Dossier logs non trouvé"}
        
        perf_file = self.logs_dir / "performance.log"
        if not perf_file.exists():
            return {"error": "Fichier de performance non trouvé"}
        
        # Analyse des logs de performance
        response_times = []
        tokens_list = []
        requests_per_hour = {}
        
        try:
            with open(perf_file, 'r') as f:
                for line in f:
                    if 'PERF' in line and 'ResponseTime:' in line and 'Tokens:' in line:
                        try:
                            # Extraction des données
                            parts = line.split('ResponseTime:')[1].split(' - Tokens:')
                            response_time = float(parts[0])
                            tokens = int(parts[1])
                            
                            response_times.append(response_time)
                            tokens_list.append(tokens)
                            
                            # Comptage par heure
                            hour = line.split(' - ')[0][:13]  # YYYY-MM-DD HH
                            requests_per_hour[hour] = requests_per_hour.get(hour, 0) + 1
                            
                        except:
                            continue
        except Exception as e:
            return {"error": f"Erreur lors de l'analyse: {e}"}
        
        if not response_times:
            return {"error": "Aucune donnée de performance trouvée"}
        
        # Calculs statistiques
        avg_response_time = sum(response_times) / len(response_times)
        min_response_time = min(response_times)
        max_response_time = max(response_times)
        
        avg_tokens = sum(tokens_list) / len(tokens_list) if tokens_list else 0
        total_tokens = sum(tokens_list)
        
        # Tokens par seconde
        tokens_per_second = total_tokens / sum(response_times) if sum(response_times) > 0 else 0
        
        return {
            "total_requests": len(response_times),
            "avg_response_time": round(avg_response_time, 3),
            "min_response_time": round(min_response_time, 3),
            "max_response_time": round(max_response_time, 3),
            "avg_tokens_per_request": round(avg_tokens, 1),
            "total_tokens": total_tokens,
            "tokens_per_second": round(tokens_per_second, 1),
            "requests_per_hour": requests_per_hour,
            "performance_distribution": self.get_performance_distribution(response_times)
        }
    
    def get_performance_distribution(self, response_times: List[float]) -> Dict[str, int]:
        """Calcule la distribution des temps de réponse"""
        distribution = {
            "fast": 0,      # < 1s
            "normal": 0,    # 1-3s
            "slow": 0,      # 3-10s
            "very_slow": 0  # > 10s
        }
        
        for time in response_times:
            if time < 1:
                distribution["fast"] += 1
            elif time < 3:
                distribution["normal"] += 1
            elif time < 10:
                distribution["slow"] += 1
            else:
                distribution["very_slow"] += 1
        
        return distribution
    
    def analyze_logs(self) -> Dict[str, Any]:
        """Analyse les logs d'erreurs et système"""
        print("📋 Analyse des logs...")
        
        if not self.logs_dir.exists():
            return {"error": "Dossier logs non trouvé"}
        
        analysis = {
            "errors": [],
            "system_issues": [],
            "model_issues": []
        }
        
        # Analyse des erreurs
        error_file = self.logs_dir / "errors.log"
        if error_file.exists():
            try:
                with open(error_file, 'r') as f:
                    for line in f:
                        if 'ERROR' in line:
                            analysis["errors"].append(line.strip())
            except:
                pass
        
        # Analyse système
        system_file = self.logs_dir / "system.log"
        if system_file.exists():
            try:
                with open(system_file, 'r') as f:
                    for line in f:
                        if 'memory_percent' in line and '> 90' in line:
                            analysis["system_issues"].append("Mémoire élevée détectée")
                        elif 'cpu_percent' in line and '> 95' in line:
                            analysis["system_issues"].append("CPU élevé détecté")
            except:
                pass
        
        return analysis
    
    def detect_issues(self) -> List[Dict[str, Any]]:
        """Détecte les problèmes potentiels"""
        print("⚠️ Détection des problèmes...")
        
        issues = []
        
        # Vérification de la mémoire
        memory = psutil.virtual_memory()
        if memory.percent > 90:
            issues.append({
                "type": "memory",
                "severity": "high",
                "message": f"Mémoire utilisée à {memory.percent}%",
                "recommendation": "Réduire la taille du contexte ou du batch"
            })
        elif memory.percent > 80:
            issues.append({
                "type": "memory",
                "severity": "medium",
                "message": f"Mémoire utilisée à {memory.percent}%",
                "recommendation": "Surveiller l'utilisation mémoire"
            })
        
        # Vérification du disque
        disk = psutil.disk_usage('/')
        if disk.percent > 90:
            issues.append({
                "type": "disk",
                "severity": "high",
                "message": f"Espace disque utilisé à {disk.percent}%",
                "recommendation": "Libérer de l'espace disque"
            })
        
        # Vérification des modèles
        if not self.models_dir.exists() or not list(self.models_dir.glob("*.gguf")):
            issues.append({
                "type": "model",
                "severity": "high",
                "message": "Aucun modèle GGUF trouvé",
                "recommendation": "Télécharger un modèle Mistral"
            })
        
        # Vérification des performances
        perf_analysis = self.analyze_performance()
        if "error" not in perf_analysis:
            avg_time = perf_analysis.get("avg_response_time", 0)
            if avg_time > 10:
                issues.append({
                    "type": "performance",
                    "severity": "high",
                    "message": f"Temps de réponse moyen élevé: {avg_time}s",
                    "recommendation": "Optimiser la configuration ou réduire la taille du modèle"
                })
            elif avg_time > 5:
                issues.append({
                    "type": "performance",
                    "severity": "medium",
                    "message": f"Temps de réponse moyen: {avg_time}s",
                    "recommendation": "Considérer des optimisations"
                })
        
        return issues
    
    def get_optimization_recommendations(self) -> List[Dict[str, Any]]:
        """Génère des recommandations d'optimisation"""
        print("💡 Génération des recommandations...")
        
        recommendations = []
        
        # Analyse du système
        system_info = self.get_system_info()
        memory_gb = system_info["memory"]["total_gb"]
        cpu_count = system_info["cpu"]["count"]
        gpu_info = system_info["gpu"]
        
        # Recommandations basées sur la RAM
        if memory_gb < 8:
            recommendations.append({
                "category": "memory",
                "priority": "high",
                "title": "Optimisation mémoire",
                "description": f"Seulement {memory_gb}GB de RAM disponible",
                "actions": [
                    "Utiliser un modèle 3B au lieu de 7B",
                    "Réduire n_ctx à 2048",
                    "Réduire n_batch à 256",
                    "Activer use_mlock=False"
                ]
            })
        elif memory_gb < 12:
            recommendations.append({
                "category": "memory",
                "priority": "medium",
                "title": "Optimisation mémoire modérée",
                "description": f"{memory_gb}GB de RAM - configuration équilibrée",
                "actions": [
                    "Utiliser un modèle 7B Q4_K_M",
                    "n_ctx = 4096",
                    "n_batch = 512"
                ]
            })
        else:
            recommendations.append({
                "category": "performance",
                "priority": "low",
                "title": "Optimisation performance",
                "description": f"{memory_gb}GB de RAM - possibilité d'amélioration",
                "actions": [
                    "Utiliser un modèle 13B si possible",
                    "Augmenter n_ctx à 8192",
                    "Augmenter n_batch à 1024"
                ]
            })
        
        # Recommandations GPU
        if gpu_info["type"] == "cuda":
            gpu_memory_gb = sum(gpu["memory_total_mb"] for gpu in gpu_info["gpus"]) / 1024
            if gpu_memory_gb >= 4:
                recommendations.append({
                    "category": "gpu",
                    "priority": "high",
                    "title": "Optimisation GPU",
                    "description": f"GPU CUDA avec {gpu_memory_gb:.1f}GB VRAM",
                    "actions": [
                        "Activer n_gpu_layers=32",
                        "Augmenter n_batch de 50%",
                        "Utiliser f16_kv=True"
                    ]
                })
        
        # Recommandations CPU
        if cpu_count >= 8:
            recommendations.append({
                "category": "cpu",
                "priority": "medium",
                "title": "Optimisation CPU",
                "description": f"{cpu_count} cœurs CPU disponibles",
                "actions": [
                    f"Utiliser n_threads={cpu_count-1}",
                    f"Utiliser n_threads_batch={cpu_count-1}",
                    "Activer mul_mat_q=True"
                ]
            })
        
        return recommendations
    
    def generate_report(self, results: Dict[str, Any], output_file: str = "performance_report.json"):
        """Génère un rapport de diagnostic"""
        print(f"📄 Génération du rapport: {output_file}")
        
        with open(output_file, 'w') as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
        
        # Affichage du résumé
        print("\n" + "="*60)
        print("📊 RÉSUMÉ DU DIAGNOSTIC")
        print("="*60)
        
        # Système
        system = results["system_info"]
        print(f"💻 Système: {system['cpu']['count']} cœurs, {system['memory']['total_gb']}GB RAM")
        if system['gpu']['type'] == 'cuda':
            gpu_name = system['gpu']['gpus'][0]['name']
            print(f"🎮 GPU: {gpu_name}")
        else:
            print("🎮 GPU: CPU uniquement")
        
        # Modèles
        models = results["model_info"]
        if "error" not in models:
            print(f"📦 Modèles: {models['count']} ({models['total_size_gb']}GB total)")
        
        # Performance
        perf = results["performance_analysis"]
        if "error" not in perf:
            print(f"⚡ Performance: {perf['avg_response_time']}s moyen, {perf['tokens_per_second']} tokens/s")
        
        # Problèmes
        issues = results["issues"]
        if issues:
            print(f"⚠️ Problèmes détectés: {len(issues)}")
            for issue in issues[:3]:  # Afficher les 3 premiers
                print(f"   • {issue['message']}")
        else:
            print("✅ Aucun problème détecté")
        
        # Recommandations
        recommendations = results["optimization_recommendations"]
        if recommendations:
            print(f"💡 Recommandations: {len(recommendations)}")
            for rec in recommendations[:2]:  # Afficher les 2 premières
                print(f"   • {rec['title']}")
        
        print("="*60)

def main():
    """Fonction principale"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Diagnostic de performance Mistral")
    parser.add_argument("--output", "-o", default="performance_report.json", 
                       help="Fichier de sortie pour le rapport")
    parser.add_argument("--quick", "-q", action="store_true", 
                       help="Diagnostic rapide (sans analyse des logs)")
    
    args = parser.parse_args()
    
    diagnostic = PerformanceDiagnostic()
    
    if args.quick:
        print("🔍 Diagnostic rapide...")
        results = {
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "system_info": diagnostic.get_system_info(),
            "model_info": diagnostic.get_model_info(),
            "issues": diagnostic.detect_issues(),
            "optimization_recommendations": diagnostic.get_optimization_recommendations()
        }
    else:
        results = diagnostic.run_full_diagnostic()
    
    diagnostic.generate_report(results, args.output)
    
    print(f"\n✅ Diagnostic terminé. Rapport sauvegardé: {args.output}")

if __name__ == "__main__":
    main() 