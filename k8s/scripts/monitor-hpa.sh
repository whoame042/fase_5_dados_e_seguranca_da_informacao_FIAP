#!/bin/bash

##############################################################################
# Script para monitorar HPA em tempo real
##############################################################################

NAMESPACE="vehicle-resale"
DEPLOYMENT="local-vehicle-resale-api"

echo "Monitorando Auto Scaling..."
echo "Pressione Ctrl+C para sair"
echo ""

while true; do
    clear
    echo "═══════════════════════════════════════════════════════════════"
    echo "          Monitoramento HPA - $(date +%H:%M:%S)"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    echo "HPA Status:"
    kubectl get hpa -n $NAMESPACE 2>/dev/null || echo "HPA não encontrado"
    echo ""
    
    echo "Pods:"
    kubectl get pods -n $NAMESPACE --no-headers 2>/dev/null | grep $DEPLOYMENT | awk '{printf "  %-50s %-10s %s\n", $1, $3, $4}'
    echo ""
    
    echo "Métricas (CPU/Memory):"
    kubectl top pods -n $NAMESPACE --no-headers 2>/dev/null | grep $DEPLOYMENT || echo "  Aguardando métricas..."
    echo ""
    
    echo "Próxima atualização em 3 segundos..."
    sleep 3
done

