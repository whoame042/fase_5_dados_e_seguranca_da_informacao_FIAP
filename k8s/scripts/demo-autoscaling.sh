#!/bin/bash

##############################################################################
# Script para demonstrar Auto Scaling (HPA) no Kubernetes
# Mostra scale out (aumentar pods) e scale in (diminuir pods)
##############################################################################

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

NAMESPACE="vehicle-resale"
DEPLOYMENT="local-vehicle-resale-api"
SERVICE="local-vehicle-resale-api-service"
HPA_FILE="k8s/overlays/local/hpa-demo.yaml"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Demonstração de Auto Scaling (HPA)                     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Função para verificar métricas
check_metrics() {
    echo -e "${YELLOW}Verificando se Metrics Server está ativo...${NC}"
    if ! kubectl top nodes &> /dev/null; then
        echo -e "${RED}Metrics Server não está funcionando!${NC}"
        echo "Habilitando Metrics Server..."
        minikube addons enable metrics-server
        echo "Aguardando Metrics Server ficar pronto (60 segundos)..."
        sleep 60
        
        if ! kubectl top nodes &> /dev/null; then
            echo -e "${RED}Erro: Metrics Server não iniciou corretamente.${NC}"
            echo "Execute: minikube addons enable metrics-server"
            exit 1
        fi
    fi
    echo -e "${GREEN}✅ Metrics Server ativo!${NC}"
    echo ""
}

# Função para aplicar HPA
apply_hpa() {
    echo -e "${YELLOW}1. Aplicando HPA...${NC}"
    kubectl apply -f "$HPA_FILE"
    echo ""
    sleep 3
    
    echo "Status do HPA:"
    kubectl get hpa -n $NAMESPACE
    echo ""
}

# Função para mostrar estado inicial
show_initial_state() {
    echo -e "${YELLOW}2. Estado Inicial:${NC}"
    echo ""
    echo "Pods atuais:"
    kubectl get pods -n $NAMESPACE | grep $DEPLOYMENT
    echo ""
    echo "HPA configurado:"
    kubectl get hpa -n $NAMESPACE -o wide
    echo ""
}

# Função para gerar carga
generate_load() {
    echo -e "${YELLOW}3. Gerando carga na aplicação...${NC}"
    echo -e "${CYAN}Isso vai causar SCALE OUT (aumentar pods)${NC}"
    echo ""
    
    # Criar pod temporário para gerar carga
    kubectl run -i --tty load-generator --rm --image=busybox:1.36 --restart=Never -n $NAMESPACE -- /bin/sh -c "
        echo 'Gerando requisições HTTP...'
        while true; do
            wget -q -O- http://$SERVICE/api/vehicles/available > /dev/null 2>&1
            wget -q -O- http://$SERVICE/health/ready > /dev/null 2>&1
        done
    " &
    
    LOAD_PID=$!
    echo "Gerador de carga iniciado (PID: $LOAD_PID)"
    echo ""
}

# Função para monitorar
monitor() {
    echo -e "${YELLOW}4. Monitorando Auto Scaling...${NC}"
    echo -e "${CYAN}Observe os pods aumentarem (scale out)${NC}"
    echo -e "${YELLOW}Pressione Ctrl+C para parar a carga e ver scale in${NC}"
    echo ""
    
    # Monitorar por 2 minutos ou até Ctrl+C
    for i in {1..24}; do
        clear
        echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║          Monitoramento de Auto Scaling ($(date +%H:%M:%S))              ║${NC}"
        echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        echo -e "${CYAN}HPA Status:${NC}"
        kubectl get hpa -n $NAMESPACE
        echo ""
        
        echo -e "${CYAN}Pods:${NC}"
        kubectl get pods -n $NAMESPACE | grep -E "NAME|$DEPLOYMENT"
        echo ""
        
        echo -e "${CYAN}Métricas de CPU/Memória:${NC}"
        kubectl top pods -n $NAMESPACE --no-headers 2>/dev/null | grep $DEPLOYMENT || echo "Coletando métricas..."
        echo ""
        
        echo -e "${YELLOW}Aguardando próxima atualização (5s)...${NC}"
        echo -e "${RED}Pressione Ctrl+C para parar a carga${NC}"
        sleep 5
    done
}

# Função para scale in (diminuir)
demonstrate_scale_in() {
    echo ""
    echo -e "${YELLOW}5. Parando carga - demonstrando SCALE IN (diminuir pods)${NC}"
    echo ""
    
    # Parar gerador de carga
    kubectl delete pod load-generator -n $NAMESPACE 2>/dev/null
    pkill -P $$ 2>/dev/null
    
    echo "Monitorando redução de pods..."
    echo "O HPA vai reduzir os pods gradualmente (pode levar alguns minutos)"
    echo ""
    
    for i in {1..20}; do
        clear
        echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║          SCALE IN - Reduzindo Pods ($(date +%H:%M:%S))              ║${NC}"
        echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        echo -e "${CYAN}HPA Status:${NC}"
        kubectl get hpa -n $NAMESPACE
        echo ""
        
        echo -e "${CYAN}Pods (observe a redução):${NC}"
        kubectl get pods -n $NAMESPACE | grep -E "NAME|$DEPLOYMENT"
        echo ""
        
        CURRENT_PODS=$(kubectl get pods -n $NAMESPACE --no-headers 2>/dev/null | grep -c "$DEPLOYMENT.*Running")
        if [ "$CURRENT_PODS" -eq 1 ]; then
            echo -e "${GREEN}✅ Scale In completo! Voltou ao mínimo de 1 pod${NC}"
            break
        fi
        
        echo -e "${YELLOW}Aguardando próxima verificação (10s)...${NC}"
        sleep 10
    done
}

# Função de limpeza
cleanup() {
    echo ""
    echo -e "${YELLOW}6. Limpeza...${NC}"
    kubectl delete pod load-generator -n $NAMESPACE 2>/dev/null
    pkill -P $$ 2>/dev/null
    
    echo ""
    echo -e "${CYAN}Deseja remover o HPA? (s/N)${NC}"
    read -r response
    if [[ "$response" =~ ^[Ss]$ ]]; then
        kubectl delete -f "$HPA_FILE"
        echo -e "${GREEN}HPA removido.${NC}"
    else
        echo "HPA mantido. Para remover depois:"
        echo "  kubectl delete -f $HPA_FILE"
    fi
}

# Trap para Ctrl+C
trap 'echo ""; demonstrate_scale_in; cleanup; exit 0' INT TERM

# Execução principal
main() {
    check_metrics
    apply_hpa
    show_initial_state
    
    echo -e "${CYAN}Preparado para iniciar demonstração!${NC}"
    echo -n "Pressione ENTER para começar..."
    read
    
    generate_load
    monitor
    
    demonstrate_scale_in
    cleanup
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          Demonstração de Auto Scaling Concluída!                ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
}

main

