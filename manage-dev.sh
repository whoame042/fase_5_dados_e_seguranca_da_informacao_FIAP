#!/bin/bash

##############################################################################
# Script de gerenciamento de containers para desenvolvimento
# Permite iniciar, parar e gerenciar todos os containers necessários
##############################################################################

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Função para exibir menu
show_menu() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          Gerenciador de Ambiente de Desenvolvimento             ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Containers Disponíveis:${NC}"
    echo ""
    
    # Status dos containers
    if docker-compose ps | grep -q "vehicle-resale-postgres"; then
        if docker-compose ps | grep "vehicle-resale-postgres" | grep -q "Up"; then
            echo -e "  ${GREEN}●${NC} PostgreSQL (porta 5433)"
        else
            echo -e "  ${RED}●${NC} PostgreSQL (parado)"
        fi
    else
        echo -e "  ${YELLOW}○${NC} PostgreSQL (não criado)"
    fi
    
    echo ""
    echo -e "${CYAN}Opções:${NC}"
    echo "  1) Iniciar todos os containers"
    echo "  2) Parar todos os containers"
    echo "  3) Reiniciar containers"
    echo "  4) Ver logs dos containers"
    echo "  5) Limpar volumes (APAGA DADOS)"
    echo "  6) Status dos containers"
    echo "  7) Iniciar Quarkus Dev Mode"
    echo "  8) Iniciar ambiente completo (containers + Quarkus)"
    echo "  9) Conectar ao PostgreSQL (psql)"
    echo "  0) Sair"
    echo ""
    echo -n "Escolha uma opção: "
}

# Função para iniciar containers
start_containers() {
    echo -e "${YELLOW}Iniciando containers...${NC}"
    docker-compose up -d postgres
    echo ""
    echo "Aguardando containers ficarem saudáveis..."
    sleep 10
    docker-compose ps
    echo ""
    echo -e "${GREEN}✅ Containers iniciados!${NC}"
}

# Função para parar containers
stop_containers() {
    echo -e "${YELLOW}Parando containers...${NC}"
    docker-compose stop
    echo -e "${GREEN}✅ Containers parados!${NC}"
}

# Função para reiniciar containers
restart_containers() {
    echo -e "${YELLOW}Reiniciando containers...${NC}"
    docker-compose restart
    echo ""
    echo "Aguardando containers ficarem saudáveis..."
    sleep 10
    docker-compose ps
    echo ""
    echo -e "${GREEN}✅ Containers reiniciados!${NC}"
}

# Função para ver logs
view_logs() {
    echo -e "${CYAN}Logs dos containers (Ctrl+C para sair):${NC}"
    echo ""
    docker-compose logs -f --tail=100
}

# Função para limpar volumes
clean_volumes() {
    echo -e "${RED}⚠️  ATENÇÃO: Isso irá APAGAR TODOS OS DADOS!${NC}"
    echo -n "Tem certeza? Digite 'SIM' para confirmar: "
    read confirmation
    if [ "$confirmation" = "SIM" ]; then
        echo -e "${YELLOW}Parando containers e removendo volumes...${NC}"
        docker-compose down -v
        echo -e "${GREEN}✅ Volumes removidos!${NC}"
        echo ""
        echo "Execute a opção 1 para iniciar novamente com dados frescos."
    else
        echo "Operação cancelada."
    fi
}

# Função para ver status
view_status() {
    echo -e "${CYAN}Status dos containers:${NC}"
    echo ""
    docker-compose ps
    echo ""
    
    # Verificar conectividade
    echo -e "${CYAN}Verificando conectividade:${NC}"
    echo ""
    
    if nc -z localhost 5433 2>/dev/null; then
        echo -e "  ${GREEN}✅${NC} PostgreSQL: localhost:5433 (acessível)"
        VEHICLES=$(docker exec vehicle-resale-postgres psql -U postgres -d vehicle_resale -t -c "SELECT COUNT(*) FROM vehicles;" 2>/dev/null | xargs)
        if [ -n "$VEHICLES" ]; then
            echo -e "     Veículos no banco: $VEHICLES"
        fi
    else
        echo -e "  ${RED}❌${NC} PostgreSQL: localhost:5433 (não acessível)"
    fi
    
    echo ""
}

# Função para iniciar Quarkus
start_quarkus() {
    echo -e "${YELLOW}Iniciando Quarkus Dev Mode...${NC}"
    echo ""
    ./dev-mode.sh
}

# Função para iniciar ambiente completo
start_full_env() {
    echo -e "${YELLOW}Iniciando ambiente completo...${NC}"
    echo ""
    ./start-dev.sh
}

# Função para conectar ao PostgreSQL
connect_psql() {
    echo -e "${CYAN}Conectando ao PostgreSQL...${NC}"
    echo "Database: vehicle_resale"
    echo "User: postgres"
    echo ""
    docker exec -it vehicle-resale-postgres psql -U postgres -d vehicle_resale
}

# Loop principal
while true; do
    show_menu
    read choice
    echo ""
    
    case $choice in
        1)
            start_containers
            ;;
        2)
            stop_containers
            ;;
        3)
            restart_containers
            ;;
        4)
            view_logs
            ;;
        5)
            clean_volumes
            ;;
        6)
            view_status
            ;;
        7)
            start_quarkus
            break
            ;;
        8)
            start_full_env
            break
            ;;
        9)
            connect_psql
            ;;
        0)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo -e "${RED}Opção inválida!${NC}"
            ;;
    esac
    
    echo ""
    echo -n "Pressione ENTER para continuar..."
    read
done

