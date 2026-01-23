#!/bin/bash

################################################################################
# Build Docker Image - Vehicle Resale API
# 
# Script para fazer build completo da aplicação e imagem Docker
#
# Uso: ./build-docker-image.sh [tag]
# Exemplo: ./build-docker-image.sh 1.0.0
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
SKIP_TESTS="${SKIP_TESTS:-false}"

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
echo "║         🐳 Build Docker Image - Vehicle Resale API 🐳             ║"
echo "║                                                                    ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

print_info "Imagem: ${IMAGE_NAME}:${IMAGE_TAG}"
print_info "Skip Tests: ${SKIP_TESTS}"
echo ""

# 1. Verificar pré-requisitos
print_header "Verificando Pré-requisitos"

if ! command -v mvn &> /dev/null && [[ ! -f ./mvnw ]]; then
    print_error "Maven não encontrado e mvnw não existe"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    print_error "Docker não encontrado"
    exit 1
fi

print_success "Pré-requisitos OK"

# 2. Limpar build anterior
print_header "Limpando Build Anterior"

if [[ -d target ]]; then
    print_info "Removendo diretório target existente..."
    rm -rf target
    print_success "Build anterior removido"
else
    print_info "Nenhum build anterior encontrado"
fi

# 3. Build da aplicação com Maven
print_header "Build da Aplicação (Maven)"

print_info "Compilando aplicação Quarkus..."

if [[ -f ./mvnw ]]; then
    chmod +x ./mvnw
    MAVEN_CMD="./mvnw"
else
    MAVEN_CMD="mvn"
fi

if [[ "$SKIP_TESTS" == "true" ]]; then
    print_info "Executando: $MAVEN_CMD clean install -DskipTests"
    $MAVEN_CMD clean install -DskipTests -B
else
    print_info "Executando: $MAVEN_CMD clean verify (com testes)"
    $MAVEN_CMD clean verify -B
fi

# Verificar se o quarkus-app foi gerado, se não, tentar package
if [[ ! -d target/quarkus-app ]]; then
    print_info "quarkus-app não gerado, tentando com quarkus:build..."
    $MAVEN_CMD quarkus:build -DskipTests -B
fi

print_success "Build Maven concluído"

# 4. Verificar artefatos gerados
print_header "Verificando Artefatos"

if [[ ! -d target/quarkus-app ]]; then
    print_error "Diretório target/quarkus-app não foi criado"
    print_error "O build Maven pode ter falhou"
    exit 1
fi

required_paths=(
    "target/quarkus-app/lib"
    "target/quarkus-app/app"
    "target/quarkus-app/quarkus"
    "target/quarkus-app/quarkus-run.jar"
)

for path in "${required_paths[@]}"; do
    if [[ -e "$path" ]]; then
        print_success "$path ✓"
    else
        print_error "$path não encontrado"
        exit 1
    fi
done

# Mostrar tamanho do artefato
if [[ -f target/quarkus-app/quarkus-run.jar ]]; then
    size=$(du -h target/quarkus-app/quarkus-run.jar | cut -f1)
    print_info "Tamanho do JAR: $size"
fi

# 5. Build da imagem Docker
print_header "Build da Imagem Docker"

print_info "Construindo imagem ${IMAGE_NAME}:${IMAGE_TAG}..."

# Verificar se deve usar buildx
if docker buildx version &> /dev/null; then
    print_info "Usando docker buildx"
    docker buildx build \
        --tag "${IMAGE_NAME}:${IMAGE_TAG}" \
        --tag "${IMAGE_NAME}:latest" \
        --load \
        .
else
    print_info "Usando docker build"
    docker build \
        --tag "${IMAGE_NAME}:${IMAGE_TAG}" \
        --tag "${IMAGE_NAME}:latest" \
        .
fi

print_success "Imagem Docker criada"

# 6. Verificar imagem criada
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

# 7. Resumo
print_header "Resumo"

echo -e "${GREEN}✨ Build concluído com sucesso! ✨${NC}\n"

echo "📦 Imagem criada:"
echo "   ${IMAGE_NAME}:${IMAGE_TAG}"
echo "   ${IMAGE_NAME}:latest"
echo ""

echo "🚀 Próximos passos:"
echo ""
echo "1️⃣  Testar localmente:"
echo "   docker run -d -p 8082:8082 --name vehicle-api ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "2️⃣  Ver logs:"
echo "   docker logs -f vehicle-api"
echo ""
echo "3️⃣  Parar container:"
echo "   docker stop vehicle-api && docker rm vehicle-api"
echo ""
echo "4️⃣  Push para registry (se necessário):"
echo "   docker tag ${IMAGE_NAME}:${IMAGE_TAG} ghcr.io/SEU-USUARIO/${IMAGE_NAME}:${IMAGE_TAG}"
echo "   docker push ghcr.io/SEU-USUARIO/${IMAGE_NAME}:${IMAGE_TAG}"
echo ""

# 8. Oferecer teste rápido
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
    print_info "Aguardando aplicação iniciar (10 segundos)..."
    sleep 10
    
    print_info "Verificando health check..."
    if curl -f http://localhost:8082/health/live &> /dev/null; then
        print_success "Aplicação está rodando! ✓"
        echo ""
        print_info "Acessível em: http://localhost:8082"
        print_info "Swagger UI: http://localhost:8082/swagger-ui"
        echo ""
        print_info "Para ver logs: docker logs -f vehicle-api-test"
        print_info "Para parar: docker stop vehicle-api-test && docker rm vehicle-api-test"
    else
        print_error "Aplicação não respondeu ao health check"
        print_info "Verificando logs..."
        docker logs vehicle-api-test
    fi
fi

echo ""
