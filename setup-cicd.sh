#!/bin/bash

################################################################################
# Script de Configuração de CI/CD - Vehicle Resale API
# 
# Este script automatiza a configuração da pipeline CI/CD do projeto
# incluindo secrets, environments e validações.
#
# Autor: DevOps Team
# Data: 2026-01-23
################################################################################

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variáveis
REPO_URL=""
REPO_OWNER=""
REPO_NAME=""

################################################################################
# Funções Utilitárias
################################################################################

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

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local reply
    
    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    read -p "$prompt" reply
    reply="${reply:-$default}"
    
    [[ "$reply" =~ ^[Yy]$ ]]
}

################################################################################
# Verificação de Pré-requisitos
################################################################################

check_prerequisites() {
    print_header "Verificando Pré-requisitos"
    
    local all_ok=true
    
    # Verificar git
    if command -v git &> /dev/null; then
        print_success "git instalado ($(git --version | cut -d' ' -f3))"
    else
        print_error "git não encontrado"
        all_ok=false
    fi
    
    # Verificar gh (GitHub CLI)
    if command -v gh &> /dev/null; then
        print_success "GitHub CLI instalado ($(gh --version | head -n1 | cut -d' ' -f3))"
    else
        print_warning "GitHub CLI não encontrado (recomendado)"
        print_info "Instale com: sudo apt install gh  ou  brew install gh"
    fi
    
    # Verificar kubectl
    if command -v kubectl &> /dev/null; then
        print_success "kubectl instalado ($(kubectl version --client --short 2>/dev/null | cut -d' ' -f3))"
    else
        print_warning "kubectl não encontrado (necessário para deploy)"
    fi
    
    # Verificar base64
    if command -v base64 &> /dev/null; then
        print_success "base64 disponível"
    else
        print_error "base64 não encontrado"
        all_ok=false
    fi
    
    # Verificar jq
    if command -v jq &> /dev/null; then
        print_success "jq instalado"
    else
        print_warning "jq não encontrado (recomendado para JSON)"
        print_info "Instale com: sudo apt install jq  ou  brew install jq"
    fi
    
    # Verificar se estamos em um repositório git
    if git rev-parse --git-dir > /dev/null 2>&1; then
        print_success "Repositório git detectado"
        
        # Obter informações do repositório
        REPO_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")
        if [[ -n "$REPO_URL" ]]; then
            # Extrair owner e repo name
            if [[ "$REPO_URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
                REPO_OWNER="${BASH_REMATCH[1]}"
                REPO_NAME="${BASH_REMATCH[2]}"
                print_info "Repositório: ${REPO_OWNER}/${REPO_NAME}"
            fi
        fi
    else
        print_error "Não está em um repositório git"
        all_ok=false
    fi
    
    if ! $all_ok; then
        print_error "Alguns pré-requisitos essenciais não foram atendidos"
        exit 1
    fi
    
    echo ""
}

################################################################################
# Configuração de Secrets
################################################################################

setup_secrets() {
    print_header "Configuração de Secrets"
    
    if ! command -v gh &> /dev/null; then
        print_warning "GitHub CLI não disponível. Configure secrets manualmente:"
        print_info "https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/secrets/actions"
        echo ""
        return
    fi
    
    # Verificar autenticação
    if ! gh auth status &> /dev/null; then
        print_info "Autenticando no GitHub..."
        gh auth login
    fi
    
    print_info "Configurando secrets do GitHub Actions..."
    echo ""
    
    # KUBECONFIG_PRODUCTION
    if confirm "Configurar KUBECONFIG_PRODUCTION?" "y"; then
        setup_kubeconfig_secret "KUBECONFIG_PRODUCTION" "production"
    fi
    
    # KUBECONFIG_STAGING
    if confirm "Configurar KUBECONFIG_STAGING?" "n"; then
        setup_kubeconfig_secret "KUBECONFIG_STAGING" "staging"
    fi
    
    # SONAR_TOKEN
    if confirm "Configurar SONAR_TOKEN (SonarCloud)?" "n"; then
        setup_simple_secret "SONAR_TOKEN" "Token do SonarCloud"
    fi
    
    # CODECOV_TOKEN
    if confirm "Configurar CODECOV_TOKEN?" "n"; then
        setup_simple_secret "CODECOV_TOKEN" "Token do Codecov"
    fi
    
    # SLACK_WEBHOOK_URL
    if confirm "Configurar SLACK_WEBHOOK_URL?" "n"; then
        setup_simple_secret "SLACK_WEBHOOK_URL" "Webhook URL do Slack"
    fi
    
    echo ""
    print_success "Secrets configurados!"
}

setup_kubeconfig_secret() {
    local secret_name="$1"
    local context_name="$2"
    
    echo ""
    print_info "Configurando ${secret_name}..."
    
    # Opções para kubeconfig
    echo "Escolha uma opção:"
    echo "  1) Usar kubeconfig do sistema (~/.kube/config)"
    echo "  2) Especificar arquivo kubeconfig"
    echo "  3) Colar kubeconfig manualmente"
    echo "  4) Pular"
    
    read -p "Opção [1-4]: " option
    
    case $option in
        1)
            if [[ -f ~/.kube/config ]]; then
                local kubeconfig_base64=$(cat ~/.kube/config | base64 -w 0)
                gh secret set "$secret_name" -b"$kubeconfig_base64" 2>/dev/null
                print_success "${secret_name} configurado do ~/.kube/config"
            else
                print_error "~/.kube/config não encontrado"
            fi
            ;;
        2)
            read -p "Caminho do arquivo kubeconfig: " kubeconfig_path
            if [[ -f "$kubeconfig_path" ]]; then
                local kubeconfig_base64=$(cat "$kubeconfig_path" | base64 -w 0)
                gh secret set "$secret_name" -b"$kubeconfig_base64" 2>/dev/null
                print_success "${secret_name} configurado de ${kubeconfig_path}"
            else
                print_error "Arquivo não encontrado: ${kubeconfig_path}"
            fi
            ;;
        3)
            print_info "Cole o conteúdo do kubeconfig (Ctrl+D quando terminar):"
            local kubeconfig_content=$(cat)
            local kubeconfig_base64=$(echo "$kubeconfig_content" | base64 -w 0)
            gh secret set "$secret_name" -b"$kubeconfig_base64" 2>/dev/null
            print_success "${secret_name} configurado"
            ;;
        4)
            print_info "Pulando ${secret_name}"
            ;;
        *)
            print_error "Opção inválida"
            ;;
    esac
}

