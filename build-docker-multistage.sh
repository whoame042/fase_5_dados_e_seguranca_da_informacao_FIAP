#!/bin/bash

################################################################################
# Build Docker Image (Multi-stage) - Vehicle Resale API
# 
# Script para fazer build usando Dockerfile multi-stage
# que compila a aplicação dentro do container
#
# Uso: ./build-docker-multistage.sh [tag]
# Exemplo: ./build-docker-multistage.sh 1.0.0
################################################################################

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Variáveis
IMAGE_NAME="${IMAGE_NAME:-vehicle-resale-api}"
IMAGE_TAG="${1:-latest}"
DOCKERFILE="${DOCKERFILE:-Dockerfile.multistage}"

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                                                                    ║"
echo "║    🐳 Build Docker Image (Multi-stage) - Vehicle Resale API 🐳   ║"
echo "║                                                                    ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

print_info "Imagem: ${IMAGE_NAME}:${IMAGE_TAG}"
print_info "Dockerfile: ${DOCKERFILE}"
echo ""

# 1. Verificar pré-requisitos
print_header "Verificando Pré-requisitos"

if ! command -v docker &> /dev/null; then
    print_error "Docker não encontrado"
    exit 1
fi

if [[ ! -f "$DOCKERFILE" ]]; then
    print_error "Dockerfile não encontrado: $DOCKERFILE"
    exit 1
fi

print_success "Pré-requisitos OK"

# 2. Build da imagem Docker (multi-stage)
print_header "Build da Imagem Docker (Multi-stage)"

print_info "Construindo imagem ${IMAGE_NAME}:${IMAGE_TAG}..."
print_info "Este processo compila a aplicação DENTRO do container"
echo ""

# Verificar se deve usar buildx
if docker buildx version &> /dev/null; then
    print_info "Usando docker buildx"
    docker buildx build \
        --file "$DOCKERFILE" \
        --tag "${IMAGE_NAME}:${IMAGE_TAG}" \
        --tag "${IMAGE_NAME}:latest" \
        --progress=plain \
        --load \
        .
else
    print_info "Usando docker build"
    docker build \
        --file "$DOCKERFILE" \
        --tag "${IMAGE_NAME}:${IMAGE_TAG}" \
        --tag "${IMAGE_NAME}:latest" \
        .
fi

print_success "Imagem Docker criada"

# 3. Verificar imagem criada
print_header "Verificando Imagem"

if docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" &> /dev/null; then
    print_success "Imagem ${IMAGE_NAME}:${IMAGE_TAG} criada com sucesso"
    
    # Mostrar informações da imagem
    echo ""
    print_info "Informações da imagem:"
    docker images "${IMAGE_NAME}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
else
    print_error "Imagem não foi criada corretamente"
    exit 1
fi

# 4. Resumo
print_header "Resumo"

echo -e "${GREEN}✨ Build multi-stage concluído com sucesso! ✨${NC}\n"

echo "📦 Imagem criada:"
echo "   ${IMAGE_NAME}:${IMAGE_TAG}"
echo "   ${IMAGE_NAME}:latest"
echo ""

echo "✅ Vantagens do multi-stage build:"
echo "   • Build reproduzível (não depende do ambiente local)"
echo "   • Imagem final menor (sem dependências de build)"
echo "   • Cache de layers otimizado"
echo "   • Ideal para CI/CD"
echo ""

echo "🚀 Próximos passos:"
echo ""
echo "1️⃣  Testar localmente:"
echo "   docker run -d -p 8082:8082 --name vehicle-api ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "2️⃣  Ver logs:"
echo "   docker logs -f vehicle-api"
echo ""
echo "3️⃣  Health check:"
echo "   curl http://localhost:8082/health/live"
echo "   curl http://localhost:8082/health/ready"
echo ""
echo "4️⃣  Parar container:"
echo "   docker stop vehicle-api && docker rm vehicle-api"
echo ""
echo "5️⃣  Push para registry:"
echo "   docker tag ${IMAGE_NAME}:${IMAGE_TAG} ghcr.io/SEU-USUARIO/${IMAGE_NAME}:${IMAGE_TAG}"
echo "   docker push ghcr.io/SEU-USUARIO/${IMAGE_NAME}:${IMAGE_TAG}"
echo ""

# 5. Oferecer teste rápido
read -p "Deseja testar a imagem agora? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_header "Testando Imagem"
    
    # Parar container existente se houver
    if docker ps -a --format '{{.Names}}' | grep -q "^vehicle-api-test$"; then
        print_info "Removendo container de teste anterior..."
        docker stop vehicle-api-test &> /dev/null || true
        docker rm vehicle-api-test &> /dev/null || true
    fi
    
    print_info "Iniciando container de teste..."
    docker run -d \
        --name vehicle-api-test \
        -p 8082:8082 \
        -e QUARKUS_DATASOURCE_JDBC_URL=jdbc:h2:mem:testdb \
        -e QUARKUS_DATASOURCE_USERNAME=sa \
        -e QUARKUS_DATASOURCE_PASSWORD=sa \
        -e QUARKUS_HIBERNATE_ORM_DATABASE_GENERATION=drop-and-create \
        "${IMAGE_NAME}:${IMAGE_TAG}"
    
    print_success "Container iniciado"
    print_info "Aguardando aplicação iniciar (15 segundos)..."
    sleep 15
    
    print_info "Verificando health check..."
    if curl -f http://localhost:8082/health/live &> /dev/null; then
        print_success "Aplicação está rodando! ✓"
        echo ""
        print_info "🌐 Acessível em: http://localhost:8082"
        print_info "📚 Swagger UI: http://localhost:8082/swagger-ui"
        print_info "❤️  Health Live: http://localhost:8082/health/live"
        print_info "✅ Health Ready: http://localhost:8082/health/ready"
        echo ""
        print_info "📋 Para ver logs: docker logs -f vehicle-api-test"
        print_info "🛑 Para parar: docker stop vehicle-api-test && docker rm vehicle-api-test"
    else
        print_error "Aplicação não respondeu ao health check"
        print_info "Verificando logs..."
        docker logs vehicle-api-test
    fi
fi

echo ""
