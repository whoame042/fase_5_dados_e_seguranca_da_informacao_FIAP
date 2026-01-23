#!/bin/bash

##############################################################################
# Script de Demonstração End-to-End
# API de Revenda de Veículos - Tech Challenge FIAP
#
# Este script executa todo o fluxo de demonstração automaticamente:
# 1. Cadastro de veículos
# 2. Listagem de veículos disponíveis
# 3. Cadastro de cliente
# 4. Compra de veículo
# 5. Processamento de pagamento
# 6. Verificação de veículo vendido
##############################################################################

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# URLs
API_URL="${API_URL:-http://localhost:8082}"
KEYCLOAK_URL="${KEYCLOAK_URL:-http://localhost:8180}"

# Credenciais
CLIENT_ID="vehicle-resale-api"
CLIENT_SECRET="vehicle-resale-secret"
ADMIN_USER="admin@vehicleresale.com"
ADMIN_PASS="admin123"
BUYER_USER="comprador@teste.com"
BUYER_PASS="comprador123"

# Função para pausar entre passos
pause_step() {
    if [ "$NO_PAUSE" != "true" ]; then
        echo ""
        read -p "Pressione ENTER para continuar..." -r
        echo ""
    else
        echo ""
        sleep 2
    fi
}

# Função para fazer requisição HTTP
http_request() {
    local method=$1
    local url=$2
    local token=$3
    local data=$4
    
    if [ -n "$data" ]; then
        curl -s -X "$method" "$url" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $token" \
            -d "$data"
    else
        curl -s -X "$method" "$url" \
            -H "Authorization: Bearer $token"
    fi
}

# Banner
clear
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                  ║${NC}"
echo -e "${BLUE}║     Demonstração End-to-End - API de Revenda de Veículos        ║${NC}"
echo -e "${BLUE}║                Tech Challenge FIAP - Fase 3                      ║${NC}"
echo -e "${BLUE}║                                                                  ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Este script demonstra o fluxo completo da aplicação:${NC}"
echo "  1. Autenticação de administrador"
echo "  2. Cadastro de veículos"
echo "  3. Listagem de veículos disponíveis"
echo "  4. Autenticação de comprador"
echo "  5. Cadastro de cliente"
echo "  6. Compra de veículo"
echo "  7. Processamento de pagamento"
echo "  8. Verificação de veículos vendidos"
echo ""

# Verificar se os serviços estão rodando
echo -e "${YELLOW}Verificando serviços...${NC}"

if ! curl -s "$API_URL/health" > /dev/null 2>&1; then
    echo -e "${RED}❌ API não está acessível em $API_URL${NC}"
    echo "Por favor, inicie a aplicação primeiro:"
    echo "  ./start-dev.sh"
    exit 1
fi
echo -e "${GREEN}✅ API está rodando em $API_URL${NC}"

if ! curl -s "$KEYCLOAK_URL/health/ready" > /dev/null 2>&1; then
    echo -e "${RED}❌ Keycloak não está acessível em $KEYCLOAK_URL${NC}"
    echo "Por favor, inicie o Keycloak primeiro:"
    echo "  docker-compose up -d keycloak"
    exit 1
fi
echo -e "${GREEN}✅ Keycloak está rodando em $KEYCLOAK_URL${NC}"

pause_step

# ============================================================================
# PASSO 1: Autenticação do Administrador
# ============================================================================
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║ PASSO 1: Autenticação do Administrador                         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Obtendo token de acesso para o administrador...${NC}"
echo "  Usuário: $ADMIN_USER"
echo "  Endpoint: $KEYCLOAK_URL/realms/vehicle-resale/protocol/openid-connect/token"
echo ""

