#!/bin/bash

##############################################################################
# Script Completo de Deploy no Minikube
# Este script faz todo o processo necessário para deploy local
##############################################################################

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Versão da imagem
IMAGE_VERSION="1.0.1"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Deploy da API de Revenda de Veículos - Minikube          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ==============================================================================
# 1. Verificar pré-requisitos
# ==============================================================================
echo -e "${YELLOW}1. Verificando pré-requisitos...${NC}"

if ! command -v minikube &> /dev/null; then
    echo -e "${RED}❌ Minikube não encontrado${NC}"
    echo "Instale com: curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && sudo install minikube-linux-amd64 /usr/local/bin/minikube"
    exit 1
fi
echo -e "${GREEN}   ✅ Minikube instalado${NC}"

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl não encontrado${NC}"
    echo "Instale com: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/"
    exit 1
fi
echo -e "${GREEN}   ✅ kubectl instalado${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker não encontrado${NC}"
    exit 1
fi
echo -e "${GREEN}   ✅ Docker instalado${NC}"

echo ""

# ==============================================================================
# 2. Verificar/Iniciar Minikube
# ==============================================================================
echo -e "${YELLOW}2. Verificando Minikube...${NC}"

if minikube status | grep -q "Running"; then
    echo -e "${GREEN}   ✅ Minikube já está rodando${NC}"
else
    echo "   Iniciando Minikube..."
    minikube start --driver=docker --memory=4096 --cpus=2
    echo -e "${GREEN}   ✅ Minikube iniciado${NC}"
fi

# Configurar kubectl para usar o contexto do minikube
kubectl config use-context minikube > /dev/null 2>&1

echo ""

# ==============================================================================
# 3. Build da aplicação
# ==============================================================================
echo -e "${YELLOW}3. Compilando aplicação...${NC}"

if [ ! -d "target/quarkus-app" ]; then
    echo "   Fazendo build do Quarkus..."
    ./mvnw clean package -DskipTests > /dev/null 2>&1
    ./mvnw quarkus:build -DskipTests > /dev/null 2>&1
    echo -e "${GREEN}   ✅ Build concluído${NC}"
else
    echo -e "${GREEN}   ✅ Build já existe${NC}"
fi

echo ""

# ==============================================================================
# 4. Build da imagem Docker
# ==============================================================================
echo -e "${YELLOW}4. Fazendo build da imagem Docker...${NC}"

# Usar o Docker do Minikube
eval $(minikube docker-env)

# Verificar se imagem já existe
if docker images | grep -q "vehicle-resale-api.*$IMAGE_VERSION"; then
    echo "   Imagem vehicle-resale-api:$IMAGE_VERSION já existe"
    read -p "   Deseja fazer rebuild? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        docker build -t vehicle-resale-api:$IMAGE_VERSION .
        echo -e "${GREEN}   ✅ Imagem reconstruída${NC}"
    else
        echo -e "${GREEN}   ✅ Usando imagem existente${NC}"
    fi
else
    echo "   Construindo imagem vehicle-resale-api:$IMAGE_VERSION..."
    docker build -t vehicle-resale-api:$IMAGE_VERSION .
    echo -e "${GREEN}   ✅ Imagem criada${NC}"
fi

echo ""

# ==============================================================================
# 5. Atualizar manifestos do Kubernetes
# ==============================================================================
echo -e "${YELLOW}5. Atualizando manifestos do Kubernetes...${NC}"

# Atualizar versão da imagem no deployment
sed -i "s|image: vehicle-resale-api:.*|image: vehicle-resale-api:$IMAGE_VERSION|g" k8s/base/deployment.yaml

# Garantir que imagePullPolicy seja Never para usar imagem local
sed -i "s|imagePullPolicy:.*|imagePullPolicy: Never|g" k8s/base/deployment.yaml

echo -e "${GREEN}   ✅ Manifestos atualizados${NC}"
echo ""

# ==============================================================================
# 6. Aplicar recursos do Kubernetes
# ==============================================================================
echo -e "${YELLOW}6. Aplicando recursos do Kubernetes...${NC}"

cd k8s

# Aplicar namespace primeiro
echo "   Criando namespace..."
kubectl apply -f base/namespace.yaml

# Aplicar configmaps e secrets
echo "   Aplicando ConfigMaps e Secrets..."
kubectl apply -f base/postgres-configmap.yaml
kubectl apply -f base/postgres-secret.yaml
kubectl apply -f base/keycloak-configmap.yaml
kubectl apply -f base/keycloak-secret.yaml
kubectl apply -f base/configmap.yaml
kubectl apply -f base/secret.yaml

# Aplicar PVCs
echo "   Aplicando PersistentVolumeClaims..."
kubectl apply -f base/postgres-pvc.yaml
kubectl apply -f base/keycloak-postgres-pvc.yaml

# Aplicar PostgreSQL
echo "   Aplicando PostgreSQL..."
kubectl apply -f base/postgres-deployment.yaml
kubectl apply -f base/postgres-service.yaml

