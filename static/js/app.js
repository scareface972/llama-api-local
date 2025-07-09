// Application JavaScript pour l'API Llama.cpp

class LlamaAPI {
    constructor() {
        this.baseURL = window.location.origin;
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.loadSystemInfo();
        this.startStatusCheck();
    }

    setupEventListeners() {
        // Formulaire de chat
        const chatForm = document.getElementById('chatForm');
        if (chatForm) {
            chatForm.addEventListener('submit', (e) => this.handleChatSubmit(e));
        }

        // Formulaire de complétion
        const completionForm = document.getElementById('completionForm');
        if (completionForm) {
            completionForm.addEventListener('submit', (e) => this.handleCompletionSubmit(e));
        }

        // Tabs
        const tabs = document.querySelectorAll('.tab');
        tabs.forEach(tab => {
            tab.addEventListener('click', (e) => this.switchTab(e));
        });

        // Boutons de contrôle
        const startBtn = document.getElementById('startServer');
        const stopBtn = document.getElementById('stopServer');
        const restartBtn = document.getElementById('restartServer');

        if (startBtn) startBtn.addEventListener('click', () => this.controlServer('start'));
        if (stopBtn) stopBtn.addEventListener('click', () => this.controlServer('stop'));
        if (restartBtn) restartBtn.addEventListener('click', () => this.controlServer('restart'));
    }

