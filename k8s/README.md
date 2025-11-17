# Manifests Kubernetes - Vehicle Resale API

Este diretório contém todos os manifestos Kubernetes para deploy da aplicação Vehicle Resale API.

## 📁 Estrutura de Diretórios

```
k8s/
├── base/                    # Manifestos base (Kustomize)
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── postgres-*           # Recursos do PostgreSQL
│   ├── init-data-*          # Job para inicializar dados
│   └── kustomization.yaml
│
├── overlays/                # Configurações por ambiente
│   ├── local/               # Deploy local (Minikube)
│   │   ├── kustomization.yaml
│   │   ├── *-patch.yaml
│   │   ├── deploy-minikube.sh
│   │   └── QUICKSTART.md
│   ├── aws/                 # Deploy AWS EKS
│   │   ├── kustomization.yaml
│   │   ├── *-patch.yaml
│   │   ├── storageclass.yaml
│   │   └── deploy.sh
│   ├── azure/               # Deploy Azure AKS
│   │   └── ...
│   └── gcp/                 # Deploy GCP GKE
│       └── ...
│
├── demos/                   # Demonstrações de estratégias
│   ├── canary/              # Canary Deployment
│   │   ├── deployment-v1.yaml
│   │   ├── deployment-v2-canary.yaml
│   │   ├── service.yaml
│   │   └── demo-canary.sh
│   ├── ab-testing/          # A/B Testing
│   │   ├── deployment-version-a.yaml
│   │   ├── deployment-version-b.yaml
│   │   ├── service-version-*.yaml
│   │   ├── ingress-ab.yaml
│   │   └── demo-ab.sh
│   ├── README.md
│   └── QUICKSTART_DEMOS.md
│
└── scripts/                 # Scripts utilitários
    ├── port-forward.sh      # Port-forward inteligente
    ├── monitor-hpa.sh       # Monitorar HPA
    ├── load-test.sh         # Gerador de carga
    └── demo-autoscaling.sh  # Demo de auto-scaling

```

## 🎯 Propósito de Cada Diretório

### 📦 `base/`

**Manifestos base compartilhados por todos os ambientes.**

Contém a definição completa da aplicação sem configurações específicas de ambiente. Usa Kustomize para permitir customização por ambiente.

**Recursos incluídos:**
- ✅ Namespace
- ✅ ConfigMaps (aplicação e PostgreSQL)
- ✅ Secrets
- ✅ Deployment (API)
- ✅ Deployment (PostgreSQL)
- ✅ Services
- ✅ Ingress
- ✅ PersistentVolumeClaim
- ✅ Job de inicialização de dados

### 🔧 `overlays/`

**Configurações específicas por ambiente.**

Cada subdiretório contém patches e configurações para um ambiente específico:

#### `local/` - Minikube
- StorageClass: `standard` (padrão do Minikube)
- ImagePullPolicy: `Never` (usa imagens locais)
- Script automatizado: `deploy-minikube.sh`
- HPA configurado para demonstração

#### `aws/` - Amazon EKS
- StorageClass: `gp2` (EBS)
- ALB Ingress Controller
- Prometheus annotations

#### `azure/` - Azure AKS
- StorageClass: `managed-premium` (Azure Disk)
- Application Gateway Ingress Controller
- Azure-specific configurations

#### `gcp/` - Google GKE
- StorageClass: `pd-ssd` (Persistent Disk)
- GKE Ingress
- BackendConfig

### 🎓 `demos/`

**Demonstrações de estratégias avançadas de deployment.**

#### `canary/` - Canary Deployment
Deploy gradual de nova versão:
- V1 (100%) → V2 (10%) → V2 (50%) → V2 (100%)
- Rollback rápido
- Ideal para deploys seguros

#### `ab-testing/` - A/B Testing
Roteamento inteligente para experimentos:
- Versão A (controle) vs Versão B (experimental)
- Roteamento por header ou cookie
- Ideal para testes de features

### 🛠️ `scripts/`

**Scripts utilitários para operação.**

- `port-forward.sh` - Port-forward com detecção de porta ocupada
- `monitor-hpa.sh` - Monitoramento de Horizontal Pod Autoscaler
- `load-test.sh` - Gerador de carga para testes
- `demo-autoscaling.sh` - Demonstração de auto-scaling

## 🚀 Como Usar

### Deploy Local (Minikube)

#### Opção 1: Script Automatizado (Recomendado)
```bash
cd overlays/local
./deploy-minikube.sh
```

#### Opção 2: Kustomize Manual
```bash
# 1. Configurar ambiente Docker do Minikube
eval $(minikube docker-env)

# 2. Compilar e construir imagem
mvn clean package -DskipTests
docker build -t vehicle-resale-api:1.0.0 .

# 3. Aplicar manifestos
cd overlays/local
kubectl apply -k .
```

### Deploy AWS

```bash
cd overlays/aws
./deploy.sh
```

### Deploy Azure

```bash
cd overlays/azure
kubectl apply -k .
```

### Deploy GCP

```bash
cd overlays/gcp
kubectl apply -k .
```

### Demonstrações

#### Canary Deployment
```bash
cd demos/canary
./demo-canary.sh
```

#### A/B Testing
```bash
cd demos/ab-testing
./demo-ab.sh
```

## 📖 Documentação Adicional

