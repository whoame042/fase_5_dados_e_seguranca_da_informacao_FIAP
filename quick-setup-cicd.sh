#!/bin/bash

################################################################################
# Quick Setup CI/CD - Vehicle Resale API
# 
# Script rápido para ativação inicial da pipeline CI/CD
# sem interações complexas.
#
# Uso: ./quick-setup-cicd.sh
################################################################################

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                                                                    ║"
echo "║      🚀 Quick Setup CI/CD - Vehicle Resale API 🚀                 ║"
echo "║                                                                    ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

# Verificar se estamos no diretório correto
if [[ ! -f "pom.xml" ]] || [[ ! -d ".github" ]]; then
    echo -e "${RED}✗ Execute este script no diretório raiz do projeto${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Estrutura .github detectada${NC}"

# Obter informações do repositório
REPO_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")
if [[ "$REPO_URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
    REPO_OWNER="${BASH_REMATCH[1]}"
    REPO_NAME="${BASH_REMATCH[2]}"
    echo -e "${GREEN}✓ Repositório: ${REPO_OWNER}/${REPO_NAME}${NC}\n"
else
    echo -e "${YELLOW}⚠ Não foi possível detectar o repositório GitHub${NC}\n"
fi

# Verificar pré-requisitos básicos
echo -e "${BLUE}━━━ Verificando Pré-requisitos ━━━${NC}\n"

command -v git &> /dev/null && echo -e "${GREEN}✓ git${NC}" || echo -e "${RED}✗ git (obrigatório)${NC}"
command -v gh &> /dev/null && echo -e "${GREEN}✓ GitHub CLI${NC}" || echo -e "${YELLOW}⚠ GitHub CLI (recomendado)${NC}"
command -v kubectl &> /dev/null && echo -e "${GREEN}✓ kubectl${NC}" || echo -e "${YELLOW}⚠ kubectl (para deploy)${NC}"

echo ""

# Validar estrutura
echo -e "${BLUE}━━━ Validando Estrutura ━━━${NC}\n"

workflows=("ci.yml" "cd.yml" "pr-check.yml" "release.yml" "security-scan.yml")
for workflow in "${workflows[@]}"; do
    if [[ -f ".github/workflows/$workflow" ]]; then
        echo -e "${GREEN}✓ $workflow${NC}"
    else
        echo -e "${RED}✗ $workflow${NC}"
    fi
done

echo ""

# Instruções de configuração
echo -e "${BLUE}━━━ Próximas Etapas ━━━${NC}\n"

echo -e "${YELLOW}1. Configurar Secrets (OBRIGATÓRIO)${NC}"
echo "   Acesse: https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/secrets/actions"
echo ""
echo "   Secrets necessários:"
echo "   • KUBECONFIG_PRODUCTION - Kubeconfig do cluster (base64)"
echo ""
echo "   Secrets opcionais:"
echo "   • KUBECONFIG_STAGING"
echo "   • SONAR_TOKEN"
echo "   • CODECOV_TOKEN"
echo "   • SLACK_WEBHOOK_URL"
echo ""

echo -e "${YELLOW}2. Criar Environments${NC}"
echo "   Acesse: https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/environments"
echo ""
echo "   • staging - Deploy automático"
echo "   • production - Requer aprovação"
echo ""

echo -e "${YELLOW}3. Configurar Branch Protection${NC}"
echo "   Acesse: https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/branches"
echo ""
echo "   Para 'main':"
echo "   ✓ Require pull request before merging"
echo "   ✓ Require approvals (1)"
echo "   ✓ Require status checks: build-and-test, code-quality"
echo ""

echo -e "${YELLOW}4. Testar Pipeline${NC}"
echo "   Crie um PR de teste ou faça push para main:"
echo ""
echo "   git checkout -b test/cicd-setup"
echo "   git commit --allow-empty -m 'test: CI/CD setup'"
echo "   git push origin test/cicd-setup"
echo "   gh pr create --base main --title 'test: CI/CD setup'"
echo ""

echo -e "${BLUE}━━━ Comandos Úteis ━━━${NC}\n"

if command -v gh &> /dev/null; then
    echo "# Configurar secret (exemplo):"
    echo "gh secret set KUBECONFIG_PRODUCTION < kubeconfig.base64"
    echo ""
    echo "# Listar secrets:"
    echo "gh secret list"
    echo ""
    echo "# Ver workflows:"
    echo "gh workflow list"
    echo ""
    echo "# Ver execuções:"
    echo "gh run list"
    echo ""
fi

echo "# Gerar kubeconfig base64:"
echo "cat ~/.kube/config | base64 -w 0"
echo ""

echo -e "${BLUE}━━━ Documentação ━━━${NC}\n"

echo "📚 Setup Completo: .github/SETUP_GUIDE.md"
echo "📖 Documentação CI/CD: .github/CICD_DOCUMENTATION.md"
echo "📊 Resumo: docs/CICD_SETUP_SUMMARY.md"
echo ""

echo -e "${GREEN}✨ Estrutura CI/CD pronta! Execute as etapas acima para ativar. ✨${NC}\n"

# Perguntar se deseja abrir o navegador
read -p "Deseja abrir a página de settings no navegador? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    url="https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/secrets/actions"
    if command -v xdg-open &> /dev/null; then
        xdg-open "$url" 2>/dev/null
    elif command -v open &> /dev/null; then
        open "$url" 2>/dev/null
    else
        echo "Abra manualmente: $url"
    fi
fi
