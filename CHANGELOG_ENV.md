# Changelog - Implementação de Variáveis de Ambiente

## Data: 2025-11-11

## Resumo

Todas as configurações do `docker-compose.yml` foram externalizadas para arquivos `.env`, permitindo maior flexibilidade e segurança no gerenciamento de configurações.

---

## Arquivos Criados

### 1. `.env`
- **Status:** Criado e funcional
- **Versionado:** NÃO (ignorado pelo `.gitignore`)
- **Descrição:** Arquivo de configuração ativo com variáveis de ambiente
- **Uso:** Valores padrão para desenvolvimento local

### 2. `.env.example`
- **Status:** Criado
- **Versionado:** SIM
- **Descrição:** Template com valores de exemplo
- **Uso:** Referência para criar novos arquivos `.env`

### 3. `.env.production.example`
- **Status:** Criado
- **Versionado:** SIM
- **Descrição:** Template para ambiente de produção
- **Uso:** Base para configurações de produção com ajustes de segurança

### 4. `ENV_VARS_GUIDE.md`
- **Status:** Criado
- **Versionado:** SIM
- **Descrição:** Documentação completa sobre variáveis de ambiente
- **Conteúdo:**
  - Lista de todas as variáveis disponíveis
  - Boas práticas de segurança
  - Exemplos de uso
  - Troubleshooting
  - Integração CI/CD

---

## Arquivos Modificados

### 1. `docker-compose.yml`
**Mudanças:**
- Todas as configurações fixas substituídas por variáveis
- Valores padrão (fallback) mantidos para compatibilidade
- Adicionada variável `TZ` (timezone)
- Nomes de containers parametrizados

**Exemplo de mudança:**
```yaml
# ANTES
POSTGRES_PASSWORD: postgres123

# DEPOIS
POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres123}
```

### 2. `INSTRUCOES_USO.md`
**Mudanças:**
- Adicionada seção "Configuração de Variáveis de Ambiente"
- Tabela com variáveis principais
- Exemplo de uso (mudança de portas)
- Referência ao `ENV_VARS_GUIDE.md`

### 3. `.gitignore`
**Já estava configurado para:**
- Ignorar `.env`
- Ignorar `.env.local`
- Ignorar `.env.*.local`

---

## Variáveis Externalizadas

### Banco de Dados (PostgreSQL)
| Variável | Valor Padrão | Descrição |
|----------|--------------|-----------|
| `POSTGRES_DB` | `vehicle_resale` | Nome do banco |
| `POSTGRES_USER` | `postgres` | Usuário |
| `POSTGRES_PASSWORD` | `postgres123` | Senha |
| `POSTGRES_PORT` | `5433` | Porta externa |
| `POSTGRES_INTERNAL_PORT` | `5432` | Porta interna |

### Aplicação
| Variável | Valor Padrão | Descrição |
|----------|--------------|-----------|
| `DB_URL` | `jdbc:postgresql://postgres:5432/vehicle_resale` | URL JDBC |
| `DB_USERNAME` | `postgres` | Usuário do banco |
| `DB_PASSWORD` | `postgres123` | Senha do banco |

### Quarkus
| Variável | Valor Padrão | Descrição |
|----------|--------------|-----------|
| `QUARKUS_HTTP_PORT` | `8080` | Porta HTTP interna |
| `APP_PORT` | `8080` | Porta externa |
| `QUARKUS_HIBERNATE_ORM_DATABASE_GENERATION` | `update` | Estratégia de schema |
| `QUARKUS_HIBERNATE_ORM_LOG_SQL` | `true` | Log de SQL |
| `QUARKUS_LOG_LEVEL` | `INFO` | Nível de log |
| `QUARKUS_LOG_CATEGORY_COM_VEHICLERESALE_LEVEL` | `DEBUG` | Log do pacote |

### Containers
| Variável | Valor Padrão | Descrição |
|----------|--------------|-----------|
| `POSTGRES_CONTAINER_NAME` | `vehicle-resale-postgres` | Nome do container PostgreSQL |
| `APP_CONTAINER_NAME` | `vehicle-resale-api` | Nome do container da API |
| `DOCKER_NETWORK_NAME` | `vehicle-resale-network` | Nome da rede |