- **`overlays/local/QUICKSTART.md`** - Guia rápido para deploy local
- **`demos/README.md`** - Documentação completa de estratégias de deployment
- **`demos/QUICKSTART_DEMOS.md`** - Guia rápido das demonstrações

## 🔍 Verificar Status

```bash
# Ver todos os recursos
kubectl get all -n vehicle-resale

# Ver pods
kubectl get pods -n vehicle-resale

# Ver logs
kubectl logs -f -n vehicle-resale -l app=vehicle-resale-api

# Ver eventos
kubectl get events -n vehicle-resale --sort-by='.lastTimestamp'
```

## 🌐 Acessar a Aplicação

### Via Port-Forward (Mais Simples)
```bash
kubectl port-forward -n vehicle-resale service/local-vehicle-resale-api-service 8082:80

# Acessar
http://localhost:8082
http://localhost:8082/swagger-ui
```

### Via Ingress
```bash
# Obter IP (Minikube)
minikube ip

# Adicionar ao /etc/hosts
echo "$(minikube ip) vehicle-resale-api.local" | sudo tee -a /etc/hosts

# Acessar
http://vehicle-resale-api.local
```

## 🗑️ Remover Deploy

```bash
# Remover namespace (remove tudo)
kubectl delete namespace vehicle-resale

# Ou remover com Kustomize
cd overlays/local
kubectl delete -k .
```

## 🏗️ Arquitetura Kubernetes

```
┌─────────────────────────────────────────────────────────────┐
│  NGINX Ingress Controller                                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  vehicle-resale-api.local                           │   │
│  └─────────────────┬───────────────────────────────────┘   │
└────────────────────┼─────────────────────────────────────────┘
                     │
                     ▼
     ┌───────────────────────────────────┐
     │  Service: vehicle-resale-api      │
     │  Type: ClusterIP                  │
     │  Port: 80 → TargetPort: 8082      │
     └───────────────┬───────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌──────────────┐          ┌──────────────┐
│  Pod 1       │          │  Pod 2       │
│  API v1.0.0  │          │  API v1.0.0  │
│  Port: 8082  │          │  Port: 8082  │
└──────┬───────┘          └──────┬───────┘
       │                         │
       │     ┌───────────────────┘
       │     │
       ▼     ▼
  ┌─────────────────┐
  │  PostgreSQL     │
  │  Service        │
  │  Port: 5432     │
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │  PostgreSQL Pod │
  │  + PVC (5Gi)    │
  └─────────────────┘
```

## ⚙️ Configurações por Ambiente

| Configuração | Local | AWS | Azure | GCP |
|--------------|-------|-----|-------|-----|
| **StorageClass** | standard | gp2 | managed-premium | pd-ssd |
| **Ingress** | NGINX | ALB | App Gateway | GKE Ingress |
| **ImagePullPolicy** | Never | IfNotPresent | IfNotPresent | IfNotPresent |
| **Replicas** | 1 | 3 | 3 | 3 |
| **Resources** | Reduzido | Produção | Produção | Produção |

## 📊 Recursos do Cluster

### Requisitos Mínimos (Local)
- CPU: 2 cores
- RAM: 4GB
- Disk: 20GB

### Requisitos Produção (Cloud)
- Nodes: 3+ (multi-AZ)
- CPU: 4+ cores por node
- RAM: 8GB+ por node
- Disk: 100GB+ (SSD)

## 🔐 Secrets

Secrets devem ser gerenciados de forma segura:

### Local (Desenvolvimento)
```bash
# Definido em base/secret.yaml e base/postgres-secret.yaml
# ⚠️ NÃO usar em produção
```

### Produção (Cloud)
```bash
# AWS: AWS Secrets Manager
# Azure: Azure Key Vault
# GCP: Secret Manager

# Usar External Secrets Operator ou similar
```

## 📝 Customização

Para customizar para seu ambiente:

1. Copie o overlay mais próximo:
   ```bash
   cp -r overlays/local overlays/meu-ambiente
   ```

2. Edite `kustomization.yaml` e os patches

3. Aplique:
   ```bash
   kubectl apply -k overlays/meu-ambiente
   ```

## 🆘 Troubleshooting

### ImagePullBackOff
```bash
# Minikube: construir imagem no ambiente Docker correto
eval $(minikube docker-env)
docker build -t vehicle-resale-api:1.0.0 .
```

### CrashLoopBackOff
```bash
# Ver logs
kubectl logs -f -n vehicle-resale -l app=vehicle-resale-api

# Verificar ConfigMap
kubectl describe configmap -n vehicle-resale
```

### Ingress não funciona
```bash
# Habilitar Ingress (Minikube)
minikube addons enable ingress

# Verificar Ingress Controller
kubectl get pods -n ingress-nginx
```

## 🔄 Atualizações

Para atualizar a aplicação:

```bash
# 1. Construir nova imagem
docker build -t vehicle-resale-api:1.1.0 .

# 2. Atualizar deployment
kubectl set image deployment/local-vehicle-resale-api \
  vehicle-resale-api=vehicle-resale-api:1.1.0 \
  -n vehicle-resale

# 3. Aguardar rollout
kubectl rollout status deployment/local-vehicle-resale-api -n vehicle-resale
```

---

**Última atualização:** 17/11/2024  
**Versão dos manifestos:** 1.0.0

