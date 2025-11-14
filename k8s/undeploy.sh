#!/bin/bash

# Script para remover a aplicação do Kubernetes

echo "Removendo aplicacao Vehicle Resale API do Kubernetes..."

# Remover Service e Deployment da aplicação
echo "1. Removendo Service e Deployment da aplicacao..."
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml

# Remover ConfigMaps e Secrets da aplicação
echo "2. Removendo ConfigMaps e Secrets da aplicacao..."
kubectl delete -f configmap.yaml
kubectl delete -f secret.yaml

# Remover Service e Deployment do PostgreSQL
echo "3. Removendo Service e Deployment do PostgreSQL..."
kubectl delete -f postgres-service.yaml
kubectl delete -f postgres-deployment.yaml

# Remover PVC
echo "4. Removendo PersistentVolumeClaim..."
kubectl delete -f postgres-pvc.yaml

# Remover ConfigMaps e Secrets do PostgreSQL
echo "5. Removendo ConfigMaps e Secrets do PostgreSQL..."
kubectl delete -f postgres-configmap.yaml
kubectl delete -f postgres-secret.yaml

# Remover namespace (opcional - comentado por segurança)
# echo "6. Removendo namespace..."
# kubectl delete -f namespace.yaml

echo ""
echo "Remocao concluida com sucesso!"
echo ""