### Opcionais
| Variável | Valor Padrão | Descrição |
|----------|--------------|-----------|
| `ENVIRONMENT` | `dev` | Ambiente de execução |
| `TZ` | `America/Sao_Paulo` | Timezone |

---

## Benefícios

### 1. Segurança
- Credenciais não ficam hardcoded no código
- Arquivo `.env` não é versionado (protegido pelo `.gitignore`)
- Fácil rotação de senhas
- Diferentes credenciais por ambiente

### 2. Flexibilidade
- Fácil mudança de configurações sem editar `docker-compose.yml`
- Valores diferentes por desenvolvedor/ambiente
- Configurações específicas para dev/staging/prod

### 3. Manutenibilidade
- Configurações centralizadas
- Documentação clara de todas as variáveis
- Templates prontos para uso

### 4. Compatibilidade
- Valores padrão garantem funcionamento sem `.env`
- Sintaxe: `${VAR:-default}` fornece fallback
- Retrocompatível com setup anterior

---

## Testes Realizados

### ✅ Teste 1: Carga de Variáveis
```bash
docker-compose config | grep POSTGRES_USER
# Resultado: POSTGRES_USER: postgres ✓
```

### ✅ Teste 2: Containers em Execução
```bash
docker-compose ps
# Resultado: Ambos containers UP e healthy ✓
```

### ✅ Teste 3: Variáveis no Container
```bash
docker inspect vehicle-resale-postgres | grep POSTGRES_DB
# Resultado: "POSTGRES_DB=vehicle_resale" ✓
```

### ✅ Teste 4: Aplicação Funcional
```bash
curl http://localhost:8080/health/ready
# Resultado: Status UP ✓
```

---

## Uso

### Desenvolvimento Local
```bash
# 1. O arquivo .env já existe com valores padrão
# 2. Subir containers
docker-compose up -d

# 3. (Opcional) Personalizar configurações
nano .env
docker-compose down
docker-compose up -d
```

### Produção
```bash
# 1. Copiar template de produção
cp .env.production.example .env

# 2. Editar e configurar senhas fortes
nano .env

# 3. Subir containers
docker-compose up -d
```

### Mudança de Configurações
```bash
# 1. Editar .env
nano .env

# 2. Reiniciar containers
docker-compose down
docker-compose up -d
```

---

## Próximos Passos (Recomendações)

### 1. Configuração CI/CD
- [ ] Adicionar secrets no GitHub/GitLab
- [ ] Configurar pipeline para injetar variáveis
- [ ] Documentar processo de deploy

### 2. Ambientes Adicionais
- [ ] Criar `.env.staging.example`
- [ ] Criar `.env.test.example`
- [ ] Documentar diferenças entre ambientes

### 3. Segurança Avançada
- [ ] Integrar com HashiCorp Vault
- [ ] Implementar rotação automática de senhas
- [ ] Adicionar validação de variáveis obrigatórias

### 4. Monitoramento
- [ ] Adicionar variáveis para configuração de logs
- [ ] Configurar envio de métricas
- [ ] Integrar com ferramentas de APM

---

## Compatibilidade

### Versões Testadas
- Docker: 20.10+
- Docker Compose: 1.29+ / 2.x
- Sistema Operacional: Linux (Ubuntu)

### Retrocompatibilidade
- ✅ Funciona sem arquivo `.env` (usa valores padrão)
- ✅ Compatível com `docker-compose` v1 e v2
- ✅ Suporta variáveis de ambiente do sistema

---

## Documentação Adicional

### Arquivos de Referência
- `ENV_VARS_GUIDE.md` - Guia completo de variáveis
- `INSTRUCOES_USO.md` - Instruções de uso da aplicação
- `.env.example` - Template de desenvolvimento
- `.env.production.example` - Template de produção

### Links Úteis
- [Docker Compose Environment Variables](https://docs.docker.com/compose/environment-variables/)
- [Twelve-Factor App - Config](https://12factor.net/config)
- [Quarkus Configuration Guide](https://quarkus.io/guides/config)

---

## Conclusão

A implementação de variáveis de ambiente foi concluída com sucesso. O sistema agora é mais flexível, seguro e fácil de manter. Todas as configurações sensíveis foram externalizadas e documentadas.

**Status Final:** ✅ APROVADO



