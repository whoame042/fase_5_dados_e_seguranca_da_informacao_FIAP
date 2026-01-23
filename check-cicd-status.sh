#!/bin/bash

################################################################################
# Check CI/CD Status - Vehicle Resale API
# 
# Script para verificar o status da pipeline CI/CD
#
# Uso: ./check-cicd-status.sh
################################################################################

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         🔍 CI/CD Status Check - Vehicle Resale API 🔍             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}\n"

# Função para check
check_item() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

# Função para warning
warn_item() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Função para info
info_item() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Contador de checks
total=0
passed=0

# 1. Estrutura de arquivos
echo -e "${BLUE}━━━ Estrutura de Arquivos ━━━${NC}\n"

((total++))
if [[ -d ".github/workflows" ]]; then
    ((passed++))
    check_item 0 "Diretório .github/workflows"
else
    check_item 1 "Diretório .github/workflows"
fi

workflows=("ci.yml" "cd.yml" "pr-check.yml" "release.yml" "security-scan.yml" "codeql.yml")
for workflow in "${workflows[@]}"; do
    ((total++))
    if [[ -f ".github/workflows/$workflow" ]]; then
        ((passed++))
        check_item 0 "Workflow: $workflow"
    else
        check_item 1 "Workflow: $workflow"
    fi
done

((total++))
if [[ -f ".github/dependabot.yml" ]]; then
    ((passed++))
    check_item 0 "Dependabot configurado"
else
    check_item 1 "Dependabot configurado"
fi

echo ""

# 2. Documentação
echo -e "${BLUE}━━━ Documentação ━━━${NC}\n"

docs=(".github/README.md" ".github/CICD_DOCUMENTATION.md" ".github/SETUP_GUIDE.md" "CICD_ACTIVATION.md")
for doc in "${docs[@]}"; do
    ((total++))
    if [[ -f "$doc" ]]; then
        ((passed++))
        check_item 0 "$(basename $doc)"
    else
        check_item 1 "$(basename $doc)"
    fi
done

echo ""

# 3. Templates
echo -e "${BLUE}━━━ Templates ━━━${NC}\n"

((total++))
if [[ -f ".github/PULL_REQUEST_TEMPLATE.md" ]]; then
    ((passed++))
    check_item 0 "Pull Request template"
else
    check_item 1 "Pull Request template"
fi

((total++))
if [[ -d ".github/ISSUE_TEMPLATE" ]]; then
    ((passed++))
    check_item 0 "Issue templates"
    
    templates=("bug_report.md" "feature_request.md" "security_vulnerability.md")
    for template in "${templates[@]}"; do
        if [[ -f ".github/ISSUE_TEMPLATE/$template" ]]; then
            info_item "  └─ $template"
        fi
    done
else
    check_item 1 "Issue templates"
fi

echo ""

# 4. Scripts
echo -e "${BLUE}━━━ Scripts de Setup ━━━${NC}\n"

scripts=("setup-cicd.sh" "quick-setup-cicd.sh" "check-cicd-status.sh")
for script in "${scripts[@]}"; do
    if [[ -f "$script" ]]; then
        if [[ -x "$script" ]]; then
            check_item 0 "$script (executável)"
        else
            warn_item "$script (não executável)"
        fi
    else
        warn_item "$script (não encontrado)"
    fi
done

echo ""

# 5. Git & GitHub
echo -e "${BLUE}━━━ Repositório Git ━━━${NC}\n"

if git rev-parse --git-dir > /dev/null 2>&1; then
    check_item 0 "Repositório git inicializado"
    
    # Branch atual
    current_branch=$(git branch --show-current 2>/dev/null)
    info_item "Branch atual: $current_branch"
    
    # Remote
    remote_url=$(git config --get remote.origin.url 2>/dev/null)
    if [[ -n "$remote_url" ]]; then
        check_item 0 "Remote configurado"
        info_item "Remote: $remote_url"
        
        # Extrair owner/repo
        if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
            owner="${BASH_REMATCH[1]}"
            repo="${BASH_REMATCH[2]}"
            info_item "Repositório: $owner/$repo"
        fi
    else
        warn_item "Remote não configurado"
    fi
else
    check_item 1 "Repositório git"
fi

echo ""