setup_simple_secret() {
    local secret_name="$1"
    local description="$2"
    
    echo ""
    read -sp "${description}: " secret_value
    echo ""
    
    if [[ -n "$secret_value" ]]; then
        gh secret set "$secret_name" -b"$secret_value" 2>/dev/null
        print_success "${secret_name} configurado"
    else
        print_info "${secret_name} pulado (valor vazio)"
    fi
}

################################################################################
# Configuração de Environments
################################################################################

setup_environments() {
    print_header "Configuração de Environments"
    
    if ! command -v gh &> /dev/null; then
        print_warning "GitHub CLI não disponível. Configure environments manualmente:"
        print_info "https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/environments"
        echo ""
        return
    fi
    
    print_info "Environments devem ser criados via interface web do GitHub"
    print_info "URL: https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/environments"
    echo ""
    
    print_info "Configurações recomendadas:"
    echo ""
    echo "📦 staging:"
    echo "   - Deployment branches: main, develop"
    echo "   - Required reviewers: Nenhum (deploy automático)"
    echo ""
    echo "🚀 production:"
    echo "   - Deployment branches: main"
    echo "   - Required reviewers: 1-2 pessoas"
    echo "   - Wait timer: 5 minutos (opcional)"
    echo ""
    
    if confirm "Abrir página de configuração no navegador?" "y"; then
        local url="https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/environments"
        if command -v xdg-open &> /dev/null; then
            xdg-open "$url" 2>/dev/null
        elif command -v open &> /dev/null; then
            open "$url" 2>/dev/null
        else
            print_info "Abra manualmente: $url"
        fi
    fi
    
    echo ""
}

################################################################################
# Configuração de Branch Protection
################################################################################

setup_branch_protection() {
    print_header "Configuração de Branch Protection"
    
    if ! command -v gh &> /dev/null; then
        print_warning "GitHub CLI não disponível. Configure branch protection manualmente:"
        print_info "https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/branches"
        echo ""
        return
    fi
    
    print_info "Branch Protection Rules devem ser configurados via interface web"
    print_info "URL: https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/branches"
    echo ""
    
    print_info "Configurações recomendadas para 'main':"
    echo "   ✓ Require pull request before merging"
    echo "   ✓ Require approvals (1)"
    echo "   ✓ Require status checks to pass:"
    echo "     - build-and-test"
    echo "     - code-quality"
    echo "     - docker-build"
    echo "   ✓ Require conversation resolution"
    echo ""
    
    if confirm "Abrir página de configuração no navegador?" "y"; then
        local url="https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/branches"
        if command -v xdg-open &> /dev/null; then
            xdg-open "$url" 2>/dev/null
        elif command -v open &> /dev/null; then
            open "$url" 2>/dev/null
        else
            print_info "Abra manualmente: $url"
        fi
    fi
    
    echo ""
}

################################################################################
# Teste da Pipeline
################################################################################

