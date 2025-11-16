#!/bin/bash

##############################################################################
# Script para gerar carga na API (causa scale out)
##############################################################################

NAMESPACE="vehicle-resale"
SERVICE="local-vehicle-resale-api-service"

echo "═══════════════════════════════════════════════════════════════"
echo "          Gerador de Carga - Auto Scaling Test"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Este script vai gerar carga na API para demonstrar scale out."
echo "Pressione Ctrl+C para parar"
echo ""
echo -n "Pressione ENTER para iniciar..."
read
echo ""
echo "Gerando carga... (em segundo plano)"
echo ""

# Criar pod gerador de carga
kubectl run load-generator \
  --image=busybox:1.36 \
  --restart=Never \
  -n $NAMESPACE \
  -- /bin/sh -c "while true; do wget -q -O- http://$SERVICE/api/vehicles/available > /dev/null 2>&1; done" &

echo "Pod gerador de carga criado!"
echo ""
echo "Comandos úteis:"
echo "  - Ver logs: kubectl logs load-generator -n $NAMESPACE -f"
echo "  - Parar: kubectl delete pod load-generator -n $NAMESPACE"
echo "  - Monitorar: ./k8s/monitor-hpa.sh"
echo ""
echo "Execute em outro terminal: ./k8s/monitor-hpa.sh"

