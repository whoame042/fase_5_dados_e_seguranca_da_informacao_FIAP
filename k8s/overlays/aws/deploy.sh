#!/bin/bash

echo "Deploying Vehicle Resale API to AWS EKS..."
echo "==========================================="

# Verificar requisitos
if ! command -v kubectl &> /dev/null; then
    echo "kubectl não encontrado. Por favor, instale kubectl."
    exit 1
fi

if ! command -v kustomize &> /dev/null; then
    echo "kustomize não encontrado. Por favor, instale kustomize."
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "AWS CLI não encontrado. Por favor, instale AWS CLI."
    exit 1
fi

# Verificar conexão com EKS
if ! kubectl cluster-info &> /dev/null; then
    echo "Não foi possível conectar ao cluster EKS."
    echo "Execute: aws eks update-kubeconfig --name <cluster-name> --region <region>"
    exit 1
fi

# Verificar AWS Load Balancer Controller
echo "Verificando AWS Load Balancer Controller..."
if ! kubectl get deployment -n kube-system aws-load-balancer-controller &> /dev/null; then
    echo "AWS Load Balancer Controller não encontrado."
    echo "Por favor, instale o AWS Load Balancer Controller:"
    echo "https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html"
    echo ""
    echo "Comando rápido:"
    echo "helm repo add eks https://aws.github.io/eks-charts"
    echo "helm install aws-load-balancer-controller eks/aws-load-balancer-controller \\"
    echo "  -n kube-system \\"
    echo "  --set clusterName=<cluster-name>"
    exit 1
fi

# Verificar EBS CSI Driver
echo "Verificando AWS EBS CSI Driver..."
if ! kubectl get deployment -n kube-system ebs-csi-controller &> /dev/null; then
    echo "AWS EBS CSI Driver não encontrado."
    echo "Instalando AWS EBS CSI Driver..."
    kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.25"
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
echo "Ingress (ALB):"
echo "============="
kubectl get ingress -n vehicle-resale

# Aguardar ALB ser provisionado
echo ""
echo "Aguardando Application Load Balancer ser provisionado..."
echo "Isso pode levar alguns minutos..."
sleep 60

# Obter endereço do ALB
ALB_ADDRESS=$(kubectl get ingress vehicle-resale-api-ingress -n vehicle-resale -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [ -n "$ALB_ADDRESS" ]; then
    echo ""
    echo "Deploy concluído com sucesso!"
    echo "ALB Address: $ALB_ADDRESS"
    echo ""
    echo "Configure seu DNS para apontar para:"
    echo "vehicle-resale-api.example.com -> $ALB_ADDRESS"
    echo ""
    echo "Ou acesse diretamente:"
    echo "http://$ALB_ADDRESS"
    echo "http://$ALB_ADDRESS/swagger-ui"
else
    echo ""
    echo "ALB ainda não está pronto. Verifique o status com:"
    echo "kubectl get ingress -n vehicle-resale -w"
fi

