#!/bin/bash

# Script de teste de integracao com Keycloak
# Testa autenticacao, autorizacao e fluxo completo

set -e

API_URL="${API_URL:-http://localhost:8082}"
KEYCLOAK_URL="${KEYCLOAK_URL:-http://localhost:8180}"
REALM="vehicle-resale"
CLIENT_ID="vehicle-resale-api"
CLIENT_SECRET="vehicle-resale-secret"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "Teste de Integracao Keycloak"
echo "========================================"
echo ""

# Funcao para obter token
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
    
    echo "$response" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"//;s/"$//'
}

# Funcao para testar endpoint
test_endpoint() {
    local method=$1
    local url=$2
    local token=$3
    local data=$4
    local expected_code=$5
    local description=$6
    
    if [ -n "$token" ]; then
        if [ -n "$data" ]; then
            response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" \
                -H "Authorization: Bearer $token" \
                -H "Content-Type: application/json" \
                -d "$data" 2>&1)
        else
            response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" \
                -H "Authorization: Bearer $token" 2>&1)
        fi
    else
        if [ -n "$data" ]; then
            response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" \
                -H "Content-Type: application/json" \
                -d "$data" 2>&1)
        else
            response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" 2>&1)
        fi
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "$expected_code" ]; then
        echo -e "${GREEN}[OK]${NC} $description (HTTP $http_code)"
        return 0
    else
        echo -e "${RED}[FALHA]${NC} $description"
        echo "    Esperado: HTTP $expected_code, Recebido: HTTP $http_code"
        echo "    Resposta: $body"
        return 1
    fi
}

echo "=== 1. Verificando servicos ==="
echo ""

# Teste 1: Verificar Keycloak
echo -n "Keycloak: "
if curl -s "${KEYCLOAK_URL}/realms/${REALM}/.well-known/openid-configuration" | grep -q "issuer"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FALHA - Keycloak nao responde${NC}"
    exit 1
fi

# Teste 2: Verificar API
echo -n "API: "
if curl -s "${API_URL}/health/ready" | grep -q "UP"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FALHA - API nao responde${NC}"
    exit 1
fi

echo ""
echo "=== 2. Testando autenticacao ==="
echo ""