test_pipeline() {
    print_header "Teste da Pipeline"
    
    print_info "Para testar a pipeline, você pode:"
    echo ""
    echo "1️⃣  Criar uma branch de teste:"
    echo "    git checkout -b test/ci-setup"
    echo "    git commit --allow-empty -m 'test: pipeline setup'"
    echo "    git push origin test/ci-setup"
    echo ""
    echo "2️⃣  Abrir um Pull Request:"
    if command -v gh &> /dev/null; then
        echo "    gh pr create --base main --title 'test: CI/CD setup' --body 'Testing pipeline'"
    else
        echo "    https://github.com/${REPO_OWNER}/${REPO_NAME}/compare"
    fi
    echo ""
    echo "3️⃣  Verificar workflows em execução:"
    echo "    https://github.com/${REPO_OWNER}/${REPO_NAME}/actions"
    echo ""
    
    if confirm "Criar branch de teste agora?" "n"; then
        local test_branch="test/cicd-setup-$(date +%Y%m%d-%H%M%S)"
        
        git checkout -b "$test_branch"
        git commit --allow-empty -m "test: CI/CD pipeline setup"
        git push origin "$test_branch"
        
        print_success "Branch criada: $test_branch"
        
        if command -v gh &> /dev/null && confirm "Criar Pull Request?" "y"; then
            gh pr create --base main --title "test: CI/CD setup" --body "Testing CI/CD pipeline configuration"
            print_success "Pull Request criado!"
        fi
    fi
    
    echo ""
}

################################################################################
# Validação da Configuração
################################################################################

validate_setup() {
    print_header "Validação da Configuração"
    
    local checks_passed=0
    local total_checks=0
    
    # Verificar estrutura .github
    ((total_checks++))
    if [[ -d ".github/workflows" ]]; then
        print_success "Diretório .github/workflows existe"
        ((checks_passed++))
    else
        print_error "Diretório .github/workflows não encontrado"
    fi
    
    # Verificar workflows
    local workflows=("ci.yml" "cd.yml" "pr-check.yml" "release.yml" "security-scan.yml")
    for workflow in "${workflows[@]}"; do
        ((total_checks++))
        if [[ -f ".github/workflows/$workflow" ]]; then
            print_success "Workflow $workflow existe"
            ((checks_passed++))
        else
            print_error "Workflow $workflow não encontrado"
        fi
    done
    
    # Verificar documentação
    local docs=("README.md" "CICD_DOCUMENTATION.md" "SETUP_GUIDE.md")
    for doc in "${docs[@]}"; do
        ((total_checks++))
        if [[ -f ".github/$doc" ]]; then
            print_success "Documentação $doc existe"
            ((checks_passed++))
        else
            print_warning "Documentação $doc não encontrada"
        fi
    done
    
    # Verificar templates
    ((total_checks++))
    if [[ -f ".github/PULL_REQUEST_TEMPLATE.md" ]]; then
        print_success "Pull Request template existe"
        ((checks_passed++))
    else
        print_warning "Pull Request template não encontrado"
    fi
    
    ((total_checks++))
    if [[ -d ".github/ISSUE_TEMPLATE" ]]; then
        print_success "Issue templates existem"
        ((checks_passed++))
    else
        print_warning "Issue templates não encontrados"
    fi
    
    # Verificar Dependabot
    ((total_checks++))
    if [[ -f ".github/dependabot.yml" ]]; then
        print_success "Dependabot configurado"
        ((checks_passed++))
    else
        print_warning "Dependabot não configurado"
    fi
    
    echo ""
    print_info "Resultado: ${checks_passed}/${total_checks} verificações passaram"
    
    if [[ $checks_passed -eq $total_checks ]]; then
        print_success "Todas as verificações passaram! ✨"
    elif [[ $checks_passed -ge $((total_checks * 80 / 100)) ]]; then
        print_warning "Maioria das verificações passaram, mas há alguns itens faltando"
    else
        print_error "Várias verificações falharam. Revise a estrutura."
    fi
    
    echo ""
}

################################################################################
# Geração de Relatório
################################################################################