# Aguardar PostgreSQL ficar pronto
echo "   Aguardando PostgreSQL ficar pronto..."
kubectl wait --for=condition=ready pod -l app=postgres -n vehicle-resale --timeout=120s || {
    echo -e "${YELLOW}   ⚠️  Timeout aguardando PostgreSQL, continuando...${NC}"
}

# Aplicar Keycloak PostgreSQL
echo "   Aplicando Keycloak PostgreSQL..."
kubectl apply -f base/keycloak-postgres-deployment.yaml
kubectl apply -f base/keycloak-postgres-service.yaml

# Aguardar Keycloak PostgreSQL
echo "   Aguardando Keycloak PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=keycloak-postgres -n vehicle-resale --timeout=120s || {
    echo -e "${YELLOW}   ⚠️  Timeout aguardando Keycloak PostgreSQL, continuando...${NC}"
}

# Aplicar Keycloak
echo "   Aplicando Keycloak..."
kubectl apply -f base/keycloak-deployment.yaml
kubectl apply -f base/keycloak-service.yaml

# Aguardar Keycloak
echo "   Aguardando Keycloak ficar pronto..."
kubectl wait --for=condition=ready pod -l app=keycloak -n vehicle-resale --timeout=180s || {
    echo -e "${YELLOW}   ⚠️  Timeout aguardando Keycloak, continuando...${NC}"
}

# Aplicar API
echo "   Aplicando Vehicle Resale API..."
kubectl apply -f base/deployment.yaml
kubectl apply -f base/service.yaml

# Aguardar API
echo "   Aguardando API ficar pronta..."
kubectl wait --for=condition=ready pod -l app=vehicle-resale-api -n vehicle-resale --timeout=120s || {
    echo -e "${YELLOW}   ⚠️  Timeout aguardando API, continuando...${NC}"
}

cd ..

echo -e "${GREEN}   ✅ Recursos aplicados com sucesso${NC}"
echo ""

# ==============================================================================
# 7. Verificar status
# ==============================================================================
echo -e "${YELLOW}7. Verificando status...${NC}"
echo ""

echo -e "${BLUE}📊 Pods:${NC}"
kubectl get pods -n vehicle-resale

echo ""
echo -e "${BLUE}🌐 Services:${NC}"
kubectl get services -n vehicle-resale

echo ""

# ==============================================================================
# 8. Configurar acesso
# ==============================================================================
echo -e "${YELLOW}8. Configurando acesso...${NC}"
echo ""

echo -e "${BLUE}Para acessar os serviços, use port-forward em terminais separados:${NC}"
echo ""
echo -e "${YELLOW}API:${NC}"
echo "  kubectl port-forward -n vehicle-resale svc/vehicle-resale-api-service 8082:80"
echo "  Acesse: http://localhost:8082"
echo "  Swagger: http://localhost:8082/swagger-ui"
echo ""
echo -e "${YELLOW}Keycloak:${NC}"
echo "  kubectl port-forward -n vehicle-resale svc/keycloak-service 8180:8180"
echo "  Acesse: http://localhost:8180"
echo "  Login: admin / admin123"
echo ""
echo -e "${YELLOW}PostgreSQL (API):${NC}"
echo "  kubectl port-forward -n vehicle-resale svc/postgres-service 5433:5432"
echo ""

# ==============================================================================
# 9. Comandos úteis
# ==============================================================================
echo -e "${BLUE}💡 Comandos úteis:${NC}"
echo ""
echo "  Ver logs da API:"
echo "    kubectl logs -f -l app=vehicle-resale-api -n vehicle-resale"
echo ""
echo "  Ver logs do Keycloak:"
echo "    kubectl logs -f -l app=keycloak -n vehicle-resale"
echo ""
echo "  Acessar shell do pod da API:"
echo "    kubectl exec -it -n vehicle-resale \$(kubectl get pod -l app=vehicle-resale-api -n vehicle-resale -o jsonpath='{.items[0].metadata.name}') -- /bin/bash"
echo ""
echo "  Remover todos os recursos:"
echo "    kubectl delete namespace vehicle-resale"
echo ""
echo "  Reiniciar deployment:"
echo "    kubectl rollout restart deployment/vehicle-resale-api -n vehicle-resale"
echo ""

# ==============================================================================
# 10. Dashboard (opcional)
# ==============================================================================
echo -e "${YELLOW}Para abrir o Minikube Dashboard:${NC}"
echo "  minikube dashboard"
echo ""

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  Deploy Concluído com Sucesso!                   ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Perguntar se deseja fazer port-forward automaticamente
echo -e "${YELLOW}Deseja iniciar port-forward da API automaticamente? (s/N)${NC}"
read -r -n 1 REPLY
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${GREEN}Iniciando port-forward...${NC}"
    echo "Acesse a API em: http://localhost:8082"
    echo "Swagger UI em: http://localhost:8082/swagger-ui"
    echo ""
    echo "Pressione Ctrl+C para parar"
    kubectl port-forward -n vehicle-resale svc/vehicle-resale-api-service 8082:80
fi
