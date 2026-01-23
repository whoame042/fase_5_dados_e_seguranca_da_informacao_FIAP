#!/bin/bash

##############################################################################
# Script Automatizado de Deploy no Minikube (Não-interativo)
##############################################################################

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

IMAGE_VERSION="1.0.1"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Deploy Automático - API de Revenda de Veículos           ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar Minikube
if ! minikube status | grep -q "Running"; then
    echo -e "${YELLOW}Iniciando Minikube...${NC}"
    minikube start --driver=docker --memory=4096 --cpus=2
fi
echo -e "${GREEN}✅ Minikube rodando${NC}"

# Configurar kubectl
kubectl config use-context minikube > /dev/null 2>&1

# Build da aplicação (se necessário)
if [ ! -d "target/quarkus-app" ]; then
    echo -e "${YELLOW}Compilando aplicação...${NC}"
    ./mvnw clean package -DskipTests > /dev/null 2>&1
    ./mvnw quarkus:build -DskipTests > /dev/null 2>&1
    echo -e "${GREEN}✅ Build concluído${NC}"
fi

# Build Docker
echo -e "${YELLOW}Configurando Docker do Minikube...${NC}"
eval $(minikube docker-env)

if ! docker images | grep -q "vehicle-resale-api.*$IMAGE_VERSION"; then
    echo -e "${YELLOW}Fazendo build da imagem...${NC}"
    docker build -t vehicle-resale-api:$IMAGE_VERSION . > /dev/null 2>&1
    echo -e "${GREEN}✅ Imagem criada${NC}"
else
    echo -e "${GREEN}✅ Imagem já existe${NC}"
fi

# Deploy Kubernetes
echo -e "${YELLOW}Aplicando recursos do Kubernetes...${NC}"

cd k8s

kubectl apply -f base/namespace.yaml > /dev/null 2>&1

kubectl apply -f base/postgres-configmap.yaml \
              -f base/postgres-secret.yaml \
              -f base/keycloak-configmap.yaml \
              -f base/keycloak-secret.yaml \
              -f base/configmap.yaml \
              -f base/secret.yaml > /dev/null 2>&1

kubectl apply -f base/postgres-pvc.yaml \
              -f base/keycloak-postgres-pvc.yaml > /dev/null 2>&1

kubectl apply -f base/postgres-deployment.yaml \
              -f base/postgres-service.yaml > /dev/null 2>&1

kubectl apply -f base/keycloak-postgres-deployment.yaml \
              -f base/keycloak-postgres-service.yaml > /dev/null 2>&1

kubectl apply -f base/keycloak-deployment.yaml \
              -f base/keycloak-service.yaml > /dev/null 2>&1

kubectl apply -f base/deployment.yaml \
              -f base/service.yaml > /dev/null 2>&1

cd ..

echo -e "${GREEN}✅ Recursos aplicados${NC}"
echo ""

# Aguardar pods (com timeout menor)
echo -e "${YELLOW}Aguardando pods ficarem prontos...${NC}"
echo "  - PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=postgres -n vehicle-resale --timeout=60s 2>/dev/null || true

echo "  - Keycloak PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=keycloak-postgres -n vehicle-resale --timeout=60s 2>/dev/null || true

echo "  - API..."
kubectl wait --for=condition=ready pod -l app=vehicle-resale-api -n vehicle-resale --timeout=60s 2>/dev/null || true

echo "  - Keycloak (pode demorar)..."
kubectl wait --for=condition=ready pod -l app=keycloak -n vehicle-resale --timeout=120s 2>/dev/null || {
    echo -e "${YELLOW}    Keycloak ainda iniciando (isso é normal)${NC}"
}

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  Deploy Concluído!                               ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Status
echo -e "${BLUE}📊 Status dos Pods:${NC}"
kubectl get pods -n vehicle-resale
echo ""

echo -e "${BLUE}🌐 Services:${NC}"
kubectl get svc -n vehicle-resale
echo ""

# Instruções
echo -e "${YELLOW}Para acessar os serviços:${NC}"
echo ""
echo -e "${GREEN}API (Terminal 1):${NC}"
echo "  kubectl port-forward -n vehicle-resale svc/vehicle-resale-api-service 8082:80"
echo "  URL: http://localhost:8082"
echo "  Swagger: http://localhost:8082/swagger-ui"
echo ""
echo -e "${GREEN}Keycloak (Terminal 2):${NC}"
echo "  kubectl port-forward -n vehicle-resale svc/keycloak-service 8180:8180"
echo "  URL: http://localhost:8180"
echo "  Login: admin / admin123"
echo ""

echo -e "${YELLOW}Ver logs:${NC}"
echo "  kubectl logs -f -l app=vehicle-resale-api -n vehicle-resale"
echo ""
echo -e "${YELLOW}Remover tudo:${NC}"
echo "  kubectl delete namespace vehicle-resale"
echo ""
