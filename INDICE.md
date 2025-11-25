# Índice Rápido - Vehicle Resale API

## Documentos Principais

| Documento | Descrição | Localização |
|-----------|-----------|-------------|
| **README.md** | Visão geral e quick start | [README.md](README.md) |
| **MANIFESTOS_OBRIGATORIOS** | Evidência dos 4 manifestos K8s | [k8s/MANIFESTOS_OBRIGATORIOS.md](k8s/MANIFESTOS_OBRIGATORIOS.md) |
| **CLEAN_ARCHITECTURE** | Análise e melhorias Clean Arch | [CLEAN_ARCHITECTURE.md](CLEAN_ARCHITECTURE.md) |
| **ARCHITECTURE** | Arquitetura da solução | [ARCHITECTURE.md](ARCHITECTURE.md) |

## Quick Start

### Executar Localmente
```bash
mvn clean package -DskipTests
docker-compose up -d
# http://localhost:8082
```

### Deploy Kubernetes
```bash
cd k8s/overlays/local
./deploy-minikube.sh
```

## Validação dos Requisitos

### ✅ Funcionalidades
- Cadastro e edição de veículos
- Efetivação de vendas
- Listagem de veículos disponíveis (ordenados por preço)
- Listagem de veículos vendidos (ordenados por preço)
- Webhook de pagamento

### ✅ Kubernetes - Manifestos Obrigatórios
| Manifesto | Status | Arquivo |
|-----------|--------|---------|
| Deployment | ✅ | `k8s/base/deployment.yaml` |
| Service | ✅ | `k8s/base/service.yaml` |
| ConfigMap | ✅ | `k8s/base/configmap.yaml` |
| Secret | ✅ | `k8s/base/secret.yaml` |

**Documentação completa:** [k8s/MANIFESTOS_OBRIGATORIOS.md](k8s/MANIFESTOS_OBRIGATORIOS.md)

### ✅ Clean Architecture
- Entities (Domain) - Implementadas
- Use Cases (Services) - Implementados
- Melhorias documentadas em [CLEAN_ARCHITECTURE.md](CLEAN_ARCHITECTURE.md)

## Estrutura do Projeto

```
vehicle-resale-api/
├── README.md                      # Visão geral + Quick Start
├── CLEAN_ARCHITECTURE.md          # Análise Clean Architecture
├── ARCHITECTURE.md                # Arquitetura detalhada
├── INDICE.md                      # Este arquivo
│
├── src/                           # Código-fonte
│   ├── main/java/com/vehicleresale/
│   │   ├── api/                   # Controllers REST + DTOs
│   │   └── domain/                # Entities + Services + Repos
│   └── test/                      # Testes unitários
│
├── k8s/                           # Manifestos Kubernetes
│   ├── base/                      # Manifestos base
│   │   ├── deployment.yaml        # ✅ Deployment
│   │   ├── service.yaml           # ✅ Service
│   │   ├── configmap.yaml         # ✅ ConfigMap
│   │   ├── secret.yaml            # ✅ Secret
│   │   └── ...
│   ├── overlays/                  # Configs por ambiente
│   ├── demos/                     # Demos Canary/A-B
│   ├── MANIFESTOS_OBRIGATORIOS.md # ⭐ Evidência manifestos
│   └── README.md                  # Documentação K8s
│
├── docker-compose.yml             # Ambiente local
├── Dockerfile                     # Build da imagem
└── pom.xml                        # Dependências Maven
```

## Documentação Kubernetes

| Documento | Descrição |
|-----------|-----------|
| `k8s/MANIFESTOS_OBRIGATORIOS.md` | ⭐ Evidência dos 4 manifestos obrigatórios |
| `k8s/README.md` | Documentação completa Kubernetes |
| `k8s/STRUCTURE.md` | Estrutura detalhada dos manifestos |
| `k8s/INDEX.md` | Índice rápido Kubernetes |
| `k8s/demos/README.md` | Estratégias Canary e A/B Testing |

## Endpoints da API

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/api/vehicles/available` | Listar veículos disponíveis |
| GET | `/api/vehicles/sold` | Listar veículos vendidos |
| POST | `/api/vehicles` | Cadastrar veículo |
| PUT | `/api/vehicles/{id}` | Atualizar veículo |
| DELETE | `/api/vehicles/{id}` | Excluir veículo |
| POST | `/api/sales` | Efetivar venda |
| POST | `/api/webhook/payment` | Processar pagamento |

**Swagger UI:** `http://localhost:8082/swagger-ui`

## Testes

```bash
# Executar testes
mvn test

# Executar com relatório
mvn clean test
```

## Comandos Úteis

### Docker Compose
```bash
# Subir ambiente
docker-compose up -d

# Ver logs
docker-compose logs -f

# Parar
docker-compose down
```

### Kubernetes
```bash
# Deploy local
cd k8s/overlays/local && ./deploy-minikube.sh

# Ver pods
kubectl get pods -n vehicle-resale

# Ver logs
kubectl logs -f -n vehicle-resale -l app=vehicle-resale-api

# Port-forward
kubectl port-forward -n vehicle-resale service/local-vehicle-resale-api-service 8082:80
```

## Feedback Atendido

### ✅ Documentação
- README mais conciso e objetivo
- Comandos docker-compose mantidos
- Swagger documentado

### ✅ Kubernetes
- Deployment, Service, ConfigMap e Secret implementados
- Documento evidenciando os 4 manifestos obrigatórios
- Conteúdo completo de cada manifesto

### ✅ Clean Architecture
- Entities e Use Cases bem implementados
- Documentação de melhorias propostas
- Exemplos de Gateway e Presenter Pattern
- Roadmap de evolução

---

**Para mais detalhes, consulte:**
- [README.md](README.md) - Visão geral completa
- [k8s/MANIFESTOS_OBRIGATORIOS.md](k8s/MANIFESTOS_OBRIGATORIOS.md) - Evidência dos manifestos K8s
- [CLEAN_ARCHITECTURE.md](CLEAN_ARCHITECTURE.md) - Análise e melhorias

