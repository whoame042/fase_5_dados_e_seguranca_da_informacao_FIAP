#!/bin/bash

# Script completo para build e deploy da aplicação

echo "=== Build e Deploy da Aplicacao Vehicle Resale API ==="
echo ""

# Compilar a aplicação
echo "1. Compilando a aplicacao com Maven..."
./mvnw clean package -DskipTests

if [ $? -ne 0 ]; then
    echo "Erro ao compilar a aplicacao!"
    exit 1
fi

# Construir imagem Docker
echo ""
echo "2. Construindo imagem Docker..."
docker build -t vehicle-resale-api:1.0.0 .

if [ $? -ne 0 ]; then
    echo "Erro ao construir imagem Docker!"
    exit 1
fi

# Fazer deploy no Kubernetes
echo ""
echo "3. Fazendo deploy no Kubernetes..."
cd k8s
chmod +x deploy.sh
./deploy.sh

echo ""
echo "=== Build e Deploy concluidos com sucesso! ==="
echo ""