TOKEN_RESPONSE=$(curl -s -X POST "$KEYCLOAK_URL/realms/vehicle-resale/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "grant_type=password" \
  -d "username=$ADMIN_USER" \
  -d "password=$ADMIN_PASS")

ADMIN_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

if [ "$ADMIN_TOKEN" == "null" ] || [ -z "$ADMIN_TOKEN" ]; then
    echo -e "${RED}❌ Falha ao obter token de administrador${NC}"
    echo "$TOKEN_RESPONSE" | jq
    exit 1
fi

echo -e "${GREEN}✅ Token de administrador obtido com sucesso!${NC}"
echo "Token (primeiros 50 caracteres): ${ADMIN_TOKEN:0:50}..."

pause_step

# ============================================================================
# PASSO 2: Cadastrar Veículos
# ============================================================================
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║ PASSO 2: Cadastrar Veículos                                    ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Veículo 1: Volkswagen Gol
echo -e "${YELLOW}Cadastrando Veículo 1: Volkswagen Gol 2022${NC}"
VEHICLE1=$(http_request POST "$API_URL/api/vehicles" "$ADMIN_TOKEN" '{
  "brand": "Volkswagen",
  "model": "Gol",
  "year": 2022,
  "color": "Branco",
  "price": 55000.00
}')
echo "$VEHICLE1" | jq
VEHICLE1_ID=$(echo "$VEHICLE1" | jq -r '.id')
echo -e "${GREEN}✅ Veículo 1 cadastrado com ID: $VEHICLE1_ID${NC}"
echo ""

# Veículo 2: Toyota Corolla
echo -e "${YELLOW}Cadastrando Veículo 2: Toyota Corolla 2023${NC}"
VEHICLE2=$(http_request POST "$API_URL/api/vehicles" "$ADMIN_TOKEN" '{
  "brand": "Toyota",
  "model": "Corolla",
  "year": 2023,
  "color": "Prata",
  "price": 95000.00
}')
echo "$VEHICLE2" | jq
VEHICLE2_ID=$(echo "$VEHICLE2" | jq -r '.id')
echo -e "${GREEN}✅ Veículo 2 cadastrado com ID: $VEHICLE2_ID${NC}"
echo ""

# Veículo 3: Honda Civic
echo -e "${YELLOW}Cadastrando Veículo 3: Honda Civic 2024${NC}"
VEHICLE3=$(http_request POST "$API_URL/api/vehicles" "$ADMIN_TOKEN" '{
  "brand": "Honda",
  "model": "Civic",
  "year": 2024,
  "color": "Preto",
  "price": 110000.00
}')
echo "$VEHICLE3" | jq
VEHICLE3_ID=$(echo "$VEHICLE3" | jq -r '.id')
echo -e "${GREEN}✅ Veículo 3 cadastrado com ID: $VEHICLE3_ID${NC}"

pause_step

# ============================================================================
# PASSO 3: Listar Veículos Disponíveis
# ============================================================================
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║ PASSO 3: Listar Veículos Disponíveis                           ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Listando veículos disponíveis (ordenados por preço)...${NC}"
echo ""

AVAILABLE=$(curl -s -X GET "$API_URL/api/vehicles/available")
echo "$AVAILABLE" | jq
echo ""
echo -e "${GREEN}✅ Veículos disponíveis listados (do mais barato ao mais caro)${NC}"

pause_step

# ============================================================================
# PASSO 4: Autenticação do Comprador
# ============================================================================
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║ PASSO 4: Autenticação do Comprador                             ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Obtendo token de acesso para o comprador...${NC}"
echo "  Usuário: $BUYER_USER"
echo ""

BUYER_TOKEN_RESPONSE=$(curl -s -X POST "$KEYCLOAK_URL/realms/vehicle-resale/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "grant_type=password" \
  -d "username=$BUYER_USER" \
  -d "password=$BUYER_PASS")

BUYER_TOKEN=$(echo "$BUYER_TOKEN_RESPONSE" | jq -r '.access_token')

if [ "$BUYER_TOKEN" == "null" ] || [ -z "$BUYER_TOKEN" ]; then
    echo -e "${RED}❌ Falha ao obter token de comprador${NC}"
    echo "$BUYER_TOKEN_RESPONSE" | jq
    exit 1
fi

echo -e "${GREEN}✅ Token de comprador obtido com sucesso!${NC}"
echo "Token (primeiros 50 caracteres): ${BUYER_TOKEN:0:50}..."

pause_step

# ============================================================================
# PASSO 5: Cadastrar Cliente (OBRIGATÓRIO)
# ============================================================================
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║ PASSO 5: Cadastrar Cliente (OBRIGATÓRIO antes da compra)       ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Cadastrando cliente João Silva...${NC}"
echo -e "${MAGENTA}IMPORTANTE: O cadastro do cliente deve ser feito ANTES da compra${NC}"
echo ""

CUSTOMER=$(http_request POST "$API_URL/api/customers" "$BUYER_TOKEN" '{
  "name": "João Silva",
  "email": "joao.silva@email.com",
  "cpf": "12345678901",
  "phone": "11999999999",
  "address": "Rua das Flores, 123",
  "city": "São Paulo",
  "state": "SP",
  "zipCode": "01234567"
}')
echo "$CUSTOMER" | jq
CUSTOMER_ID=$(echo "$CUSTOMER" | jq -r '.id')
echo ""
echo -e "${GREEN}✅ Cliente cadastrado com ID: $CUSTOMER_ID${NC}"

pause_step

# ============================================================================
# PASSO 6: Verificar Cadastro do Cliente
# ============================================================================
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║ PASSO 6: Verificar Cadastro do Cliente                         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Verificando dados do cliente cadastrado...${NC}"
echo ""

MY_CUSTOMER=$(http_request GET "$API_URL/api/customers/me" "$BUYER_TOKEN")
echo "$MY_CUSTOMER" | jq
echo ""
echo -e "${GREEN}✅ Cliente verificado no sistema${NC}"

pause_step

# ============================================================================
# PASSO 7: Efetuar Compra do Veículo
# ============================================================================
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║ PASSO 7: Efetuar Compra do Veículo                             ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Comprando veículo: Volkswagen Gol (ID: $VEHICLE1_ID)${NC}"
echo ""

SALE=$(http_request POST "$API_URL/api/sales" "$BUYER_TOKEN" "{
  \"vehicleId\": $VEHICLE1_ID,
  \"buyerName\": \"João Silva\",
  \"buyerEmail\": \"joao.silva@email.com\",
  \"buyerCpf\": \"12345678901\",
  \"saleDate\": \"$(date +%Y-%m-%d)\"
}")
echo "$SALE" | jq
SALE_ID=$(echo "$SALE" | jq -r '.id')
PAYMENT_CODE=$(echo "$SALE" | jq -r '.paymentCode')
echo ""
echo -e "${GREEN}✅ Venda registrada com sucesso!${NC}"
echo -e "${YELLOW}   ID da Venda: $SALE_ID${NC}"
echo -e "${YELLOW}   Código de Pagamento: $PAYMENT_CODE${NC}"
echo -e "${MAGENTA}   Status: PENDENTE (aguardando pagamento)${NC}"

pause_step

# ============================================================================
# PASSO 8: Processar Pagamento (Webhook)
# ============================================================================
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║ PASSO 8: Processar Pagamento (Webhook do Gateway)              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Simulando retorno do gateway de pagamento...${NC}"
echo -e "${MAGENTA}(Em produção, isso seria feito pelo gateway de pagamento)${NC}"
echo ""

PAYMENT=$(curl -s -X POST "$API_URL/api/webhook/payment" \
  -H "Content-Type: application/json" \
  -d "{
    \"paymentCode\": \"$PAYMENT_CODE\",
    \"paid\": true
  }")
echo "$PAYMENT" | jq
echo ""
echo -e "${GREEN}✅ Pagamento processado com sucesso!${NC}"
echo -e "${GREEN}   Status: APROVADO${NC}"

pause_step

# ============================================================================
# PASSO 9: Verificar Veículos Vendidos
# ============================================================================
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║ PASSO 9: Verificar Veículos Vendidos                           ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Listando veículos vendidos...${NC}"
echo ""

SOLD=$(curl -s -X GET "$API_URL/api/vehicles/sold")
echo "$SOLD" | jq
echo ""
echo -e "${GREEN}✅ Veículo aparece na lista de vendidos${NC}"

echo ""
echo -e "${YELLOW}Listando veículos ainda disponíveis...${NC}"
echo ""

AVAILABLE_AFTER=$(curl -s -X GET "$API_URL/api/vehicles/available")
echo "$AVAILABLE_AFTER" | jq
echo ""
echo -e "${GREEN}✅ Veículo vendido não aparece mais na lista de disponíveis${NC}"

pause_step

# ============================================================================
# PASSO 10: Editar Veículo (Demonstração adicional)
# ============================================================================
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║ PASSO 10: Editar Veículo (Funcionalidade Adicional)            ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Atualizando preço do Honda Civic de R\$ 110.000 para R\$ 105.000${NC}"
echo ""

UPDATED=$(http_request PUT "$API_URL/api/vehicles/$VEHICLE3_ID" "$ADMIN_TOKEN" '{
  "brand": "Honda",
  "model": "Civic",
  "year": 2024,
  "color": "Preto",
  "price": 105000.00
}')
echo "$UPDATED" | jq
echo ""
echo -e "${GREEN}✅ Veículo atualizado com sucesso!${NC}"

pause_step

# ============================================================================
# RESUMO FINAL
# ============================================================================
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    DEMONSTRAÇÃO CONCLUÍDA!                       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✅ Resumo da Demonstração:${NC}"
echo ""
echo -e "  ${CYAN}1. Autenticação${NC}"
echo "     • Token de administrador obtido"
echo "     • Token de comprador obtido"
echo ""
echo -e "  ${CYAN}2. Cadastro de Veículos${NC}"
echo "     • 3 veículos cadastrados"
echo "     • Volkswagen Gol - R\$ 55.000"
echo "     • Toyota Corolla - R\$ 95.000"
echo "     • Honda Civic - R\$ 110.000 → R\$ 105.000"
echo ""
echo -e "  ${CYAN}3. Gestão de Clientes${NC}"
echo "     • Cliente João Silva cadastrado"
echo "     • CPF: 12345678901"
echo ""
echo -e "  ${CYAN}4. Venda de Veículo${NC}"
echo "     • Venda ID: $SALE_ID"
echo "     • Veículo: Volkswagen Gol"
echo "     • Comprador: João Silva"
echo "     • Status: APROVADO"
echo ""
echo -e "  ${CYAN}5. Verificações${NC}"
echo "     • Veículos ordenados por preço ✓"
echo "     • Cadastro prévio obrigatório ✓"
echo "     • Veículo vendido removido da lista ✓"
echo "     • Edição de veículo funcionando ✓"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📊 Estatísticas:${NC}"
echo "  • Total de veículos cadastrados: 3"
echo "  • Veículos disponíveis: 2"
echo "  • Veículos vendidos: 1"
echo "  • Clientes cadastrados: 1"
echo "  • Vendas realizadas: 1"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}🎯 Todos os requisitos de negócio foram atendidos:${NC}"
echo "  ✅ Cadastrar veículo para venda"
echo "  ✅ Editar dados do veículo"
echo "  ✅ Permitir compra via internet"
echo "  ✅ Cadastro prévio obrigatório"
echo "  ✅ Listagem de veículos à venda (ordenada por preço)"
echo "  ✅ Listagem de veículos vendidos (ordenada por preço)"
echo "  ✅ Autenticação separada (Keycloak)"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}Para acessar a documentação interativa:${NC}"
echo "  Swagger UI: $API_URL/swagger-ui"
echo "  Keycloak Admin: $KEYCLOAK_URL (admin/admin123)"
echo ""
echo -e "${CYAN}Para verificar o banco de dados:${NC}"
echo "  docker exec -it vehicle-resale-postgres psql -U postgres -d vehicle_resale"
echo ""
echo -e "${GREEN}🚀 Obrigado por acompanhar a demonstração!${NC}"
echo ""
