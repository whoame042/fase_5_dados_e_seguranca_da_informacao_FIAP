#!/bin/bash

# Script de teste end-to-end para validar o fluxo completo
# Cadastro de cliente -> Venda de veiculo -> Pagamento

set -e

API_URL="${API_URL:-http://localhost:8082}"
KEYCLOAK_URL="${KEYCLOAK_URL:-http://localhost:8180}"
REALM="vehicle-resale"
CLIENT_ID="vehicle-resale-api"
CLIENT_SECRET="vehicle-resale-secret"

echo "========================================"
echo "Teste End-to-End - Vehicle Resale API"
echo "========================================"
echo ""

# Funcao para obter token
get_token() {
    local username=$1
    local password=$2
    
    curl -s -X POST "${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "client_id=${CLIENT_ID}" \
        -d "client_secret=${CLIENT_SECRET}" \
        -d "grant_type=password" \
        -d "username=${username}" \
        -d "password=${password}" | jq -r '.access_token'
}

# 1. Verificar se os servicos estao ativos
echo "[1/8] Verificando health da API..."
if curl -s "${API_URL}/health/ready" | grep -q "UP"; then
    echo "    API OK"
else
    echo "    ERRO: API nao esta pronta"
    exit 1
fi

echo "[2/8] Verificando Keycloak..."
if curl -s "${KEYCLOAK_URL}/health/ready" | grep -q "UP"; then
    echo "    Keycloak OK"
else
    echo "    ERRO: Keycloak nao esta pronto"
    exit 1
fi

# 2. Obter token de admin
echo "[3/8] Obtendo token de administrador..."
ADMIN_TOKEN=$(get_token "admin@vehicleresale.com" "admin123")
if [ -z "$ADMIN_TOKEN" ] || [ "$ADMIN_TOKEN" = "null" ]; then
    echo "    ERRO: Nao foi possivel obter token de admin"
    exit 1
fi
echo "    Token obtido com sucesso"

# 3. Cadastrar veiculo
echo "[4/8] Cadastrando veiculo..."
VEHICLE_RESPONSE=$(curl -s -X POST "${API_URL}/api/vehicles" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -d '{
        "brand": "Honda",
        "model": "Civic",
        "year": 2023,
        "color": "Preto",
        "price": 120000.00
    }')

VEHICLE_ID=$(echo $VEHICLE_RESPONSE | jq -r '.id')
if [ -z "$VEHICLE_ID" ] || [ "$VEHICLE_ID" = "null" ]; then
    echo "    ERRO: Nao foi possivel cadastrar veiculo"
    echo "    Resposta: $VEHICLE_RESPONSE"
    exit 1
fi
echo "    Veiculo cadastrado - ID: $VEHICLE_ID"

# 4. Listar veiculos disponiveis
echo "[5/8] Listando veiculos disponiveis..."
AVAILABLE=$(curl -s "${API_URL}/api/vehicles/available")
COUNT=$(echo $AVAILABLE | jq '.totalElements')
echo "    Total de veiculos disponiveis: $COUNT"

# 5. Cadastrar cliente
echo "[6/8] Cadastrando cliente..."
TIMESTAMP=$(date +%s)
CUSTOMER_CPF="123456789${TIMESTAMP: -2}"
CUSTOMER_RESPONSE=$(curl -s -X POST "${API_URL}/api/customers" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -d "{
        \"name\": \"Cliente Teste\",
        \"email\": \"cliente${TIMESTAMP}@teste.com\",
        \"cpf\": \"${CUSTOMER_CPF}\",
        \"phone\": \"11999999999\",
        \"address\": \"Rua Teste, 123\",
        \"city\": \"Sao Paulo\",
        \"state\": \"SP\",
        \"zipCode\": \"01234567\"
    }")

CUSTOMER_ID=$(echo $CUSTOMER_RESPONSE | jq -r '.id')
if [ -z "$CUSTOMER_ID" ] || [ "$CUSTOMER_ID" = "null" ]; then
    echo "    ERRO: Nao foi possivel cadastrar cliente"
    echo "    Resposta: $CUSTOMER_RESPONSE"
    exit 1
fi
echo "    Cliente cadastrado - ID: $CUSTOMER_ID"

# 6. Realizar venda
echo "[7/8] Realizando venda..."
SALE_RESPONSE=$(curl -s -X POST "${API_URL}/api/sales" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -d "{
        \"vehicleId\": ${VEHICLE_ID},
        \"buyerName\": \"Cliente Teste\",
        \"buyerEmail\": \"cliente${TIMESTAMP}@teste.com\",
        \"buyerCpf\": \"${CUSTOMER_CPF}\",
        \"saleDate\": \"$(date +%Y-%m-%d)\"
    }")

SALE_ID=$(echo $SALE_RESPONSE | jq -r '.id')
PAYMENT_CODE=$(echo $SALE_RESPONSE | jq -r '.paymentCode')
if [ -z "$SALE_ID" ] || [ "$SALE_ID" = "null" ]; then
    echo "    ERRO: Nao foi possivel realizar venda"
    echo "    Resposta: $SALE_RESPONSE"
    exit 1
fi
echo "    Venda realizada - ID: $SALE_ID"
echo "    Codigo de pagamento: $PAYMENT_CODE"

# 7. Processar pagamento
echo "[8/8] Processando pagamento..."
PAYMENT_RESPONSE=$(curl -s -X POST "${API_URL}/api/webhook/payment" \
    -H "Content-Type: application/json" \
    -d "{
        \"paymentCode\": \"${PAYMENT_CODE}\",
        \"paid\": true
    }")

PAYMENT_STATUS=$(echo $PAYMENT_RESPONSE | jq -r '.paymentStatus')
if [ "$PAYMENT_STATUS" != "APPROVED" ]; then
    echo "    ERRO: Pagamento nao foi aprovado"
    echo "    Resposta: $PAYMENT_RESPONSE"
    exit 1
fi
echo "    Pagamento aprovado!"

echo ""
echo "========================================"
echo "Teste End-to-End concluido com sucesso!"
echo "========================================"
echo ""
echo "Resumo:"
echo "  - Veiculo cadastrado: ID $VEHICLE_ID"
echo "  - Cliente cadastrado: ID $CUSTOMER_ID"
echo "  - Venda realizada: ID $SALE_ID"
echo "  - Pagamento: APROVADO"

