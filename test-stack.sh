#!/bin/bash

# Script completo de teste da stack Vehicle Resale API
# Testa todos os componentes: Keycloak, API, Banco de dados, fluxos completos

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
API_URL="${API_URL:-http://localhost:8082}"
KEYCLOAK_URL="${KEYCLOAK_URL:-http://localhost:8180}"
REALM="vehicle-resale"
CLIENT_ID="vehicle-resale-api"
CLIENT_SECRET="vehicle-resale-secret"

# Usuários de teste
ADMIN_USER="admin@vehicleresale.com"
ADMIN_PASS="admin123"
BUYER_USER="comprador@teste.com"
BUYER_PASS="comprador123"

# Variáveis globais
ADMIN_TOKEN=""
BUYER_TOKEN=""
VEHICLE_ID=""
CUSTOMER_ID=""
SALE_ID=""
PAYMENT_CODE=""

# Contadores
TESTS_PASSED=0
TESTS_FAILED=0

echo "========================================"
echo "  TESTE COMPLETO DA STACK"
echo "  Vehicle Resale API"
echo "========================================"
echo ""

# Função para imprimir resultado
print_result() {
    local test_name=$1
    local status=$2
    local message=$3
    
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} $test_name"
        echo -e "  ${RED}Erro:${NC} $message"
        ((TESTS_FAILED++))
    fi
}

