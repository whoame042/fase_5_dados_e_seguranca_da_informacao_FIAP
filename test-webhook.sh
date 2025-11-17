#!/bin/bash

##############################################################################
# Script para testar o Webhook de Pagamento
##############################################################################

API_URL="${1:-http://localhost:8082}"

echo "═══════════════════════════════════════════════════════════════"
echo "          Testando Webhook de Pagamento"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "API: $API_URL"
echo ""

# Função para criar venda
create_sale() {
    echo "1. Criando venda..."
    SALE_RESPONSE=$(curl -s -X POST "$API_URL/api/sales" \
      -H "Content-Type: application/json" \
      -d '{
        "vehicleId": 3,
        "buyerName": "João Silva",
        "buyerEmail": "joao@email.com",
        "buyerCpf": "123.456.789-00",
        "saleDate": "2024-01-15"
      }')
    
    echo "$SALE_RESPONSE" | jq .
    
    PAYMENT_CODE=$(echo "$SALE_RESPONSE" | jq -r '.paymentCode')
    
    if [ "$PAYMENT_CODE" = "null" ] || [ -z "$PAYMENT_CODE" ]; then
        echo ""
        echo "Erro: Não foi possível criar venda ou obter paymentCode!"
        exit 1
    fi
    
    echo ""
    echo "Payment Code gerado: $PAYMENT_CODE"
    echo ""
}

# Função para testar pagamento aprovado
test_approved() {
    echo "2. Testando pagamento APROVADO..."
    echo ""
    
    WEBHOOK_RESPONSE=$(curl -s -X POST "$API_URL/api/webhook/payment" \
      -H "Content-Type: application/json" \
      -d "{
        \"paymentCode\": \"$PAYMENT_CODE\",
        \"paid\": true
      }")
    
    echo "Resposta:"
    echo "$WEBHOOK_RESPONSE" | jq .
    
    STATUS=$(echo "$WEBHOOK_RESPONSE" | jq -r '.paymentStatus')
    
    if [ "$STATUS" = "APPROVED" ]; then
        echo ""
        echo "✅ SUCESSO! Status atualizado para APPROVED"
    else
        echo ""
        echo "❌ ERRO! Status esperado: APPROVED, recebido: $STATUS"
    fi
    echo ""
}

# Função para testar pagamento rejeitado
test_rejected() {
    echo "3. Criando nova venda para testar REJECTED..."
    SALE_RESPONSE=$(curl -s -X POST "$API_URL/api/sales" \
      -H "Content-Type: application/json" \
      -d '{
        "vehicleId": 6,
        "buyerName": "Maria Santos",
        "buyerEmail": "maria@email.com",
        "buyerCpf": "987.654.321-00",
        "saleDate": "2024-01-16"
      }')
    
    PAYMENT_CODE_2=$(echo "$SALE_RESPONSE" | jq -r '.paymentCode')
    
    echo ""
    echo "4. Testando pagamento REJEITADO..."
    echo ""
    
    WEBHOOK_RESPONSE=$(curl -s -X POST "$API_URL/api/webhook/payment" \
      -H "Content-Type: application/json" \
      -d "{
        \"paymentCode\": \"$PAYMENT_CODE_2\",
        \"paid\": false
      }")
    
    echo "Resposta:"
    echo "$WEBHOOK_RESPONSE" | jq .
    
    STATUS=$(echo "$WEBHOOK_RESPONSE" | jq -r '.paymentStatus')
    
    if [ "$STATUS" = "REJECTED" ]; then
        echo ""
        echo "✅ SUCESSO! Status atualizado para REJECTED"
    else
        echo ""
        echo "❌ ERRO! Status esperado: REJECTED, recebido: $STATUS"
    fi
    echo ""
}

# Executar testes
create_sale
test_approved
test_rejected

echo "═══════════════════════════════════════════════════════════════"
echo "          Testes de Webhook Concluídos!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Status esperados:"
echo "  - Pagamento aprovado (paid: true)  → APPROVED ✅"
echo "  - Pagamento rejeitado (paid: false) → REJECTED ✅"
echo ""
echo "Valores antigos (que causavam erro):"
echo "  - PAID (removido)"
echo "  - CANCELLED (removido)"
echo ""

