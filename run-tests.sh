#!/bin/bash

# Script para executar testes

echo "=== Executando Testes da API de Revenda de Veiculos ==="
echo ""

echo "1. Executando testes unitarios..."
./mvnw test -Dquarkus.test.profile=test

if [ $? -ne 0 ]; then
    echo "Erro nos testes unitarios!"
    exit 1
fi

echo ""
echo "2. Executando testes de integracao..."
./mvnw verify -Dquarkus.test.profile=test

if [ $? -ne 0 ]; then
    echo "Erro nos testes de integracao!"
    exit 1
fi

echo ""
echo "=== Todos os testes passaram com sucesso! ==="
echo ""
echo "Para ver o relatorio detalhado:"
echo "  cat target/surefire-reports/*.txt"
echo ""

