#!/bin/bash

##############################################################################
# Script Inteligente de Port-Forward
# Gerencia port-forwards automaticamente, lidando com portas em uso
##############################################################################

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NAMESPACE="${1:-vehicle-resale}"
SERVICE="${2:-local-vehicle-resale-api-service}"
LOCAL_PORT="${3:-8080}"
SERVICE_PORT="${4:-80}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Port-Forward Inteligente para Kubernetes               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

##############################################################################
# 1. VERIFICAR SE O SERVIÇO EXISTE
##############################################################################

if ! kubectl get service "$SERVICE" -n "$NAMESPACE" &>/dev/null; then
    echo -e "${RED}❌ Serviço '$SERVICE' não encontrado no namespace '$NAMESPACE'${NC}"
    echo ""
    echo "Serviços disponíveis:"
    kubectl get services -n "$NAMESPACE"
    exit 1
fi

echo -e "${GREEN}✓ Serviço encontrado: $SERVICE${NC}"
echo ""

##############################################################################
# 2. VERIFICAR SE HÁ PODS PRONTOS
##############################################################################

READY_PODS=$(kubectl get endpoints "$SERVICE" -n "$NAMESPACE" -o jsonpath='{.subsets[*].addresses[*].ip}' | wc -w)

if [ "$READY_PODS" -eq 0 ]; then
    echo -e "${RED}❌ Nenhum pod pronto para o serviço '$SERVICE'${NC}"
    echo ""
    echo "Status dos pods:"
    kubectl get pods -n "$NAMESPACE" -l app=$(echo "$SERVICE" | sed 's/-service//')
    echo ""
    echo -e "${YELLOW}Execute o diagnóstico:${NC}"
    echo -e "  ${GREEN}./k8s/scripts/k8s-diagnose.sh${NC}"
    exit 1
fi

echo -e "${GREEN}✓ $READY_PODS pod(s) pronto(s)${NC}"
echo ""

##############################################################################
# 3. VERIFICAR SE A PORTA LOCAL ESTÁ EM USO
##############################################################################

if lsof -i ":$LOCAL_PORT" &>/dev/null || ss -tln | grep -q ":$LOCAL_PORT "; then
    echo -e "${YELLOW}⚠️  Porta $LOCAL_PORT já está em uso${NC}"
    echo ""
    
    # Verificar se é um port-forward antigo
    PF_PIDS=$(pgrep -f "kubectl port-forward.*$LOCAL_PORT" || echo "")
    
    if [ -n "$PF_PIDS" ]; then
        echo -e "${YELLOW}Port-forwards encontrados usando a porta $LOCAL_PORT:${NC}"
        ps aux | grep "kubectl port-forward" | grep -v grep | grep "$LOCAL_PORT"
        echo ""
        
        read -p "Deseja matar esses port-forwards? (s/n) " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            echo "$PF_PIDS" | xargs kill 2>/dev/null || true
            sleep 2
            echo -e "${GREEN}✓ Port-forwards antigos finalizados${NC}"
        else
            # Sugerir porta alternativa
            ALTERNATIVE_PORT=$((LOCAL_PORT + 1))
            while lsof -i ":$ALTERNATIVE_PORT" &>/dev/null || ss -tln | grep -q ":$ALTERNATIVE_PORT "; do
                ALTERNATIVE_PORT=$((ALTERNATIVE_PORT + 1))
            done
            
            echo -e "${YELLOW}Usando porta alternativa: $ALTERNATIVE_PORT${NC}"
            LOCAL_PORT=$ALTERNATIVE_PORT
        fi
    else
        # Outro processo está usando a porta
        echo "Processo usando a porta:"
        lsof -i ":$LOCAL_PORT" 2>/dev/null || ss -tlnp | grep ":$LOCAL_PORT"
        echo ""
        
        # Sugerir porta alternativa
        ALTERNATIVE_PORT=$((LOCAL_PORT + 1))
        while lsof -i ":$ALTERNATIVE_PORT" &>/dev/null || ss -tln | grep -q ":$ALTERNATIVE_PORT "; do
            ALTERNATIVE_PORT=$((ALTERNATIVE_PORT + 1))
        done
        
        echo -e "${YELLOW}Usando porta alternativa: $ALTERNATIVE_PORT${NC}"
        LOCAL_PORT=$ALTERNATIVE_PORT
    fi
    echo ""
fi

##############################################################################
# 4. INICIAR PORT-FORWARD
##############################################################################

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Iniciando Port-Forward${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "Configuração:"
echo "  Namespace: $NAMESPACE"
echo "  Serviço: $SERVICE"
echo "  Porta Local: $LOCAL_PORT"
echo "  Porta do Serviço: $SERVICE_PORT"
echo ""

echo -e "${GREEN}Iniciando port-forward...${NC}"
echo -e "${YELLOW}Pressione Ctrl+C para parar${NC}"
echo ""
echo "Comandos úteis:"
echo -e "  ${GREEN}curl http://localhost:$LOCAL_PORT/health/ready${NC}"
echo -e "  ${GREEN}curl http://localhost:$LOCAL_PORT/vehicles${NC}"
echo -e "  ${GREEN}curl http://localhost:$LOCAL_PORT/q/swagger-ui${NC}"
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Trap para cleanup
cleanup() {
    echo ""
    echo -e "${YELLOW}Port-forward finalizado${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Iniciar port-forward
kubectl port-forward -n "$NAMESPACE" "service/$SERVICE" "$LOCAL_PORT:$SERVICE_PORT"

