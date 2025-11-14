#!/bin/bash

# Script para deploy da aplicação no Kubernetes

echo "Iniciando deploy da aplicacao Vehicle Resale API..."

# Criar namespace
echo "1. Criando namespace..."
kubectl apply -f namespace.yaml

# Aplicar ConfigMaps e Secrets do PostgreSQL
echo "2. Aplicando ConfigMaps e Secrets do PostgreSQL..."
kubectl apply -f postgres-configmap.yaml
kubectl apply -f postgres-secret.yaml

# Aplicar PVC
echo "3. Criando PersistentVolumeClaim..."
kubectl apply -f postgres-pvc.yaml

# Aplicar Deployment e Service do PostgreSQL
echo "4. Criando Deployment e Service do PostgreSQL..."
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml

# Aguardar PostgreSQL estar pronto
echo "5. Aguardando PostgreSQL estar pronto..."
kubectl wait --for=condition=ready pod -l app=postgres -n vehicle-resale --timeout=300s

# Aplicar ConfigMaps e Secrets da aplicação
echo "6. Aplicando ConfigMaps e Secrets da aplicacao..."
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml

# Aplicar Deployment e Service da aplicação
echo "7. Criando Deployment e Service da aplicacao..."
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Aguardar pods da aplicação estarem prontos
echo "8. Aguardando pods da aplicacao estarem prontos..."
kubectl wait --for=condition=ready pod -l app=vehicle-resale-api -n vehicle-resale --timeout=300s

echo ""
echo "Deploy concluido com sucesso!"
echo ""
echo "Para verificar o status dos pods:"
echo "  kubectl get pods -n vehicle-resale"
echo ""
echo "Para verificar os services:"
echo "  kubectl get services -n vehicle-resale"
echo ""
echo "Para acessar os logs da aplicacao:"
echo "  kubectl logs -f -l app=vehicle-resale-api -n vehicle-resale"
echo ""

