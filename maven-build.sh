#!/bin/bash

##############################################################################
# Script para executar o Maven com as versões corretas do Java e Maven
# Este script configura Java 21 e Maven 3.9.6 que são compatíveis com Quarkus 3.6.4
##############################################################################

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Verificar se algum argumento foi passado
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ Erro: Nenhum goal do Maven foi especificado${NC}"
    echo ""
    echo -e "${YELLOW}Uso:${NC}"
    echo "  ./maven-build.sh <goal> [opções]"
    echo ""
    echo -e "${YELLOW}Exemplos:${NC}"
    echo "  ./maven-build.sh clean compile"
    echo "  ./maven-build.sh clean package"
    echo "  ./maven-build.sh clean install"
    echo "  ./maven-build.sh quarkus:dev"
    echo "  ./maven-build.sh test"
    echo ""
    echo -e "${YELLOW}Ou use os scripts específicos:${NC}"
    echo "  ./dev-mode.sh          - Inicia em modo desenvolvimento"
    echo "  ./build-and-deploy.sh  - Build e deploy completo"
    echo "  ./run-tests.sh         - Executa testes"
    echo ""
    exit 1
fi

export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=/home/eduardo-almeida/.sdkman/candidates/maven/3.9.6/bin:$JAVA_HOME/bin:$PATH

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Executando Maven com configuração                ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Configuração:${NC}"
echo "Java: $(java -version 2>&1 | head -n 1)"
echo "Maven: $(mvn -version | head -n 1)"
echo ""
echo -e "${YELLOW}Executando: mvn $@${NC}"
echo ""

mvn "$@"



