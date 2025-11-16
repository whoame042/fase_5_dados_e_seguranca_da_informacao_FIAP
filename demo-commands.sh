#!/bin/bash

##############################################################################
# Script de Demonstração - Vehicle Resale API
# Use este script como guia durante a gravação do vídeo
##############################################################################

set -e

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Demonstração - Vehicle Resale API                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

##############################################################################
# PARTE 1: PREPARAÇÃO
##############################################################################

echo -e "${GREEN}═══ PARTE 1: PREPARAÇÃO ═══${NC}"
echo ""

# Verificar ambiente
echo "1. Verificando ambiente..."
echo "Java version:"
java -version

echo ""
echo "Docker version:"
docker --version

echo ""
echo "Kubernetes version:"
kubectl version --client

echo ""
echo "Minikube status:"
minikube status

echo ""
read -p "Pressione ENTER para continuar com a compilação..."

##############################################################################
# PARTE 2: COMPILAÇÃO
##############################################################################

echo ""
echo -e "${GREEN}═══ PARTE 2: COMPILAÇÃO ═══${NC}"
echo ""
echo "2. Compilando aplicação com Maven..."
./mvnw clean package -DskipTests

echo ""
echo -e "${YELLOW}✓ Compilação concluída!${NC}"
read -p "Pressione ENTER para continuar com Docker Compose..."

##############################################################################
# PARTE 3: DOCKER COMPOSE
##############################################################################

echo ""
echo -e "${GREEN}═══ PARTE 3: DOCKER COMPOSE ═══${NC}"
echo ""

# Limpar ambiente anterior
echo "3. Limpando ambiente anterior..."
docker-compose down -v 2>/dev/null || true

echo ""
echo "4. Iniciando ambiente com Docker Compose..."
docker-compose up -d

echo ""
echo "Aguardando aplicação ficar pronta (30 segundos)..."
sleep 30

echo ""
echo "5. Verificando health check..."
curl -s http://localhost:8080/health/ready | jq .

echo ""
echo "6. Listando veículos disponíveis..."
curl -s "http://localhost:8080/vehicles?status=AVAILABLE" | jq '. | length'
echo " veículos disponíveis"

echo ""
echo "7. Buscando veículo específico (ID=1)..."
curl -s http://localhost:8080/vehicles/1 | jq .

echo ""
read -p "Pressione ENTER para criar uma venda..."

echo ""
echo "8. Criando uma venda..."
SALE_RESPONSE=$(curl -s -X POST http://localhost:8080/sales \
  -H "Content-Type: application/json" \
  -d '{
    "vehicleId": 1,
    "buyerName": "João Silva Demo",
    "buyerEmail": "joao.demo@email.com",
    "buyerCpf": "12345678901",
    "saleDate": "2025-11-14"
  }')

echo "$SALE_RESPONSE" | jq .

# Extrair payment code
PAYMENT_CODE=$(echo "$SALE_RESPONSE" | jq -r '.paymentCode')
echo ""
echo "Payment Code gerado: $PAYMENT_CODE"

echo ""
echo "9. Verificando que veículo foi vendido..."
curl -s http://localhost:8080/vehicles/1 | jq '.status'

echo ""
read -p "Pressione ENTER para simular pagamento..."

echo ""
echo "10. Simulando webhook de pagamento..."
curl -s -X POST http://localhost:8080/payment-webhook \
  -H "Content-Type: application/json" \
  -d "{
    \"paymentCode\": \"$PAYMENT_CODE\",
    \"status\": \"APPROVED\"
  }" | jq .

echo ""
echo "11. Testando validação (dados inválidos)..."
curl -s -X POST http://localhost:8080/sales \
  -H "Content-Type: application/json" \
  -d '{
    "vehicleId": 1,
    "buyerName": "AB",
    "buyerEmail": "email-invalido",
    "buyerCpf": "123"
  }' | jq .

echo ""
echo -e "${YELLOW}✓ Demonstração Docker Compose concluída!${NC}"
read -p "Pressione ENTER para continuar com Kubernetes..."

##############################################################################
# PARTE 4: KUBERNETES
##############################################################################

echo ""
echo -e "${GREEN}═══ PARTE 4: KUBERNETES ═══${NC}"
echo ""

