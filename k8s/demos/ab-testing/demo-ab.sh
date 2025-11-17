#!/bin/bash

##############################################################################
# Demo de A/B Testing
# Demonstra o roteamento inteligente baseado em headers/cookies
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
echo -e "${BLUE}║              🎯 DEMO: A/B TESTING                                ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Fase 1: Deploy das versões A e B
log_info "FASE 1: Aplicando versões A e B"
kubectl apply -f "$SCRIPT_DIR/deployment-version-a.yaml"
kubectl apply -f "$SCRIPT_DIR/deployment-version-b.yaml"
kubectl apply -f "$SCRIPT_DIR/service-version-a.yaml"
kubectl apply -f "$SCRIPT_DIR/service-version-b.yaml"

log_info "Aguardando pods ficarem prontos..."
kubectl wait --for=condition=ready pod -l app=vehicle-resale-api,version=a -n ${NAMESPACE} --timeout=120s || true
kubectl wait --for=condition=ready pod -l app=vehicle-resale-api,version=b -n ${NAMESPACE} --timeout=120s || true

log_success "Versões A e B deployadas"
echo ""
kubectl get pods -n ${NAMESPACE} -l app=vehicle-resale-api --show-labels
echo ""

# Fase 2: Aplicar Ingress para A/B Testing
read -p "Pressione ENTER para configurar Ingress A/B..."

log_info "FASE 2: Aplicando Ingress para A/B Testing"
kubectl apply -f "$SCRIPT_DIR/ingress-ab.yaml"

log_info "Aguardando Ingress ficar pronto..."
sleep 5

log_success "Ingress A/B configurado"
echo ""
kubectl get ingress -n ${NAMESPACE}
echo ""

# Fase 3: Testar roteamento
log_info "FASE 3: Testando roteamento A/B"
echo ""

# Obter IP do Minikube (se disponível)
if command -v minikube &> /dev/null; then
    MINIKUBE_IP=$(minikube ip)
    log_info "IP do Minikube: ${MINIKUBE_IP}"
    log_warn "Adicione ao /etc/hosts:"
    echo "  ${MINIKUBE_IP} vehicle-resale-api-ab.local"
    echo ""
fi

log_info "Como testar o A/B Testing:"
echo ""
echo "1️⃣  Usuários PADRÃO (sem header/cookie) → Versão A"
echo "   ${YELLOW}curl http://vehicle-resale-api-ab.local/health${NC}"
echo ""
echo "2️⃣  Usuários BETA (com header X-Version: B) → Versão B"
echo "   ${YELLOW}curl -H 'X-Version: B' http://vehicle-resale-api-ab.local/health${NC}"
echo ""
echo "3️⃣  Usuários BETA (com cookie version=B) → Versão B"
echo "   ${YELLOW}curl --cookie 'version=B' http://vehicle-resale-api-ab.local/health${NC}"
echo ""

# Fase 4: Demonstração de port-forward
read -p "Pressione ENTER para configurar port-forward para testes locais..."

log_info "FASE 4: Configurando port-forward"
log_info "Serviço A: porta 8080"
log_info "Serviço B: porta 8081"
echo ""

# Port-forward para versão A
kubectl port-forward -n ${NAMESPACE} svc/vehicle-resale-api-version-a-service 8080:80 &
PF_PID_A=$!

# Port-forward para versão B
kubectl port-forward -n ${NAMESPACE} svc/vehicle-resale-api-version-b-service 8081:80 &
PF_PID_B=$!

sleep 3

log_success "Port-forward configurado"
echo ""
echo "Testar localmente:"
echo "  Versão A: ${YELLOW}curl http://localhost:8080/health${NC}"
echo "  Versão B: ${YELLOW}curl http://localhost:8081/health${NC}"
echo ""

log_info "Pressione Ctrl+C para parar o port-forward e continuar..."
trap "kill $PF_PID_A $PF_PID_B 2>/dev/null" EXIT

# Aguardar Ctrl+C
wait $PF_PID_A $PF_PID_B

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ✅ DEMO CONCLUÍDO!                                   ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

log_info "Resumo do A/B Testing:"
echo "  1. Versões A e B deployadas simultaneamente"
echo "  2. Ingress configurado com roteamento baseado em header/cookie"
echo "  3. Usuários sem header/cookie → Versão A (controle)"
echo "  4. Usuários com X-Version: B ou cookie version=B → Versão B (experimental)"
echo ""

log_info "Para limpar completamente:"
echo "  kubectl delete -f $SCRIPT_DIR/"