# Função para obter token
get_token() {
    local username=$1
    local password=$2
    
    local response=$(curl -s -X POST "${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "client_id=${CLIENT_ID}" \
        -d "client_secret=${CLIENT_SECRET}" \
        -d "grant_type=password" \
        -d "username=${username}" \
        -d "password=${password}" 2>&1)
    
    if echo "$response" | grep -q "access_token"; then
        echo "$response" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"//;s/"$//'
    else
        echo ""
    fi
}

# Função para fazer requisição HTTP
http_request() {
    local method=$1
    local endpoint=$2
    local token=$3
    local data=$4
    
    if [ -n "$token" ]; then
        if [ -n "$data" ]; then
            curl -s -X "$method" "${API_URL}${endpoint}" \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $token" \
                -d "$data"
        else
            curl -s -X "$method" "${API_URL}${endpoint}" \
                -H "Authorization: Bearer $token"
        fi
    else
        if [ -n "$data" ]; then
            curl -s -X "$method" "${API_URL}${endpoint}" \
                -H "Content-Type: application/json" \
                -d "$data"
        else
            curl -s -X "$method" "${API_URL}${endpoint}"
        fi
    fi
}

# ============================================
# 1. VERIFICAÇÃO DE SERVIÇOS
# ============================================
echo -e "${BLUE}=== 1. Verificação de Serviços ===${NC}"
echo ""

# Teste 1.1: Health check da API
echo -n "Testando health check da API... "
HEALTH_RESPONSE=$(http_request "GET" "/health" "")
if echo "$HEALTH_RESPONSE" | grep -q '"status":"UP"'; then
    print_result "Health check da API" "PASS" ""
else
    print_result "Health check da API" "FAIL" "Resposta: $HEALTH_RESPONSE"
fi

# Teste 1.2: Health check do Keycloak
echo -n "Testando health check do Keycloak... "
KEYCLOAK_HEALTH=$(curl -s "${KEYCLOAK_URL}/health/ready" 2>&1)
if echo "$KEYCLOAK_HEALTH" | grep -q '"status":"UP"'; then
    print_result "Health check do Keycloak" "PASS" ""
else
    print_result "Health check do Keycloak" "FAIL" "Resposta: $KEYCLOAK_HEALTH"
fi

# Teste 1.3: Verificar containers Docker
echo -n "Verificando containers Docker... "
if docker compose ps | grep -q "vehicle-resale-api.*Up"; then
    print_result "Container da API rodando" "PASS" ""
else
    print_result "Container da API rodando" "FAIL" "Container não está rodando"
fi

echo ""

# ============================================
# 2. AUTENTICAÇÃO COM KEYCLOAK
# ============================================
echo -e "${BLUE}=== 2. Autenticação com Keycloak ===${NC}"
echo ""

# Teste 2.1: Obter token de admin
echo -n "Obtendo token de administrador... "
ADMIN_TOKEN=$(get_token "$ADMIN_USER" "$ADMIN_PASS")
if [ -n "$ADMIN_TOKEN" ]; then
    print_result "Token de admin obtido" "PASS" ""
else
    print_result "Token de admin obtido" "FAIL" "Não foi possível obter token"
    echo -e "${RED}Erro: Não é possível continuar sem token de admin${NC}"
    exit 1
fi

# Teste 2.2: Obter token de comprador
echo -n "Obtendo token de comprador... "
BUYER_TOKEN=$(get_token "$BUYER_USER" "$BUYER_PASS")
if [ -n "$BUYER_TOKEN" ]; then
    print_result "Token de comprador obtido" "PASS" ""
else
    print_result "Token de comprador obtido" "FAIL" "Não foi possível obter token"
fi

# Teste 2.3: Validar token de admin
echo -n "Validando token de admin... "
VALIDATE_RESPONSE=$(http_request "GET" "/api/customers/me" "$ADMIN_TOKEN")
if echo "$VALIDATE_RESPONSE" | grep -q "userId\|email"; then
    print_result "Token de admin válido" "PASS" ""
else
    print_result "Token de admin válido" "FAIL" "Resposta: $VALIDATE_RESPONSE"
fi

echo ""

# ============================================
# 3. GESTÃO DE VEÍCULOS
# ============================================
echo -e "${BLUE}=== 3. Gestão de Veículos ===${NC}"
echo ""

# Teste 3.1: Listar veículos disponíveis (público)
echo -n "Listando veículos disponíveis (público)... "
VEHICLES_RESPONSE=$(http_request "GET" "/api/vehicles/available" "")
if echo "$VEHICLES_RESPONSE" | grep -q "content\|\[\]"; then
    print_result "Listar veículos disponíveis" "PASS" ""
else
    print_result "Listar veículos disponíveis" "FAIL" "Resposta: $VEHICLES_RESPONSE"
fi

# Teste 3.2: Cadastrar veículo (admin)
echo -n "Cadastrando veículo (admin)... "
VEHICLE_DATA='{
    "brand": "Toyota",
    "model": "Corolla",
    "year": 2023,
    "color": "Prata",
    "price": 95000.00
}'
CREATE_VEHICLE_RESPONSE=$(http_request "POST" "/api/vehicles" "$ADMIN_TOKEN" "$VEHICLE_DATA")
if echo "$CREATE_VEHICLE_RESPONSE" | grep -q '"id"'; then
    VEHICLE_ID=$(echo "$CREATE_VEHICLE_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
    print_result "Cadastrar veículo" "PASS" "ID: $VEHICLE_ID"
else
    print_result "Cadastrar veículo" "FAIL" "Resposta: $CREATE_VEHICLE_RESPONSE"
fi

# Teste 3.3: Buscar veículo por ID (público)
if [ -n "$VEHICLE_ID" ]; then
    echo -n "Buscando veículo por ID... "
    GET_VEHICLE_RESPONSE=$(http_request "GET" "/api/vehicles/$VEHICLE_ID" "")
    if echo "$GET_VEHICLE_RESPONSE" | grep -q '"id":'$VEHICLE_ID; then
        print_result "Buscar veículo por ID" "PASS" ""
    else
        print_result "Buscar veículo por ID" "FAIL" "Resposta: $GET_VEHICLE_RESPONSE"
    fi
fi

# Teste 3.4: Atualizar veículo (admin)
if [ -n "$VEHICLE_ID" ]; then
    echo -n "Atualizando veículo (admin)... "
    UPDATE_VEHICLE_DATA='{
        "brand": "Toyota",
        "model": "Corolla",
        "year": 2024,
        "color": "Branco",
        "price": 98000.00
    }'
    UPDATE_RESPONSE=$(http_request "PUT" "/api/vehicles/$VEHICLE_ID" "$ADMIN_TOKEN" "$UPDATE_VEHICLE_DATA")
    if echo "$UPDATE_RESPONSE" | grep -q '"id":'$VEHICLE_ID; then
        print_result "Atualizar veículo" "PASS" ""
    else
        print_result "Atualizar veículo" "FAIL" "Resposta: $UPDATE_RESPONSE"
    fi
fi

# Teste 3.5: Tentar cadastrar veículo sem autenticação (deve falhar)
echo -n "Tentando cadastrar veículo sem autenticação (deve falhar)... "
UNAUTH_RESPONSE=$(http_request "POST" "/api/vehicles" "" "$VEHICLE_DATA")
if echo "$UNAUTH_RESPONSE" | grep -q "401\|Unauthorized"; then
    print_result "Proteção de endpoint (sem auth)" "PASS" ""
else
    print_result "Proteção de endpoint (sem auth)" "FAIL" "Endpoint deveria estar protegido"
fi

echo ""

