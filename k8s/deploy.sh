#!/bin/bash

# Script simplificado para deploy da aplicação no Kubernetes
# Usa kustomize para aplicar todos os recursos de uma vez

set -e

echo "=========================================="
echo "  Deploy Vehicle Resale API - Kubernetes"
echo "=========================================="
echo ""

# Verificar se kustomize está instalado
if ! command -v kustomize &> /dev/null && ! kubectl kustomize --help &> /dev/null; then
    echo "❌ Erro: kustomize não encontrado"
    echo "   Instale kustomize ou use kubectl >= 1.14"
    exit 1
fi

# Aplicar recursos usando kustomize
echo "📦 Aplicando recursos do Kubernetes..."

# Determinar o diretório correto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$SCRIPT_DIR/base"

if [ ! -d "$BASE_DIR" ]; then
    echo "❌ Erro: Diretório base/ não encontrado em $SCRIPT_DIR"
    exit 1
fi

if command -v kustomize &> /dev/null; then
    kustomize build "$BASE_DIR" | kubectl apply -f -
else
    kubectl apply -k "$BASE_DIR"
fi

echo ""
echo "⏳ Aguardando pods ficarem prontos..."

# Aguardar PostgreSQL
echo "  - Aguardando PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=postgres -n vehicle-resale --timeout=120s || true

# Aguardar Keycloak
echo "  - Aguardando Keycloak..."
kubectl wait --for=condition=ready pod -l app=keycloak -n vehicle-resale --timeout=180s || true

# Aguardar API
echo "  - Aguardando API..."
kubectl wait --for=condition=ready pod -l app=vehicle-resale-api -n vehicle-resale --timeout=120s || true

echo ""
echo "✅ Deploy concluído!"
echo ""
echo "📊 Status dos pods:"
kubectl get pods -n vehicle-resale
echo ""
echo "🌐 Services:"
kubectl get services -n vehicle-resale
echo ""
echo "💡 Para ver logs:"
echo "   kubectl logs -f -l app=vehicle-resale-api -n vehicle-resale"
echo ""
echo "💡 Para port-forward:"
echo "   kubectl port-forward -n vehicle-resale svc/vehicle-resale-api-service 8082:80"
