# 🔄 CI/CD Infrastructure

Esta pasta contém toda a infraestrutura de CI/CD do projeto Vehicle Resale API utilizando GitHub Actions.

## 📁 Estrutura

```
.github/
├── workflows/              # GitHub Actions workflows
│   ├── ci.yml             # Integração Contínua
│   ├── cd.yml             # Deploy Contínuo
│   ├── pr-check.yml       # Validação de PRs
│   ├── release.yml        # Gerenciamento de Releases
│   └── security-scan.yml  # Scans de Segurança
├── ISSUE_TEMPLATE/        # Templates para Issues
│   ├── bug_report.md      # Template para bugs
│   ├── feature_request.md # Template para features
│   └── security_vulnerability.md # Template para vulnerabilidades
├── PULL_REQUEST_TEMPLATE.md # Template para Pull Requests
├── dependabot.yml         # Configuração do Dependabot
├── CICD_DOCUMENTATION.md  # Documentação completa de CI/CD
└── README.md             # Este arquivo
```

## 🚀 Workflows Disponíveis

### 1. CI - Continuous Integration
- **Arquivo**: `workflows/ci.yml`
- **Trigger**: Push/PR em main, develop, feature/*
- **Tempo**: ~10 minutos
- **Funções**:
  - Build e testes
  - Análise de qualidade de código
  - Build de imagem Docker
  - Scan de segurança

### 2. CD - Continuous Deployment
- **Arquivo**: `workflows/cd.yml`
- **Trigger**: Push para main, tags v*.*.*
- **Tempo**: ~20 minutos
- **Funções**:
  - Build e push de imagem
  - Deploy em staging (automático)
  - Deploy em produção (manual, com aprovação)
  - Rollback automático em falhas

### 3. PR Check - Pull Request Validation
- **Arquivo**: `workflows/pr-check.yml`
- **Trigger**: Pull Requests
- **Tempo**: ~12 minutos
- **Funções**:
  - Validação de título (Conventional Commits)
  - Lint e formatação
  - Testes e cobertura
  - Security checks
  - Labels automáticos

### 4. Release Management
- **Arquivo**: `workflows/release.yml`
- **Trigger**: Tags v*.*.*
- **Tempo**: ~15 minutos
- **Funções**:
  - Validação de versão
  - Build de release
  - Geração de changelog
  - Criação de GitHub Release
  - Notificações

### 5. Security Scan
- **Arquivo**: `workflows/security-scan.yml`
- **Trigger**: Schedule diário + push/PR
- **Tempo**: ~18 minutos
- **Funções**:
  - Dependency scan (OWASP)
  - Code scan (CodeQL)
  - Container scan (Trivy)
  - Secret detection
  - License compliance

## 🔧 Configuração Necessária

### Secrets Obrigatórios

Configure em: `Settings → Secrets and variables → Actions`

```bash
KUBECONFIG_PRODUCTION    # Kubeconfig do cluster de produção (base64)
```

### Secrets Opcionais

```bash
KUBECONFIG_STAGING       # Kubeconfig do cluster de staging (base64)
SONAR_TOKEN             # Token do SonarCloud
CODECOV_TOKEN           # Token do Codecov
SLACK_WEBHOOK_URL       # Webhook do Slack para notificações
```

### Environments

Configure em: `Settings → Environments`

1. **staging**: Deploy automático, sem aprovação
2. **production**: Requer aprovação de 1-2 revisores

### Branch Protection

Configure em: `Settings → Branches → Branch protection rules`

**Para `main`**:
- ✅ Require PR before merging
- ✅ Require 1 approval
- ✅ Require status checks: `build-and-test`, `code-quality`, `security-scan`
- ✅ Require conversation resolution

## 📊 Status Badges

Adicione ao README principal:

```markdown
[![CI](https://github.com/USER/REPO/workflows/CI%20-%20Continuous%20Integration/badge.svg)](https://github.com/USER/REPO/actions/workflows/ci.yml)
[![CD](https://github.com/USER/REPO/workflows/CD%20-%20Continuous%20Deployment/badge.svg)](https://github.com/USER/REPO/actions/workflows/cd.yml)
[![Security](https://github.com/USER/REPO/workflows/Security%20Scan/badge.svg)](https://github.com/USER/REPO/actions/workflows/security-scan.yml)
```

## 🔄 Fluxo de Trabalho

### Desenvolvimento de Feature

```bash
# 1. Criar branch de feature
git checkout -b feature/minha-feature

# 2. Desenvolver e commitar (Conventional Commits)
git commit -m "feat: adicionar nova funcionalidade"

# 3. Push da branch
git push origin feature/minha-feature

# 4. Abrir Pull Request para develop
# - PR Check workflow será executado
# - Aguardar aprovação e merge
```

### Release de Produção

```bash
# 1. Merge develop → main
git checkout main
git merge develop

# 2. Criar tag de versão
git tag -a v1.2.3 -m "Release v1.2.3"
git push origin v1.2.3

# 3. Workflows automáticos:
# - Release workflow: cria GitHub Release
# - CD workflow: deploy em staging e produção (com aprovação)
```

## 📖 Documentação Completa

Para informações detalhadas sobre:
- Arquitetura de CI/CD
- Configuração avançada
- Troubleshooting
- Boas práticas

Consulte: [CICD_DOCUMENTATION.md](./CICD_DOCUMENTATION.md)

## 🤝 Contribuindo

### Modificando Workflows

1. Teste localmente com [act](https://github.com/nektos/act)
2. Faça alterações em uma branch
3. Abra PR com descrição clara
4. Aguarde revisão do time de DevOps

### Adicionando Novos Workflows

1. Crie arquivo em `workflows/`
2. Siga padrão dos workflows existentes
3. Documente triggers e jobs
4. Adicione ao README e documentação
5. Teste extensivamente antes de merge

## 🆘 Problemas Comuns

### Build Falha
- Verifique logs no Actions tab
- Teste localmente: `./mvnw clean verify`
- Verifique compatibilidade de versões

### Deploy Falha
- Verifique KUBECONFIG está configurado
- Teste conexão: `kubectl get nodes`
- Verifique logs do pod: `kubectl logs -f pod-name`

### Security Alerts
- Revise alertas no Security tab
- Aguarde PR do Dependabot
- Ou atualize manualmente: `./mvnw versions:display-dependency-updates`

## 📞 Suporte

- 📧 **Email**: devops@vehicle-resale.com
- 💬 **Slack**: #devops-support
- 🐛 **Issues**: [GitHub Issues](../../issues)
- 📚 **Docs**: [Documentação Completa](./CICD_DOCUMENTATION.md)

---

**Última atualização**: 2026-01-23  
**Mantido por**: DevOps Team