    async handleChatSubmit(e) {
        e.preventDefault();
        const form = e.target;
        const submitBtn = form.querySelector('button[type="submit"]');
        const responseArea = document.getElementById('chatResponse');

        const formData = new FormData(form);
        const data = {
            messages: [
                {
                    role: "user",
                    content: formData.get('message')
                }
            ],
            model: formData.get('model') || 'default',
            temperature: parseFloat(formData.get('temperature')) || 0.7,
            max_tokens: parseInt(formData.get('max_tokens')) || 1000,
            stream: false
        };

        this.setLoading(submitBtn, true);
        this.clearResponse(responseArea);

        try {
            const response = await fetch(`${this.baseURL}/v1/chat/completions`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(data)
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const result = await response.json();
            this.displayResponse(responseArea, result.choices[0].message.content);
        } catch (error) {
            this.displayError(responseArea, `Erreur: ${error.message}`);
        } finally {
            this.setLoading(submitBtn, false);
        }
    }

    async handleCompletionSubmit(e) {
        e.preventDefault();
        const form = e.target;
        const submitBtn = form.querySelector('button[type="submit"]');
        const responseArea = document.getElementById('completionResponse');

        const formData = new FormData(form);
        const data = {
            prompt: formData.get('prompt'),
            model: formData.get('model') || 'default',
            temperature: parseFloat(formData.get('temperature')) || 0.7,
            max_tokens: parseInt(formData.get('max_tokens')) || 1000,
            stream: false
        };

        this.setLoading(submitBtn, true);
        this.clearResponse(responseArea);

        try {
            const response = await fetch(`${this.baseURL}/v1/completions`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(data)
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const result = await response.json();
            this.displayResponse(responseArea, result.choices[0].text);
        } catch (error) {
            this.displayError(responseArea, `Erreur: ${error.message}`);
        } finally {
            this.setLoading(submitBtn, false);
        }
    }

    async loadSystemInfo() {
        try {
            const response = await fetch(`${this.baseURL}/api/system-info`);
            if (response.ok) {
                const data = await response.json();
                this.updateSystemInfo(data);
            }
        } catch (error) {
            console.error('Erreur lors du chargement des informations système:', error);
        }
    }

    updateSystemInfo(data) {
        const cpuInfo = document.getElementById('cpuInfo');
        const ramInfo = document.getElementById('ramInfo');
        const diskInfo = document.getElementById('diskInfo');
        const modelInfo = document.getElementById('modelInfo');

        if (cpuInfo && data.cpu) {
            cpuInfo.textContent = `${data.cpu.percent}% | ${data.cpu.count} cœurs`;
        }

        if (ramInfo && data.memory) {
            const usedGB = (data.memory.used / 1024 / 1024 / 1024).toFixed(1);
            const totalGB = (data.memory.total / 1024 / 1024 / 1024).toFixed(1);
            ramInfo.textContent = `${usedGB}GB / ${totalGB}GB`;
        }

        if (diskInfo && data.disk) {
            const usedGB = (data.disk.used / 1024 / 1024 / 1024).toFixed(1);
            const totalGB = (data.disk.total / 1024 / 1024 / 1024).toFixed(1);
            diskInfo.textContent = `${usedGB}GB / ${totalGB}GB`;
        }

        if (modelInfo && data.model) {
            modelInfo.textContent = data.model;
        }
    }

    async startStatusCheck() {
        setInterval(async () => {
            try {
                const response = await fetch(`${this.baseURL}/health`);
                const statusIndicator = document.getElementById('serverStatus');
                
                if (response.ok) {
                    this.updateStatus(statusIndicator, 'online', 'Serveur en ligne');
                } else {
                    this.updateStatus(statusIndicator, 'offline', 'Serveur hors ligne');
                }
            } catch (error) {
                const statusIndicator = document.getElementById('serverStatus');
                this.updateStatus(statusIndicator, 'offline', 'Serveur hors ligne');
            }
        }, 5000); // Vérification toutes les 5 secondes
    }

    updateStatus(element, status, text) {
        if (!element) return;

        element.className = `status-indicator status-${status}`;
        element.innerHTML = `
            <span class="status-dot"></span>
            ${text}
        `;
    }

    async controlServer(action) {
        const btn = event.target;
        const originalText = btn.textContent;
        
        this.setLoading(btn, true);
        btn.textContent = `${action === 'start' ? 'Démarrage' : action === 'stop' ? 'Arrêt' : 'Redémarrage'}...`;

        try {
            const response = await fetch(`${this.baseURL}/api/control/${action}`, {
                method: 'POST'
            });

            if (response.ok) {
                this.showAlert('success', `Serveur ${action === 'start' ? 'démarré' : action === 'stop' ? 'arrêté' : 'redémarré'} avec succès`);
                setTimeout(() => this.loadSystemInfo(), 2000);
            } else {
                throw new Error(`Erreur ${response.status}`);
            }
        } catch (error) {
            this.showAlert('error', `Erreur lors du ${action}: ${error.message}`);
        } finally {
            this.setLoading(btn, false);
            btn.textContent = originalText;
        }
    }

    switchTab(e) {
        const targetTab = e.target.getAttribute('data-tab');
        
        // Mettre à jour les tabs
        document.querySelectorAll('.tab').forEach(tab => tab.classList.remove('active'));
        e.target.classList.add('active');
        
        // Mettre à jour le contenu
        document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));
        document.getElementById(targetTab).classList.add('active');
    }

    setLoading(button, loading) {
        if (loading) {
            button.disabled = true;
            button.innerHTML = '<span class="loading"></span> Traitement...';
        } else {
            button.disabled = false;
            button.innerHTML = button.getAttribute('data-original-text') || 'Envoyer';
        }
    }

    clearResponse(area) {
        if (area) {
            area.textContent = '';
            area.style.display = 'none';
        }
    }

    displayResponse(area, content) {
        if (area) {
            area.textContent = content;
            area.style.display = 'block';
        }
    }

    displayError(area, message) {
        if (area) {
            area.textContent = message;
            area.style.display = 'block';
            area.classList.add('error');
        }
    }

    showAlert(type, message) {
        const alertDiv = document.createElement('div');
        alertDiv.className = `alert alert-${type}`;
        alertDiv.textContent = message;
        
        const container = document.querySelector('.container');
        container.insertBefore(alertDiv, container.firstChild);
        
        setTimeout(() => {
            alertDiv.remove();
        }, 5000);
    }
}

// Initialisation de l'application
document.addEventListener('DOMContentLoaded', () => {
    new LlamaAPI();
});

// Fonctions utilitaires
function formatBytes(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

function formatPercentage(value, total) {
    return ((value / total) * 100).toFixed(1) + '%';
} 