# 6. Ferramentas
echo -e "${BLUE}━━━ Ferramentas Disponíveis ━━━${NC}\n"

command -v git &> /dev/null && check_item 0 "git" || check_item 1 "git (obrigatório)"
command -v gh &> /dev/null && check_item 0 "GitHub CLI (gh)" || warn_item "GitHub CLI (recomendado)"
command -v kubectl &> /dev/null && check_item 0 "kubectl" || warn_item "kubectl (necessário para deploy)"
command -v docker &> /dev/null && check_item 0 "docker" || warn_item "docker (necessário para build local)"
command -v mvn &> /dev/null && check_item 0 "Maven (mvn)" || warn_item "Maven (verificar ./mvnw)"
command -v jq &> /dev/null && check_item 0 "jq" || warn_item "jq (útil para JSON)"

echo ""

# 7. GitHub CLI Status
if command -v gh &> /dev/null; then
    echo -e "${BLUE}━━━ GitHub CLI Status ━━━${NC}\n"
    
    if gh auth status &> /dev/null; then
        check_item 0 "Autenticado no GitHub"
        
        # Verificar secrets (se tiver acesso ao repo)
        if [[ -n "$owner" ]] && [[ -n "$repo" ]]; then
            echo -e "\n${BLUE}Secrets configurados:${NC}"
            gh secret list 2>/dev/null || warn_item "Não foi possível listar secrets"
            
            echo -e "\n${BLUE}Workflows disponíveis:${NC}"
            gh workflow list 2>/dev/null || warn_item "Não foi possível listar workflows"
            
            echo -e "\n${BLUE}Últimas execuções:${NC}"
            gh run list --limit 5 2>/dev/null || warn_item "Não foi possível listar execuções"
        fi
    else
        warn_item "Não autenticado no GitHub (execute: gh auth login)"
    fi
fi

echo ""

# 8. Resumo
echo -e "${BLUE}━━━ Resumo ━━━${NC}\n"

percentage=$((passed * 100 / total))

echo -e "Verificações: ${GREEN}$passed${NC}/${total} (${percentage}%)"

if [[ $percentage -eq 100 ]]; then
    echo -e "\n${GREEN}✨ Excelente! Estrutura CI/CD completa! ✨${NC}"
elif [[ $percentage -ge 80 ]]; then
    echo -e "\n${GREEN}✓ Boa! Estrutura CI/CD quase completa.${NC}"
elif [[ $percentage -ge 60 ]]; then
    echo -e "\n${YELLOW}⚠ Estrutura básica presente, mas faltam alguns componentes.${NC}"
else
    echo -e "\n${RED}✗ Estrutura incompleta. Execute ./setup-cicd.sh${NC}"
fi

echo ""

# 9. Próximos passos
if [[ $percentage -lt 100 ]]; then
    echo -e "${BLUE}━━━ Próximos Passos ━━━${NC}\n"
    
    if [[ $percentage -lt 80 ]]; then
        info_item "1. Verifique se você está no diretório raiz do projeto"
        info_item "2. Execute: ./setup-cicd.sh ou ./quick-setup-cicd.sh"
    else
        info_item "1. Configure secrets no GitHub"
        info_item "2. Crie environments (staging, production)"
        info_item "3. Configure branch protection"
        info_item "4. Teste a pipeline"
    fi
    
    echo ""
fi

# 10. Links úteis
echo -e "${BLUE}━━━ Documentação ━━━${NC}\n"

echo "📚 Ativação rápida:"
echo "   ./quick-setup-cicd.sh"
echo ""
echo "📖 Setup completo:"
echo "   ./setup-cicd.sh"
echo ""
echo "📝 Guias:"
echo "   • CICD_ACTIVATION.md"
echo "   • .github/SETUP_GUIDE.md"
echo "   • .github/CICD_DOCUMENTATION.md"
echo ""

if [[ -n "$owner" ]] && [[ -n "$repo" ]]; then
    echo "🔗 Links GitHub:"
    echo "   • Actions: https://github.com/$owner/$repo/actions"
    echo "   • Secrets: https://github.com/$owner/$repo/settings/secrets/actions"
    echo "   • Environments: https://github.com/$owner/$repo/settings/environments"
    echo ""
fi
