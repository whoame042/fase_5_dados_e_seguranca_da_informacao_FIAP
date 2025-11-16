#!/bin/bash

##############################################################################
# Script completo para iniciar o ambiente de desenvolvimento
# 1. Inicia o PostgreSQL via Docker Compose
# 2. Aguarda o banco ficar pronto
# 3. Inicia o Quarkus em modo dev
##############################################################################

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      Iniciando Ambiente de Desenvolvimento Completo             ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker não está rodando!${NC}"
    echo "Por favor, inicie o Docker e tente novamente."
    exit 1
fi

# Gerenciar containers
echo -e "${YELLOW}1. Gerenciando containers Docker...${NC}"

# Verificar se há containers com problemas e limpar
if docker-compose ps | grep -E "Exit|Restarting" > /dev/null 2>&1; then
    echo "   Detectados containers com problemas. Reiniciando..."
    docker-compose down > /dev/null 2>&1
fi

# Verificar se PostgreSQL está rodando e saudável
POSTGRES_RUNNING=false
if docker-compose ps | grep "vehicle-resale-postgres" | grep -q "Up (healthy)"; then
    echo -e "   ${GREEN}✅ PostgreSQL já está rodando e saudável${NC}"
    POSTGRES_RUNNING=true
elif docker-compose ps | grep "vehicle-resale-postgres" | grep -q "Up"; then
    echo "   PostgreSQL está iniciando... aguardando ficar saudável"
    POSTGRES_RUNNING=true
else
    echo "   Iniciando container PostgreSQL..."
    docker-compose up -d postgres
    POSTGRES_RUNNING=true
fi
echo ""

# Aguardar PostgreSQL ficar pronto
if [ "$POSTGRES_RUNNING" = true ]; then
    echo -e "${YELLOW}2. Aguardando PostgreSQL ficar pronto...${NC}"
    MAX_ATTEMPTS=60
    ATTEMPT=0
    
    while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
        # Verificar se o container está rodando
        if ! docker-compose ps | grep "vehicle-resale-postgres" | grep -q "Up"; then
            echo -e "\n   ${RED}❌ Container PostgreSQL parou de rodar${NC}"
            echo "   Logs do container:"
            docker-compose logs --tail=20 postgres
            exit 1
        fi
        
        # Verificar conectividade
        if docker exec vehicle-resale-postgres pg_isready -U postgres > /dev/null 2>&1; then
            echo -e "\n   ${GREEN}✅ PostgreSQL está pronto e aceitando conexões!${NC}"
            break
        fi
        
        ATTEMPT=$((ATTEMPT + 1))
        echo -n "."
        sleep 1
    done
    
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        echo -e "\n   ${RED}❌ PostgreSQL não iniciou corretamente após $MAX_ATTEMPTS segundos${NC}"
        echo "   Logs do container:"
        docker-compose logs --tail=30 postgres
        echo ""
        echo "   Tentando diagnóstico adicional..."
        docker inspect vehicle-resale-postgres | grep -A 10 "State"
        exit 1
    fi
fi
echo ""

# Verificar dados no banco
echo -e "${YELLOW}3. Verificando dados no banco...${NC}"
VEHICLE_COUNT=$(docker exec vehicle-resale-postgres psql -U postgres -d vehicle_resale -t -c "SELECT COUNT(*) FROM vehicles;" 2>/dev/null | xargs)
if [ -n "$VEHICLE_COUNT" ]; then
    echo -e "   ${GREEN}✅ $VEHICLE_COUNT veículos encontrados no banco${NC}"
else
    echo -e "   ${YELLOW}⚠️  Nenhum veículo encontrado (tabela pode estar vazia)${NC}"
fi
echo ""

# Iniciar Quarkus
echo -e "${GREEN}4. Iniciando Quarkus Dev Mode...${NC}"
echo -e "${YELLOW}   Pressione Ctrl+C para parar${NC}"
echo ""

./dev-mode.sh

