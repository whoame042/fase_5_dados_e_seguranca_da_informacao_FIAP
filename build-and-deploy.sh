#!/bin/bash

# Script completo para build e deploy da aplicação

echo "=== Build e Deploy da Aplicacao Vehicle Resale API ==="
echo ""

# Configurar Java 21 e Maven 3.9.6
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=/home/eduardo-almeida/.sdkman/candidates/maven/3.9.6/bin:$JAVA_HOME/bin:$PATH

echo "Usando Java: $(java -version 2>&1 | head -n 1)"
echo "Usando Maven: $(mvn -version | head -n 1)"
echo ""

# Compilar a aplicação
echo "1. Compilando a aplicacao com Maven..."
mvn clean package -DskipTests

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

