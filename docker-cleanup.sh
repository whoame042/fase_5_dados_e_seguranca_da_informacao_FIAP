#!/bin/bash

##############################################################################
# Script de Limpeza Docker
# Remove imagens, containers, volumes e networks não utilizados
##############################################################################

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Docker Cleanup - Limpeza Completa                   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker não está rodando${NC}"
    exit 1
fi

# Mostrar espaço usado antes
echo -e "${YELLOW}📊 Espaço usado ANTES da limpeza:${NC}"
docker system df
echo ""

# Perguntar confirmação
echo -e "${YELLOW}⚠️  ATENÇÃO: Este script irá remover:${NC}"
echo "  • Containers parados"
echo "  • Imagens não utilizadas"
echo "  • Volumes não utilizados"
echo "  • Networks não utilizadas"
echo "  • Build cache"
echo ""
read -p "Deseja continuar? (s/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}Operação cancelada${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}Iniciando limpeza...${NC}"
echo ""

# 1. Parar containers rodando (opcional)
echo -e "${YELLOW}1. Containers em execução:${NC}"
RUNNING_CONTAINERS=$(docker ps -q)
if [ -n "$RUNNING_CONTAINERS" ]; then
    echo "   Encontrados $(echo $RUNNING_CONTAINERS | wc -w) containers rodando"
    read -p "   Deseja parar todos os containers? (s/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        docker stop $(docker ps -q)
        echo -e "${GREEN}   ✅ Containers parados${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Containers mantidos em execução${NC}"
    fi
else
    echo -e "${GREEN}   ✅ Nenhum container em execução${NC}"
fi
echo ""

# 2. Remover containers parados
echo -e "${YELLOW}2. Removendo containers parados...${NC}"
STOPPED_CONTAINERS=$(docker ps -aq -f status=exited -f status=created)
if [ -n "$STOPPED_CONTAINERS" ]; then
    docker rm $STOPPED_CONTAINERS
    echo -e "${GREEN}   ✅ Containers parados removidos${NC}"
else
    echo -e "${GREEN}   ✅ Nenhum container parado${NC}"
fi
echo ""

# 3. Remover imagens não utilizadas
echo -e "${YELLOW}3. Removendo imagens não utilizadas...${NC}"
read -p "   Remover TODAS as imagens não utilizadas? (s) ou apenas as pendentes/dangling? (N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
    # Remove todas as imagens não utilizadas
    docker image prune -a -f
    echo -e "${GREEN}   ✅ Todas as imagens não utilizadas removidas${NC}"
else
    # Remove apenas imagens dangling (sem tag)
    docker image prune -f
    echo -e "${GREEN}   ✅ Imagens dangling removidas${NC}"
fi
echo ""

# 4. Remover volumes não utilizados
echo -e "${YELLOW}4. Removendo volumes não utilizados...${NC}"
read -p "   Remover volumes? (s/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
    docker volume prune -f
    echo -e "${GREEN}   ✅ Volumes não utilizados removidos${NC}"
else
    echo -e "${YELLOW}   ⚠️  Volumes mantidos${NC}"
fi
echo ""

# 5. Remover networks não utilizadas
echo -e "${YELLOW}5. Removendo networks não utilizadas...${NC}"
docker network prune -f
echo -e "${GREEN}   ✅ Networks não utilizadas removidas${NC}"
echo ""

# 6. Limpar build cache
echo -e "${YELLOW}6. Limpando build cache...${NC}"
read -p "   Remover build cache? (s/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
    docker builder prune -a -f
    echo -e "${GREEN}   ✅ Build cache removido${NC}"
else
    echo -e "${YELLOW}   ⚠️  Build cache mantido${NC}"
fi
echo ""

# 7. Limpeza do sistema completo (tudo de uma vez)
echo -e "${YELLOW}7. Limpeza adicional do sistema...${NC}"
read -p "   Executar 'docker system prune -a'? (s/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
    docker system prune -a -f
    echo -e "${GREEN}   ✅ Limpeza do sistema concluída${NC}"
else
    echo -e "${YELLOW}   ⚠️  Limpeza do sistema pulada${NC}"
fi
echo ""

# Mostrar espaço usado depois
echo -e "${YELLOW}📊 Espaço usado DEPOIS da limpeza:${NC}"
docker system df
echo ""

# Resumo
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                 Limpeza Concluída!                               ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Calcular espaço recuperado (aproximado)
echo -e "${BLUE}💾 Resumo:${NC}"
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Size}}"
echo ""

echo -e "${YELLOW}💡 Para ver imagens restantes:${NC}"
echo "   docker images"
echo ""
echo -e "${YELLOW}💡 Para ver containers restantes:${NC}"
echo "   docker ps -a"
echo ""
echo -e "${YELLOW}💡 Para ver volumes restantes:${NC}"
echo "   docker volume ls"
echo ""