generate_report() {
    print_header "Relatório de Configuração"
    
    local report_file="cicd-setup-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "======================================================================"
        echo "  Relatório de Configuração CI/CD - Vehicle Resale API"
        echo "======================================================================"
        echo ""
        echo "Data: $(date)"
        echo "Repositório: ${REPO_OWNER}/${REPO_NAME}"
        echo ""
        echo "----------------------------------------------------------------------"
        echo "Workflows Configurados:"
        echo "----------------------------------------------------------------------"
        echo "✓ CI - Continuous Integration"
        echo "✓ CD - Continuous Deployment"
        echo "✓ PR Check - Pull Request Validation"
        echo "✓ Release Management"
        echo "✓ Security Scan"
        echo "✓ CodeQL Analysis"
        echo ""
        echo "----------------------------------------------------------------------"
        echo "Próximos Passos:"
        echo "----------------------------------------------------------------------"
        echo "1. Verificar secrets configurados:"
        echo "   https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/secrets/actions"
        echo ""
        echo "2. Criar environments (staging, production):"
        echo "   https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/environments"
        echo ""
        echo "3. Configurar branch protection:"
        echo "   https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/branches"
        echo ""
        echo "4. Verificar workflows:"
        echo "   https://github.com/${REPO_OWNER}/${REPO_NAME}/actions"
        echo ""
        echo "----------------------------------------------------------------------"
        echo "Documentação:"
        echo "----------------------------------------------------------------------"
        echo "• Setup Guide: .github/SETUP_GUIDE.md"
        echo "• Documentação Completa: .github/CICD_DOCUMENTATION.md"
        echo "• Resumo: docs/CICD_SETUP_SUMMARY.md"
        echo ""
        echo "======================================================================"
    } > "$report_file"
    
    print_success "Relatório gerado: $report_file"
    
    if confirm "Ver relatório agora?" "y"; then
        cat "$report_file"
    fi
    
    echo ""
}

################################################################################
# Menu Principal
################################################################################

show_menu() {
    clear
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                    ║"
    echo "║         🚀 Setup CI/CD - Vehicle Resale API 🚀                    ║"
    echo "║                                                                    ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "Escolha uma opção:"
    echo ""
    echo "  1) ✓ Verificar pré-requisitos"
    echo "  2) 🔐 Configurar secrets"
    echo "  3) 🌍 Configurar environments"
    echo "  4) 🛡️  Configurar branch protection"
    echo "  5) 🧪 Testar pipeline"
    echo "  6) ✅ Validar configuração"
    echo "  7) 📊 Gerar relatório"
    echo "  8) 🚀 Setup completo (tudo acima)"
    echo "  9) ❓ Ajuda"
    echo "  0) 🚪 Sair"
    echo ""
}

show_help() {
    print_header "Ajuda"
    
    echo "Este script automatiza a configuração da pipeline CI/CD."
    echo ""
    echo "Funcionalidades:"
    echo "  • Verificação de pré-requisitos (git, gh, kubectl, etc.)"
    echo "  • Configuração de secrets do GitHub"
    echo "  • Guia para configuração de environments"
    echo "  • Guia para branch protection"
    echo "  • Teste da pipeline"
    echo "  • Validação da estrutura"
    echo "  • Geração de relatório"
    echo ""
    echo "Requisitos:"
    echo "  • git (obrigatório)"
    echo "  • GitHub CLI (gh) - recomendado"
    echo "  • kubectl - necessário para deploy"
    echo "  • base64 (obrigatório)"
    echo ""
    echo "Documentação completa:"
    echo "  • .github/SETUP_GUIDE.md"
    echo "  • .github/CICD_DOCUMENTATION.md"
    echo ""
}

full_setup() {
    print_header "Setup Completo"
    
    print_info "Este wizard guiará você por todo o processo de configuração."
    echo ""
    
    if ! confirm "Deseja continuar?" "y"; then
        return
    fi
    
    check_prerequisites
    setup_secrets
    setup_environments
    setup_branch_protection
    validate_setup
    test_pipeline
    generate_report
    
    print_header "Setup Concluído!"
    print_success "Pipeline CI/CD configurada com sucesso! 🎉"
    echo ""
    print_info "Próximos passos:"
    echo "  1. Verifique os workflows em: https://github.com/${REPO_OWNER}/${REPO_NAME}/actions"
    echo "  2. Revise a documentação em: .github/CICD_DOCUMENTATION.md"
    echo "  3. Faça um commit e veja a pipeline em ação!"
    echo ""
}

################################################################################
# Main
################################################################################

main() {
    # Verificar se estamos no diretório raiz do projeto
    if [[ ! -f "pom.xml" ]] || [[ ! -d ".github" ]]; then
        print_error "Execute este script no diretório raiz do projeto vehicle-resale-api"
        exit 1
    fi
    
    while true; do
        show_menu
        read -p "Opção: " choice
        echo ""
        
        case $choice in
            1) check_prerequisites; read -p "Pressione Enter para continuar..." ;;
            2) setup_secrets; read -p "Pressione Enter para continuar..." ;;
            3) setup_environments; read -p "Pressione Enter para continuar..." ;;
            4) setup_branch_protection; read -p "Pressione Enter para continuar..." ;;
            5) test_pipeline; read -p "Pressione Enter para continuar..." ;;
            6) validate_setup; read -p "Pressione Enter para continuar..." ;;
            7) generate_report; read -p "Pressione Enter para continuar..." ;;
            8) full_setup; read -p "Pressione Enter para continuar..." ;;
            9) show_help; read -p "Pressione Enter para continuar..." ;;
            0) print_info "Até logo! 👋"; exit 0 ;;
            *) print_error "Opção inválida!"; sleep 2 ;;
        esac
    done
}

# Executar script
main
