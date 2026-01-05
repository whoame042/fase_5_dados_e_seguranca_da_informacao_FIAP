# Kubernetes - Deploy Simplificado

Esta pasta contém os manifestos Kubernetes simplificados para deploy da aplicação.

## Estrutura

```
k8s/
├── base/                    # Manifestos base
│   ├── namespace.yaml       # Namespace
│   ├── deployment.yaml     # Deployment da API
│   ├── service.yaml        # Service da API
│   ├── configmap.yaml      # Configurações da API
│   ├── secret.yaml         # Secrets da API
│   ├── postgres-*.yaml     # PostgreSQL (banco da API)
│   ├── keycloak-*.yaml     # Keycloak (autenticação separada)
│   └── kustomization.yaml  # Kustomize
└── deploy.sh               # Script de deploy
```

## Requisitos

- Kubernetes cluster (Minikube, Kind, ou cloud)
- kubectl configurado
- kustomize (ou kubectl >= 1.14)

## Deploy

### Deploy Completo

```bash
cd k8s
./deploy.sh
```

### Deploy Manual

```bash
kubectl apply -k base/
```

### Verificar Status

```bash
kubectl get pods -n vehicle-resale
kubectl get services -n vehicle-resale
```

### Acessar Aplicação

```bash
# Port-forward
kubectl port-forward -n vehicle-resale svc/vehicle-resale-api-service 8082:80

# Acessar em http://localhost:8082
```

## Componentes

### API Application
- **Deployment**: `vehicle-resale-api` (1 replica)
- **Service**: `vehicle-resale-api-service` (ClusterIP)
- **Porta**: 8082

### PostgreSQL (API Database)
- **Deployment**: `postgres`
- **Service**: `postgres-service`
- **PVC**: `postgres-pvc`

### Keycloak (Authentication - Separated)
- **Deployment**: `keycloak`
- **Service**: `keycloak-service`
- **PostgreSQL**: `keycloak-postgres` (banco separado)
- **Porta**: 8180

## Remover Deploy

```bash
kubectl delete -k base/
# ou
kubectl delete namespace vehicle-resale
```