# ============================================
# 4. GESTÃO DE CLIENTES
# ============================================
echo -e "${BLUE}=== 4. Gestão de Clientes ===${NC}"
echo ""

# Teste 4.1: Cadastrar cliente
echo -n "Cadastrando cliente... "
CUSTOMER_DATA='{
    "name": "João Silva",
    "email": "joao.silva@teste.com",
    "cpf": "12345678901",
    "phone": "11999999999",
    "address": "Rua Exemplo, 123",
    "city": "São Paulo",
    "state": "SP",
    "zipCode": "01234567"
}'
CREATE_CUSTOMER_RESPONSE=$(http_request "POST" "/api/customers" "$BUYER_TOKEN" "$CUSTOMER_DATA")
if echo "$CREATE_CUSTOMER_RESPONSE" | grep -q '"id"'; then
    CUSTOMER_ID=$(echo "$CREATE_CUSTOMER_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
    print_result "Cadastrar cliente" "PASS" "ID: $CUSTOMER_ID"
else
    print_result "Cadastrar cliente" "FAIL" "Resposta: $CREATE_CUSTOMER_RESPONSE"
fi

# Teste 4.2: Buscar meu cadastro
echo -n "Buscando meu cadastro... "
MY_PROFILE_RESPONSE=$(http_request "GET" "/api/customers/me" "$BUYER_TOKEN")
if echo "$MY_PROFILE_RESPONSE" | grep -q '"id"'; then
    print_result "Buscar meu cadastro" "PASS" ""
else
    print_result "Buscar meu cadastro" "FAIL" "Resposta: $MY_PROFILE_RESPONSE"
fi

# Teste 4.3: Verificar CPF cadastrado
echo -n "Verificando se CPF está cadastrado... "
CHECK_CPF_RESPONSE=$(http_request "GET" "/api/customers/check/12345678901" "$BUYER_TOKEN")
if echo "$CHECK_CPF_RESPONSE" | grep -q "true\|false"; then
    print_result "Verificar CPF cadastrado" "PASS" ""
else
    print_result "Verificar CPF cadastrado" "FAIL" "Resposta: $CHECK_CPF_RESPONSE"
fi

echo ""

# ============================================
# 5. PROCESSO DE VENDA
# ============================================
echo -e "${BLUE}=== 5. Processo de Venda ===${NC}"
echo ""

# Teste 5.1: Tentar comprar sem cadastro (deve falhar)
if [ -n "$VEHICLE_ID" ]; then
    echo -n "Tentando comprar sem cadastro (deve falhar)... "
    SALE_DATA_WITHOUT_CUSTOMER='{
        "vehicleId": '$VEHICLE_ID',
        "buyerName": "Maria Santos",
        "buyerEmail": "maria@teste.com",
        "buyerCpf": "98765432100",
        "saleDate": "'$(date +%Y-%m-%d)'"
    }'
    SALE_ERROR_RESPONSE=$(http_request "POST" "/api/sales" "$BUYER_TOKEN" "$SALE_DATA_WITHOUT_CUSTOMER")
    if echo "$SALE_ERROR_RESPONSE" | grep -q "cadastrado\|CPF"; then
        print_result "Validação: compra sem cadastro" "PASS" ""
    else
        print_result "Validação: compra sem cadastro" "FAIL" "Deveria rejeitar compra sem cadastro"
    fi
fi

