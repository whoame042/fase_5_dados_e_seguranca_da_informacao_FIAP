#!/bin/bash

echo "Deploying Vehicle Resale API to GCP GKE..."
echo "=========================================="

# Verificar requisitos
if ! command -v kubectl &> /dev/null; then
    echo "kubectl não encontrado. Por favor, instale kubectl."
    exit 1
fi

if ! command -v kustomize &> /dev/null; then
    echo "kustomize não encontrado. Por favor, instale kustomize."
    exit 1
fi

if ! command -v gcloud &> /dev/null; then
    echo "gcloud CLI não encontrado. Por favor, instale Google Cloud SDK."
    exit 1
fi

# Verificar conexão com GKE
if ! kubectl cluster-info &> /dev/null; then
    echo "Não foi possível conectar ao cluster GKE."
    echo "Execute: gcloud container clusters get-credentials <cluster-name> --zone <zone>"
    exit 1
fi

# Reservar IP estático (se não existir)
echo "Verificando IP estático global..."
if ! gcloud compute addresses describe vehicle-resale-api-ip --global &> /dev/null; then
    echo "Criando IP estático global..."
    gcloud compute addresses create vehicle-resale-api-ip --global
fi

STATIC_IP=$(gcloud compute addresses describe vehicle-resale-api-ip --global --format="value(address)")
echo "IP Estático: $STATIC_IP"

# Aplicar manifestos
echo "Aplicando manifestos Kubernetes..."
kubectl apply -k .

# Aguardar pods ficarem prontos
echo "Aguardando pods ficarem prontos..."
kubectl wait --for=condition=ready pod -l app=vehicle-resale-api -n vehicle-resale --timeout=300s || true
kubectl wait --for=condition=ready pod -l app=postgres -n vehicle-resale --timeout=300s || true

# Mostrar status
echo ""
echo "Status do Deploy:"
echo "================"
kubectl get all -n vehicle-resale

echo ""
echo "Ingress (GCE Load Balancer):"
echo "============================"
kubectl get ingress -n vehicle-resale

# Aguardar Load Balancer ser provisionado
echo ""
echo "Aguardando GCE Load Balancer ser provisionado..."
echo "Isso pode levar 5-10 minutos..."

# Mostrar eventos do Ingress
kubectl describe ingress vehicle-resale-api-ingress -n vehicle-resale

echo ""
echo "Deploy concluído!"
echo "IP Estático: $STATIC_IP"
echo ""
echo "Configure seu DNS para apontar para:"
echo "vehicle-resale-api.example.com -> $STATIC_IP"
echo ""
echo "Monitore o status do Ingress:"
echo "kubectl get ingress -n vehicle-resale -w"

