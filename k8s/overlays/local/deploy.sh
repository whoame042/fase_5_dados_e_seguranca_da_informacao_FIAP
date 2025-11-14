#!/bin/bash

echo "Deploying Vehicle Resale API to Local Kubernetes..."
echo "=================================================="

# Verificar se kubectl está instalado
if ! command -v kubectl &> /dev/null; then
    echo "kubectl não encontrado. Por favor, instale kubectl."
    exit 1
fi

# Verificar se kustomize está instalado
if ! command -v kustomize &> /dev/null; then
    echo "kustomize não encontrado. Por favor, instale kustomize."
    exit 1
fi

# Verificar se o cluster está acessível
if ! kubectl cluster-info &> /dev/null; then
    echo "Não foi possível conectar ao cluster Kubernetes."
    echo "Certifique-se de que minikube/kind/k3s está rodando."
    exit 1
fi

# Verificar se NGINX Ingress Controller está instalado
if ! kubectl get ingressclass nginx &> /dev/null; then
    echo "NGINX Ingress Controller não encontrado."
    echo "Instalando NGINX Ingress Controller..."
    
    # Para minikube
    if command -v minikube &> /dev/null; then
        minikube addons enable ingress
    else
        # Para kind ou k3s (NGINX padrão)
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
    fi
    
    echo "Aguardando NGINX Ingress Controller ficar pronto..."
    sleep 30
fi

# Aplicar manifestos com Kustomize
echo "Aplicando manifestos Kubernetes..."
kubectl apply -k .

# Aguardar os pods ficarem prontos
echo "Aguardando pods ficarem prontos..."
kubectl wait --for=condition=ready pod -l app=vehicle-resale-api -n vehicle-resale --timeout=300s
kubectl wait --for=condition=ready pod -l app=postgres -n vehicle-resale --timeout=300s

# Mostrar status
echo ""
echo "Status do Deploy:"
echo "================"
kubectl get all -n vehicle-resale

echo ""
echo "Ingress:"
echo "========"
kubectl get ingress -n vehicle-resale

# Configurar /etc/hosts
echo ""
echo "Para acessar localmente, adicione ao /etc/hosts:"
echo "127.0.0.1 vehicle-resale-api.local"
echo ""

# Para minikube, obter IP
if command -v minikube &> /dev/null; then
    MINIKUBE_IP=$(minikube ip)
    echo "Para acessar, adicione ao /etc/hosts:"
    echo "$MINIKUBE_IP vehicle-resale-api.local"
    echo ""
    echo "Ou use:"
    echo "minikube service vehicle-resale-api-service -n vehicle-resale"
fi

echo ""
echo "Deploy concluído com sucesso!"
echo "Acesse: http://vehicle-resale-api.local"
echo "Swagger: http://vehicle-resale-api.local/swagger-ui"

