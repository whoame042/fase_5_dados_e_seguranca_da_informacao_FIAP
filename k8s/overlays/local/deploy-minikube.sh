#!/bin/bash

##############################################################################
# Script de Deploy para Minikube - Vehicle Resale API
# Este script automatiza todo o processo de deploy no Minikube
##############################################################################

set -e  # Para em caso de erro

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
IMAGE_NAME="vehicle-resale-api"
IMAGE_TAG="1.0.0"
NAMESPACE="vehicle-resale"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

log_info() { echo -e "\n${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "\n${GREEN}[SUCESSO]${NC} $1"; }
log_warn() { echo -e "\n${YELLOW}[AVISO]${NC} $1"; }
log_error() { echo -e "\n${RED}[ERRO]${NC} $1" >&2; }

# --- Verificações Iniciais ---

log_info "Verificando pré-requisitos..."

# Verificar Minikube
if ! command -v minikube &> /dev/null; then
    log_error "Minikube não encontrado. Por favor, instale o Minikube."
    exit 1
fi

# Verificar se Minikube está rodando
if ! minikube status &> /dev/null; then
    log_warn "Minikube não está rodando. Iniciando Minikube..."
    minikube start
    log_success "Minikube iniciado."
else
    log_success "Minikube está rodando."
fi

# Verificar kubectl
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl não encontrado. Por favor, instale kubectl."
    exit 1
fi

# Verificar se kubectl está configurado para Minikube
if ! kubectl cluster-info &> /dev/null; then
    log_error "Não foi possível conectar ao cluster Kubernetes."
    log_info "Configurando kubectl para Minikube..."
    minikube update-context
fi

log_success "Pré-requisitos verificados."

# --- Configurar Ambiente Docker do Minikube ---

log_info "Configurando ambiente Docker do Minikube..."
eval $(minikube docker-env)
log_success "Ambiente Docker do Minikube configurado."

# --- Compilar Aplicação ---

log_info "Compilando aplicação (Java 21 + Maven 3.9.6)..."
cd "$PROJECT_ROOT"

# Configurar Java e Maven
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=/home/eduardo-almeida/.sdkman/candidates/maven/3.9.6/bin:$JAVA_HOME/bin:$PATH

# Verificar se target/quarkus-app existe
if [ ! -d "target/quarkus-app" ]; then
    log_info "Artefatos não encontrados. Compilando..."
    mvn clean package -DskipTests
    log_success "Compilação concluída."
else
    log_info "Artefatos já existem. Pulando compilação."
    log_warn "Para recompilar, execute: mvn clean package -DskipTests"
fi

# --- Construir Imagem Docker no Minikube ---

log_info "Construindo imagem Docker no Minikube..."
log_info "Imagem: ${IMAGE_NAME}:${IMAGE_TAG}"

docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

log_success "Imagem Docker construída: ${IMAGE_NAME}:${IMAGE_TAG}"

# Verificar se a imagem foi criada
if docker images | grep -q "${IMAGE_NAME}.*${IMAGE_TAG}"; then
    log_success "Imagem verificada no ambiente Docker do Minikube."
else
    log_error "Falha ao construir imagem Docker."
    exit 1
fi

# --- Habilitar Addons do Minikube ---

log_info "Verificando addons do Minikube..."

# Ingress
if ! minikube addons list | grep -q "ingress.*enabled"; then
    log_info "Habilitando Ingress addon..."
    minikube addons enable ingress
    log_success "Ingress habilitado."
else
    log_success "Ingress já está habilitado."
fi

# Metrics Server (para HPA)
if ! minikube addons list | grep -q "metrics-server.*enabled"; then
    log_info "Habilitando Metrics Server addon..."
    minikube addons enable metrics-server
    log_success "Metrics Server habilitado."
else
    log_success "Metrics Server já está habilitado."
fi

# --- Aplicar Manifestos Kubernetes ---

log_info "Aplicando manifestos Kubernetes..."
cd "$SCRIPT_DIR"

# Verificar se kustomize está disponível
if command -v kustomize &> /dev/null; then
    KUSTOMIZE_CMD="kustomize"
elif kubectl version --client --short 2>/dev/null | grep -q "v1.14"; then
    log_warn "kustomize não encontrado, mas kubectl suporta -k flag."
    KUSTOMIZE_CMD="kubectl apply -k"
else
    log_error "kustomize não encontrado e kubectl não suporta -k."
    log_info "Instalando kustomize..."
    # Tentar instalar kustomize (pode falhar, mas vamos tentar)
    log_warn "Por favor, instale kustomize manualmente: https://kustomize.io/"
    exit 1
fi

# Aplicar com kustomize
if command -v kustomize &> /dev/null; then
    kustomize build . | kubectl apply -f -
else
    kubectl apply -k .
fi

log_success "Manifestos aplicados."

# --- Aguardar Recursos Ficarem Prontos ---

log_info "Aguardando namespace ser criado..."
kubectl wait --for=jsonpath='{.status.phase}'=Active namespace/${NAMESPACE} --timeout=30s || true

log_info "Aguardando PostgreSQL ficar pronto..."
kubectl wait --for=condition=ready pod -l app=postgres -n ${NAMESPACE} --timeout=300s || {
    log_warn "PostgreSQL não ficou pronto no tempo esperado. Verificando logs..."
    kubectl logs -l app=postgres -n ${NAMESPACE} --tail=20
}

log_info "Aguardando API ficar pronto..."
kubectl wait --for=condition=ready pod -l app=vehicle-resale-api -n ${NAMESPACE} --timeout=300s || {
    log_warn "API não ficou pronta no tempo esperado. Verificando logs..."
    kubectl logs -l app=vehicle-resale-api -n ${NAMESPACE} --tail=20
}

# --- Verificar Status ---

log_info "Status do Deploy:"
echo ""
kubectl get all -n ${NAMESPACE}

echo ""
log_info "Ingress:"
kubectl get ingress -n ${NAMESPACE} || log_warn "Ingress não encontrado."

echo ""
log_info "Pods:"
kubectl get pods -n ${NAMESPACE}

# --- Informações de Acesso ---

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ✅ DEPLOY CONCLUÍDO COM SUCESSO!                    ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Obter IP do Minikube
MINIKUBE_IP=$(minikube ip)
log_info "IP do Minikube: ${MINIKUBE_IP}"

# Verificar Ingress
INGRESS_HOST=$(kubectl get ingress -n ${NAMESPACE} -o jsonpath='{.items[0].spec.rules[0].host}' 2>/dev/null || echo "")

if [ -n "$INGRESS_HOST" ]; then
    echo ""
    log_info "Para acessar via Ingress, adicione ao /etc/hosts:"
    echo -e "${YELLOW}${MINIKUBE_IP} ${INGRESS_HOST}${NC}"
    echo ""
    log_info "URLs disponíveis:"
    echo "  - API: http://${INGRESS_HOST}"
    echo "  - Swagger UI: http://${INGRESS_HOST}/swagger-ui"
    echo "  - Health: http://${INGRESS_HOST}/health"
else
    log_warn "Ingress não configurado. Usando port-forward..."
fi

echo ""
log_info "Alternativa: Port-Forward"
echo "  kubectl port-forward -n ${NAMESPACE} service/local-vehicle-resale-api-service 8082:80"
echo "  Acesse: http://localhost:8082"
echo ""

log_info "Comandos úteis:"
echo "  # Ver logs da API:"
echo "  kubectl logs -f -n ${NAMESPACE} -l app=vehicle-resale-api"
echo ""
echo "  # Ver logs do PostgreSQL:"
echo "  kubectl logs -f -n ${NAMESPACE} -l app=postgres"
echo ""
echo "  # Ver status de todos os recursos:"
echo "  kubectl get all -n ${NAMESPACE}"
echo ""
echo "  # Desfazer deploy:"
echo "  kubectl delete namespace ${NAMESPACE}"
echo ""

log_success "Deploy concluído! 🚀"