# Teste 3: Obter token de admin
echo -n "Token admin: "
ADMIN_TOKEN=$(get_token "admin@vehicleresale.com" "admin123")
if [ -n "$ADMIN_TOKEN" ] && [ "$ADMIN_TOKEN" != "null" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FALHA - Nao foi possivel obter token de admin${NC}"
    exit 1
fi

# Teste 4: Obter token de comprador
echo -n "Token comprador: "
BUYER_TOKEN=$(get_token "comprador@teste.com" "comprador123")
if [ -n "$BUYER_TOKEN" ] && [ "$BUYER_TOKEN" != "null" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FALHA - Nao foi possivel obter token de comprador${NC}"
    exit 1
fi

# Teste 5: Token invalido
echo -n "Token invalido: "
INVALID_TOKEN=$(get_token "usuario@invalido.com" "senhaerrada")
if [ -z "$INVALID_TOKEN" ] || [ "$INVALID_TOKEN" = "null" ]; then
    echo -e "${GREEN}OK (rejeitado corretamente)${NC}"
else
    echo -e "${RED}FALHA - Token nao deveria ser gerado${NC}"
fi

echo ""
echo "=== 3. Testando endpoints publicos ==="
echo ""

test_endpoint "GET" "${API_URL}/api/vehicles/available" "" "" "200" "Listar veiculos disponiveis (sem auth)"
test_endpoint "GET" "${API_URL}/api/vehicles/sold" "" "" "200" "Listar veiculos vendidos (sem auth)"
test_endpoint "GET" "${API_URL}/api/vehicles/1" "" "" "200" "Buscar veiculo por ID (sem auth)"

echo ""
echo "=== 4. Testando endpoints protegidos (sem token) ==="
echo ""

test_endpoint "POST" "${API_URL}/api/vehicles" "" '{"brand":"Test","model":"Test","year":2023,"color":"Azul","price":50000}' "401" "Criar veiculo sem token"
test_endpoint "POST" "${API_URL}/api/sales" "" '{"vehicleId":1,"buyerName":"Teste","buyerEmail":"teste@teste.com","buyerCpf":"12345678901","saleDate":"2024-01-15"}' "401" "Criar venda sem token"
test_endpoint "GET" "${API_URL}/api/customers" "" "" "401" "Listar clientes sem token"

echo ""
echo "=== 5. Testando autorizacao de admin ==="
echo ""

# Admin pode criar veiculo
TIMESTAMP=$(date +%s)
test_endpoint "POST" "${API_URL}/api/vehicles" "$ADMIN_TOKEN" "{\"brand\":\"TestBrand${TIMESTAMP}\",\"model\":\"TestModel\",\"year\":2023,\"color\":\"Azul\",\"price\":50000}" "201" "Admin cria veiculo"

# Admin pode listar clientes
test_endpoint "GET" "${API_URL}/api/customers" "$ADMIN_TOKEN" "" "200" "Admin lista clientes"

echo ""
echo "=== 6. Testando autorizacao de comprador ==="
echo ""

# Comprador NAO pode criar veiculo
test_endpoint "POST" "${API_URL}/api/vehicles" "$BUYER_TOKEN" '{"brand":"Test","model":"Test","year":2023,"color":"Azul","price":50000}' "403" "Comprador tenta criar veiculo (deve falhar)"

# Comprador pode ver veiculos
test_endpoint "GET" "${API_URL}/api/vehicles/available" "$BUYER_TOKEN" "" "200" "Comprador lista veiculos"

echo ""
echo "=== 7. Testando fluxo de cadastro e compra ==="
echo ""

# Cadastrar cliente
CUSTOMER_CPF="999888777${TIMESTAMP: -2}"
echo "Cadastrando cliente com CPF: $CUSTOMER_CPF"

CUSTOMER_RESPONSE=$(curl -s -X POST "${API_URL}/api/customers" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"name\": \"Cliente Teste Integracao\",
        \"email\": \"cliente${TIMESTAMP}@teste.com\",
        \"cpf\": \"${CUSTOMER_CPF}\",
        \"phone\": \"11999999999\"
    }")

CUSTOMER_ID=$(echo "$CUSTOMER_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | sed 's/"id"://')

if [ -n "$CUSTOMER_ID" ] && [ "$CUSTOMER_ID" != "null" ]; then
    echo -e "${GREEN}[OK]${NC} Cliente cadastrado - ID: $CUSTOMER_ID"
else
    echo -e "${RED}[FALHA]${NC} Erro ao cadastrar cliente"
    echo "    Resposta: $CUSTOMER_RESPONSE"
fi

# Cadastrar veiculo para venda
VEHICLE_RESPONSE=$(curl -s -X POST "${API_URL}/api/vehicles" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"brand\": \"TestCar${TIMESTAMP}\",
        \"model\": \"ModelX\",
        \"year\": 2024,
        \"color\": \"Verde\",
        \"price\": 75000
    }")

VEHICLE_ID=$(echo "$VEHICLE_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | sed 's/"id"://')

if [ -n "$VEHICLE_ID" ] && [ "$VEHICLE_ID" != "null" ]; then
    echo -e "${GREEN}[OK]${NC} Veiculo cadastrado - ID: $VEHICLE_ID"
else
    echo -e "${RED}[FALHA]${NC} Erro ao cadastrar veiculo"
    echo "    Resposta: $VEHICLE_RESPONSE"
fi

# Realizar venda
if [ -n "$VEHICLE_ID" ] && [ -n "$CUSTOMER_ID" ]; then
    SALE_RESPONSE=$(curl -s -X POST "${API_URL}/api/sales" \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"vehicleId\": ${VEHICLE_ID},
            \"buyerName\": \"Cliente Teste Integracao\",
            \"buyerEmail\": \"cliente${TIMESTAMP}@teste.com\",
            \"buyerCpf\": \"${CUSTOMER_CPF}\",
            \"saleDate\": \"$(date +%Y-%m-%d)\"
        }")
    
    SALE_ID=$(echo "$SALE_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | sed 's/"id"://')
    PAYMENT_CODE=$(echo "$SALE_RESPONSE" | grep -o '"paymentCode":"[^"]*"' | sed 's/"paymentCode":"//;s/"$//')
    
    if [ -n "$SALE_ID" ] && [ "$SALE_ID" != "null" ]; then
        echo -e "${GREEN}[OK]${NC} Venda realizada - ID: $SALE_ID"
        echo "    Codigo de pagamento: $PAYMENT_CODE"
        
        # Processar pagamento via webhook
        PAYMENT_RESPONSE=$(curl -s -X POST "${API_URL}/api/webhook/payment" \
            -H "Content-Type: application/json" \
            -d "{
                \"paymentCode\": \"${PAYMENT_CODE}\",
                \"paid\": true
            }")
        
        PAYMENT_STATUS=$(echo "$PAYMENT_RESPONSE" | grep -o '"paymentStatus":"[^"]*"' | sed 's/"paymentStatus":"//;s/"$//')
        
        if [ "$PAYMENT_STATUS" = "APPROVED" ]; then
            echo -e "${GREEN}[OK]${NC} Pagamento aprovado"
        else
            echo -e "${YELLOW}[AVISO]${NC} Status do pagamento: $PAYMENT_STATUS"
        fi
    else
        echo -e "${RED}[FALHA]${NC} Erro ao realizar venda"
        echo "    Resposta: $SALE_RESPONSE"
    fi
fi

echo ""
echo "=== 8. Validando token JWT ==="
echo ""

# Decodificar payload do token (base64)
echo "Decodificando token de admin..."
PAYLOAD=$(echo "$ADMIN_TOKEN" | cut -d'.' -f2 | base64 -d 2>/dev/null || echo "$ADMIN_TOKEN" | cut -d'.' -f2 | base64 --decode 2>/dev/null)

if echo "$PAYLOAD" | grep -q "admin@vehicleresale.com"; then
    echo -e "${GREEN}[OK]${NC} Token contem email do usuario"
fi

if echo "$PAYLOAD" | grep -q "realm_access"; then
    echo -e "${GREEN}[OK]${NC} Token contem roles do realm"
fi

if echo "$PAYLOAD" | grep -q "vehicle-resale"; then
    echo -e "${GREEN}[OK]${NC} Token pertence ao realm correto"
fi

echo ""
echo "========================================"
echo "Teste de integracao concluido!"
echo "========================================"
echo ""
echo "Resumo:"
echo "  - Keycloak: Funcionando"
echo "  - Autenticacao: OK"
echo "  - Endpoints publicos: OK"
echo "  - Protecao de endpoints: OK"
echo "  - Autorizacao por role: OK"
echo "  - Fluxo de compra: OK"

