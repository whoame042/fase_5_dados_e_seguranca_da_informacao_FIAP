#!/bin/bash

echo "Deploying Vehicle Resale API to Azure AKS..."
echo "============================================="

# Verificar requisitos
if ! command -v kubectl &> /dev/null; then
    echo "kubectl não encontrado. Por favor, instale kubectl."
    exit 1
fi

if ! command -v kustomize &> /dev/null; then
    echo "kustomize não encontrado. Por favor, instale kustomize."
    exit 1
fi

if ! command -v az &> /dev/null; then
    echo "Azure CLI não encontrado. Por favor, instale Azure CLI."
    exit 1
fi

# Verificar conexão com AKS
if ! kubectl cluster-info &> /dev/null; then
    echo "Não foi possível conectar ao cluster AKS."
    echo "Execute: az aks get-credentials --resource-group <rg-name> --name <cluster-name>"
    exit 1
fi

# Verificar Application Gateway Ingress Controller
echo "Verificando Application Gateway Ingress Controller..."
if ! kubectl get deployment -n kube-system ingress-appgw-deployment &> /dev/null; then
    echo "Application Gateway Ingress Controller não encontrado."
    echo "Por favor, instale o AGIC:"
    echo "https://docs.microsoft.com/en-us/azure/application-gateway/ingress-controller-install-new"
    exit 1
fi

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
echo "Ingress (Application Gateway):"
echo "=============================="
kubectl get ingress -n vehicle-resale

# Obter IP do Application Gateway
echo ""
echo "Aguardando Application Gateway ser configurado..."
sleep 60

APPGW_IP=$(kubectl get ingress vehicle-resale-api-ingress -n vehicle-resale -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [ -n "$APPGW_IP" ]; then
    echo ""
    echo "Deploy concluído com sucesso!"
    echo "Application Gateway IP: $APPGW_IP"
    echo ""
    echo "Configure seu DNS para apontar para:"
    echo "vehicle-resale-api.example.com -> $APPGW_IP"
    echo ""
    echo "Ou acesse diretamente:"
    echo "http://$APPGW_IP"
else
    echo ""
    echo "Application Gateway ainda não está pronto. Verifique o status com:"
    echo "kubectl get ingress -n vehicle-resale -w"
fi