# Teste 5.2: Efetuar compra (com cadastro)
if [ -n "$VEHICLE_ID" ] && [ -n "$CUSTOMER_ID" ]; then
    echo -n "Efetuando compra (com cadastro)... "
    SALE_DATA='{
        "vehicleId": '$VEHICLE_ID',
        "buyerName": "João Silva",
        "buyerEmail": "joao.silva@teste.com",
        "buyerCpf": "12345678901",
        "saleDate": "'$(date +%Y-%m-%d)'"
    }'
    CREATE_SALE_RESPONSE=$(http_request "POST" "/api/sales" "$BUYER_TOKEN" "$SALE_DATA")
    if echo "$CREATE_SALE_RESPONSE" | grep -q '"id"'; then
        SALE_ID=$(echo "$CREATE_SALE_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
        PAYMENT_CODE=$(echo "$CREATE_SALE_RESPONSE" | grep -o '"paymentCode":"[^"]*"' | sed 's/"paymentCode":"//;s/"$//')
        print_result "Efetuar compra" "PASS" "ID: $SALE_ID, Código: $PAYMENT_CODE"
    else
        print_result "Efetuar compra" "FAIL" "Resposta: $CREATE_SALE_RESPONSE"
    fi
fi

# Teste 5.3: Buscar venda por ID
if [ -n "$SALE_ID" ]; then
    echo -n "Buscando venda por ID... "
    GET_SALE_RESPONSE=$(http_request "GET" "/api/sales/$SALE_ID" "$BUYER_TOKEN")
    if echo "$GET_SALE_RESPONSE" | grep -q '"id":'$SALE_ID; then
        print_result "Buscar venda por ID" "PASS" ""
    else
        print_result "Buscar venda por ID" "FAIL" "Resposta: $GET_SALE_RESPONSE"
    fi
fi

# Teste 5.4: Verificar se veículo foi marcado como vendido
if [ -n "$VEHICLE_ID" ]; then
    echo -n "Verificando se veículo foi marcado como vendido... "
    VEHICLE_STATUS_RESPONSE=$(http_request "GET" "/api/vehicles/$VEHICLE_ID" "")
    if echo "$VEHICLE_STATUS_RESPONSE" | grep -q '"status":"SOLD"'; then
        print_result "Veículo marcado como vendido" "PASS" ""
    else
        print_result "Veículo marcado como vendido" "FAIL" "Resposta: $VEHICLE_STATUS_RESPONSE"
    fi
fi

# Teste 5.5: Listar veículos vendidos
echo -n "Listando veículos vendidos... "
SOLD_VEHICLES_RESPONSE=$(http_request "GET" "/api/vehicles/sold" "")
if echo "$SOLD_VEHICLES_RESPONSE" | grep -q "content\|\[\]"; then
    print_result "Listar veículos vendidos" "PASS" ""
else
    print_result "Listar veículos vendidos" "FAIL" "Resposta: $SOLD_VEHICLES_RESPONSE"
fi

echo ""

# ============================================
# 6. WEBHOOK DE PAGAMENTO
# ============================================
echo -e "${BLUE}=== 6. Webhook de Pagamento ===${NC}"
echo ""

# Teste 6.1: Processar pagamento aprovado
if [ -n "$PAYMENT_CODE" ]; then
    echo -n "Processando pagamento aprovado... "
    PAYMENT_DATA='{
        "paymentCode": "'$PAYMENT_CODE'",
        "paid": true
    }'
    PAYMENT_RESPONSE=$(http_request "POST" "/api/webhook/payment" "" "$PAYMENT_DATA")
    if echo "$PAYMENT_RESPONSE" | grep -q '"paymentStatus":"APPROVED"'; then
        print_result "Processar pagamento aprovado" "PASS" ""
    else
        print_result "Processar pagamento aprovado" "FAIL" "Resposta: $PAYMENT_RESPONSE"
    fi
fi

echo ""

# ============================================
# 7. TESTES DE SEGURANÇA
# ============================================
echo -e "${BLUE}=== 7. Testes de Segurança ===${NC}"
echo ""

# Teste 7.1: Tentar acessar endpoint admin com token de comprador
echo -n "Tentando acessar endpoint admin com token de comprador (deve falhar)... "
ADMIN_ENDPOINT_RESPONSE=$(http_request "GET" "/api/customers" "$BUYER_TOKEN")
if echo "$ADMIN_ENDPOINT_RESPONSE" | grep -q "403\|Forbidden\|Access denied"; then
    print_result "Autorização: comprador não pode acessar admin" "PASS" ""
else
    print_result "Autorização: comprador não pode acessar admin" "FAIL" "Deveria bloquear acesso"
fi

# Teste 7.2: Tentar deletar veículo com token inválido
echo -n "Tentando deletar veículo com token inválido (deve falhar)... "
INVALID_TOKEN_RESPONSE=$(http_request "DELETE" "/api/vehicles/$VEHICLE_ID" "token-invalido")
if echo "$INVALID_TOKEN_RESPONSE" | grep -q "401\|Unauthorized"; then
    print_result "Autenticação: token inválido rejeitado" "PASS" ""
else
    print_result "Autenticação: token inválido rejeitado" "FAIL" "Deveria rejeitar token inválido"
fi

echo ""

# ============================================
# RESUMO FINAL
# ============================================
echo "========================================"
echo "  RESUMO DOS TESTES"
echo "========================================"
echo -e "${GREEN}Testes passados: $TESTS_PASSED${NC}"
echo -e "${RED}Testes falhados: $TESTS_FAILED${NC}"
echo ""

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ Todos os testes passaram!${NC}"
    exit 0
else
    echo -e "${RED}✗ Alguns testes falharam${NC}"
    exit 1
fi

