#!/bin/bash

##############################################################################
# Demo de Canary Deployment
# Demonstra o deploy gradual de uma nova versão
##############################################################################

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NAMESPACE="vehicle-resale"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info() { echo -e "\n${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "\n${GREEN}[SUCESSO]${NC} $1"; }
log_warn() { echo -e "\n${YELLOW}[AVISO]${NC} $1"; }
log_error() { echo -e "\n${RED}[ERRO]${NC} $1" >&2; }

# Verificar se o namespace existe
if ! kubectl get namespace ${NAMESPACE} &>/dev/null; then
    log_info "Criando namespace ${NAMESPACE}..."
    kubectl create namespace ${NAMESPACE}
fi

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              🎯 DEMO: CANARY DEPLOYMENT                          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Fase 1: Deploy da versão V1 (produção)
log_info "FASE 1: Aplicando versão V1 (100% do tráfego)"
kubectl apply -f "$SCRIPT_DIR/deployment-v1.yaml"
kubectl apply -f "$SCRIPT_DIR/service.yaml"

log_info "Aguardando pods da v1 ficarem prontos..."
kubectl wait --for=condition=ready pod -l app=vehicle-resale-api,version=v1 -n ${NAMESPACE} --timeout=120s || true

log_success "Versão V1 deployada"
echo ""
kubectl get pods -n ${NAMESPACE} -l app=vehicle-resale-api --show-labels
echo ""

log_info "Testando V1 (aguarde 5 segundos)..."
sleep 5

# Fase 2: Deploy da versão V2 Canary (10% do tráfego)
read -p "Pressione ENTER para deploy da versão V2 (Canary - 10% do tráfego)..."

log_info "FASE 2: Aplicando versão V2 (Canary - 10% do tráfego)"
log_info "  V1: 9 pods (90%)"
log_info "  V2: 1 pod (10%)"
kubectl apply -f "$SCRIPT_DIR/deployment-v2-canary.yaml"

log_info "Aguardando pods da v2 ficarem prontos..."
kubectl wait --for=condition=ready pod -l app=vehicle-resale-api,version=v2 -n ${NAMESPACE} --timeout=120s || true

log_success "Versão V2 Canary deployada"
echo ""
kubectl get pods -n ${NAMESPACE} -l app=vehicle-resale-api --show-labels
echo ""

log_info "Distribuição de tráfego atual:"
echo "  V1: ~90% (9 pods)"
echo "  V2: ~10% (1 pod)"
echo ""

# Fase 3: Aumentar tráfego do canary (50%)
read -p "Pressione ENTER para aumentar tráfego do Canary para 50%..."

log_info "FASE 3: Aumentando tráfego do Canary para 50%"
kubectl scale deployment/vehicle-resale-api-v1 --replicas=5 -n ${NAMESPACE}
kubectl scale deployment/vehicle-resale-api-v2-canary --replicas=5 -n ${NAMESPACE}

log_info "Aguardando escalonamento..."
sleep 10

log_success "Tráfego do Canary aumentado"
echo ""
kubectl get pods -n ${NAMESPACE} -l app=vehicle-resale-api --show-labels
echo ""

log_info "Distribuição de tráfego atual:"
echo "  V1: 50% (5 pods)"
echo "  V2: 50% (5 pods)"
echo ""

# Fase 4: Promover V2 para produção (100%)
read -p "Pressione ENTER para promover V2 para produção (100% do tráfego)..."

log_info "FASE 4: Promovendo V2 para produção (100% do tráfego)"
kubectl scale deployment/vehicle-resale-api-v1 --replicas=0 -n ${NAMESPACE}
kubectl scale deployment/vehicle-resale-api-v2-canary --replicas=10 -n ${NAMESPACE}

log_info "Aguardando escalonamento..."
sleep 10

log_success "V2 promovida para produção (100% do tráfego)"
echo ""
kubectl get pods -n ${NAMESPACE} -l app=vehicle-resale-api --show-labels
echo ""

log_info "Distribuição de tráfego atual:"
echo "  V1: 0% (0 pods)"
echo "  V2: 100% (10 pods)"
echo ""

# Fase 5: Limpeza (opcional)
read -p "Pressione ENTER para remover a versão V1 antiga..."

log_info "FASE 5: Removendo deployment V1 (não é mais necessário)"
kubectl delete deployment/vehicle-resale-api-v1 -n ${NAMESPACE}

log_success "Deployment V1 removido"
echo ""

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ✅ DEMO CONCLUÍDO!                                   ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

log_info "Resumo do Canary Deployment:"
echo "  1. V1 deployada (100% do tráfego)"
echo "  2. V2 Canary adicionada (10% do tráfego)"
echo "  3. V2 Canary aumentada (50% do tráfego)"
echo "  4. V2 promovida (100% do tráfego)"
echo "  5. V1 removida"
echo ""

log_info "Para limpar completamente:"
echo "  kubectl delete -f $SCRIPT_DIR/"