# Parar Docker Compose
echo "12. Parando Docker Compose..."
docker-compose down

# Verificar contexto
echo ""
echo "13. Verificando contexto Kubernetes..."
kubectl config current-context

echo ""
echo "14. Limpando namespace anterior (se existir)..."
kubectl delete namespace vehicle-resale --ignore-not-found=true
sleep 5

echo ""
echo "15. Fazendo deploy com Kustomize..."
kubectl apply -k k8s/overlays/local

echo ""
echo "Aguardando pods ficarem prontos (60 segundos)..."
sleep 60

echo ""
echo "16. Verificando recursos criados..."
kubectl get all -n vehicle-resale

echo ""
echo "17. Verificando pods detalhadamente..."
kubectl get pods -n vehicle-resale -o wide

echo ""
read -p "Pressione ENTER para ver logs..."

echo ""
echo "18. Logs da aplicação..."
kubectl logs -l app=vehicle-resale-api -n vehicle-resale --tail=20

echo ""
echo "19. Logs do Job de inicialização..."
kubectl logs -l app=init-database -n vehicle-resale --tail=30

echo ""
echo "20. Verificando ConfigMaps e Secrets..."
kubectl get configmaps -n vehicle-resale
echo ""
kubectl get secrets -n vehicle-resale

echo ""
echo "21. Verificando Ingress..."
kubectl get ingress -n vehicle-resale

echo ""
echo "22. Verificando HPA (Horizontal Pod Autoscaler)..."
kubectl get hpa -n vehicle-resale

echo ""
read -p "Pressione ENTER para demonstrar Alta Disponibilidade..."

echo ""
echo "23. Demonstrando Self-Healing..."
echo "Deletando um pod da API..."
POD_TO_DELETE=$(kubectl get pods -n vehicle-resale -l app=vehicle-resale-api -o jsonpath='{.items[0].metadata.name}')
echo "Pod a ser deletado: $POD_TO_DELETE"

# Em outro terminal, rode: kubectl get pods -n vehicle-resale -w
echo ""
echo "Execute em outro terminal: kubectl get pods -n vehicle-resale -w"
echo ""
read -p "Pressione ENTER para deletar o pod..."

kubectl delete pod "$POD_TO_DELETE" -n vehicle-resale

echo ""
echo "Aguardando Kubernetes recriar o pod (30 segundos)..."
sleep 30

echo ""
echo "Verificando que novo pod foi criado:"
kubectl get pods -n vehicle-resale

echo ""
read -p "Pressione ENTER para testar a aplicação no Kubernetes..."

echo ""
echo "24. Iniciando port-forward (em background)..."
kubectl port-forward -n vehicle-resale service/local-vehicle-resale-api-service 8080:80 >/dev/null 2>&1 &
PF_PID=$!

echo "Port-forward iniciado (PID: $PF_PID)"
sleep 5

echo ""
echo "25. Testando health check..."
curl -s http://localhost:8080/health/ready | jq .

echo ""
echo "26. Listando veículos (populados pelo Job)..."
VEHICLE_COUNT=$(curl -s http://localhost:8080/vehicles | jq '. | length')
echo "Total de veículos: $VEHICLE_COUNT"

echo ""
echo "27. Criando uma venda no Kubernetes..."
curl -s -X POST http://localhost:8080/sales \
  -H "Content-Type: application/json" \
  -d '{
    "vehicleId": 5,
    "buyerName": "Maria Santos K8s",
    "buyerEmail": "maria.k8s@email.com",
    "buyerCpf": "98765432100",
    "saleDate": "2025-11-14"
  }' | jq .

echo ""
echo "Matando port-forward..."
kill $PF_PID 2>/dev/null || true

echo ""
echo -e "${YELLOW}✓ Demonstração Kubernetes concluída!${NC}"

##############################################################################
# PARTE 5: LIMPEZA (OPCIONAL)
##############################################################################

echo ""
read -p "Deseja limpar o ambiente? (s/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo "Limpando ambiente..."
    kubectl delete namespace vehicle-resale
    docker-compose down -v
    echo "Ambiente limpo!"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Demonstração Concluída!                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"

