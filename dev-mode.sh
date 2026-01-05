#!/bin/bash

##############################################################################
# Script para iniciar Quarkus em modo desenvolvimento
# Configura automaticamente Java 21 e Maven 3.9.6
##############################################################################

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Iniciando Quarkus Dev Mode (Java 21 + Maven 3.9.6)      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Limpar variáveis de ambiente do Docker Compose
unset DB_URL
unset DB_USERNAME
unset DB_PASSWORD

# Configurar ambiente
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=/home/eduardo-almeida/.sdkman/candidates/maven/3.9.6/bin:$JAVA_HOME/bin:$PATH

# Configurar senha do PostgreSQL (do docker-compose)
export DB_PASSWORD=postgres123

# Verificar configuração
echo -e "${GREEN}Configuração do ambiente:${NC}"
echo "Java: $(java -version 2>&1 | head -n 1)"
echo "Maven: $(mvn -v | head -n 1)"
echo "DB: localhost:5433 (user=postgres, db=vehicle_resale)"
echo ""

# Verificar se PostgreSQL está rodando
if ! nc -z localhost 5433 2>/dev/null; then
    echo -e "${YELLOW}⚠️  PostgreSQL não está rodando na porta 5433!${NC}"
    echo ""
    echo "Solução: Inicie o PostgreSQL com docker-compose:"
    echo "  docker-compose up -d postgres"
    echo ""
    read -p "Deseja continuar mesmo assim? (s/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

# Verificar se Keycloak está rodando
if ! nc -z localhost 8180 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Keycloak não está rodando na porta 8180!${NC}"
    echo ""
    echo "Solução: Inicie o Keycloak com docker-compose:"
    echo "  docker-compose up -d keycloak-postgres keycloak"
    echo ""
    echo "Ou use: make dev-docker"
    echo ""
    echo -e "${YELLOW}Nota: A aplicação funcionará, mas endpoints protegidos podem falhar.$(NC)"
    echo ""
fi

echo -e "${GREEN}Limpando cache do Quarkus...${NC}"
rm -rf target/ .quarkus/
echo ""

echo -e "${GREEN}Iniciando Quarkus Dev Mode na porta 8082...${NC}"
echo -e "${YELLOW}Pressione Ctrl+C para parar${NC}"
echo ""

# Iniciar Quarkus com propriedades explícitas para evitar problemas de cache
mvn clean quarkus:dev \
  -Dquarkus.http.port=8082 \
  -Dquarkus.datasource.jdbc.url=jdbc:postgresql://localhost:5433/vehicle_resale \
  -Dquarkus.datasource.username=postgres \
  -Dquarkus.datasource.password=postgres123 \
  -DskipTests

