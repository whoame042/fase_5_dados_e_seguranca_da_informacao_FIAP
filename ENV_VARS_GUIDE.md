# Guia de Variáveis de Ambiente

Este documento descreve como usar e configurar as variáveis de ambiente do projeto Vehicle Resale API.

## Arquivos de Configuração

O projeto utiliza arquivos `.env` para gerenciar configurações sensíveis e específicas de ambiente:

### Arquivos Disponíveis

| Arquivo | Descrição | Versionado |
|---------|-----------|------------|
| `.env` | Configurações locais ativas | NÃO (ignorado pelo git) |
| `.env.example` | Template com valores padrão | SIM |
| `.env.production.example` | Template para produção | SIM |

---

## Configuração Inicial

### 1. Para Desenvolvimento Local

```bash
# Copie o arquivo de exemplo
cp .env.example .env

# Edite o arquivo .env com suas configurações locais (opcional)
nano .env
```

O arquivo `.env` já vem com valores padrão prontos para uso local.

### 2. Para Produção

```bash
# Copie o arquivo de exemplo de produção
cp .env.production.example .env

# IMPORTANTE: Edite e altere as senhas e configurações sensíveis
nano .env
```

Altere especialmente:
- `POSTGRES_PASSWORD`
- `DB_PASSWORD`
- `QUARKUS_HIBERNATE_ORM_DATABASE_GENERATION` (use `validate` ou `none`)
- `QUARKUS_HIBERNATE_ORM_LOG_SQL` (configure como `false`)
- `QUARKUS_LOG_LEVEL` (configure como `WARN` ou `ERROR`)

---

## Variáveis Disponíveis

### Banco de Dados PostgreSQL

| Variável | Descrição | Padrão | Obrigatório |
|----------|-----------|--------|-------------|
| `POSTGRES_DB` | Nome do banco de dados | `vehicle_resale` | Sim |
| `POSTGRES_USER` | Usuário do PostgreSQL | `postgres` | Sim |
| `POSTGRES_PASSWORD` | Senha do PostgreSQL | `postgres123` | Sim |
| `POSTGRES_PORT` | Porta externa | `5433` | Não |
| `POSTGRES_INTERNAL_PORT` | Porta interna | `5432` | Não |

### Aplicação

| Variável | Descrição | Padrão | Obrigatório |
|----------|-----------|--------|-------------|
| `DB_URL` | URL JDBC de conexão | `jdbc:postgresql://postgres:5432/vehicle_resale` | Sim |
| `DB_USERNAME` | Usuário do banco | `postgres` | Sim |
| `DB_PASSWORD` | Senha do banco | `postgres123` | Sim |

### Quarkus

| Variável | Descrição | Valores | Padrão |
|----------|-----------|---------|--------|
| `QUARKUS_HTTP_PORT` | Porta HTTP interna | Número | `8080` |
| `APP_PORT` | Porta externa (host) | Número | `8080` |
| `QUARKUS_HIBERNATE_ORM_DATABASE_GENERATION` | Estratégia de schema | `none`, `create`, `drop-and-create`, `drop`, `update`, `validate` | `update` |
| `QUARKUS_HIBERNATE_ORM_LOG_SQL` | Log de SQL | `true`, `false` | `true` |
| `QUARKUS_LOG_LEVEL` | Nível de log | `OFF`, `FATAL`, `ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE`, `ALL` | `INFO` |
| `QUARKUS_LOG_CATEGORY_COM_VEHICLERESALE_LEVEL` | Log do pacote | `OFF`, `FATAL`, `ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE`, `ALL` | `DEBUG` |

### Containers

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `POSTGRES_CONTAINER_NAME` | Nome do container PostgreSQL | `vehicle-resale-postgres` |
| `APP_CONTAINER_NAME` | Nome do container da API | `vehicle-resale-api` |
| `DOCKER_NETWORK_NAME` | Nome da rede Docker | `vehicle-resale-network` |

### Opcionais

| Variável | Descrição | Valores | Padrão |
|----------|-----------|---------|--------|
| `ENVIRONMENT` | Ambiente de execução | `dev`, `staging`, `prod` | `dev` |
| `TZ` | Timezone | Timezone IANA | `America/Sao_Paulo` |

---

## Uso com Docker Compose

O `docker-compose.yml` está configurado para carregar automaticamente o arquivo `.env`:

```bash
# Iniciar com arquivo .env padrão
docker-compose up -d

# Iniciar com arquivo específico
docker-compose --env-file .env.production up -d

# Verificar variáveis carregadas
docker-compose config
```

### Valores Padrão (Fallback)

Todas as variáveis têm valores padrão definidos no `docker-compose.yml`:

```yaml
${POSTGRES_USER:-postgres}
```

Se a variável não existir no `.env`, o valor `postgres` será usado.

---

## Estratégias de Gerenciamento de Schema

### Desenvolvimento (`QUARKUS_HIBERNATE_ORM_DATABASE_GENERATION`)

| Valor | Descrição | Quando Usar |
|-------|-----------|-------------|
| `update` | Atualiza schema automaticamente | Desenvolvimento local |
| `create` | Cria schema ao iniciar | Testes com dados temporários |
| `drop-and-create` | Remove e recria schema | Testes que precisam limpar dados |
| `validate` | Apenas valida schema | Staging/Produção |
| `none` | Não faz nada | Produção (usar migrations) |

### Recomendações por Ambiente

| Ambiente | Valor Recomendado | Justificativa |
|----------|-------------------|---------------|
| **Desenvolvimento** | `update` | Facilita desenvolvimento rápido |
| **Staging** | `validate` | Valida mas não altera |
| **Produção** | `none` ou `validate` | Segurança máxima |

---

## Segurança

### Boas Práticas

1. **NUNCA commitar o arquivo `.env`**
   - O `.gitignore` já está configurado para ignorá-lo
   - Sempre use `.env.example` como template

2. **Usar senhas fortes em produção**
   ```bash
   # Gerar senha aleatória
   openssl rand -base64 32
   ```

3. **Diferentes credenciais por ambiente**
   - Desenvolvimento: senhas simples (OK)
   - Produção: senhas complexas e únicas

4. **Rotação de credenciais**
   - Altere senhas periodicamente
   - Use secrets managers em produção (AWS Secrets Manager, HashiCorp Vault)

5. **Permissões do arquivo**
   ```bash
   # Restringir acesso ao .env
   chmod 600 .env
   ```

### Checklist de Segurança

Antes de colocar em produção:

- [ ] Alterar `POSTGRES_PASSWORD`
- [ ] Alterar `DB_PASSWORD`
- [ ] Configurar `QUARKUS_HIBERNATE_ORM_DATABASE_GENERATION=validate`
- [ ] Desabilitar logs SQL (`QUARKUS_HIBERNATE_ORM_LOG_SQL=false`)
- [ ] Reduzir nível de log (`QUARKUS_LOG_LEVEL=WARN`)
- [ ] Verificar permissões do arquivo `.env` (600)
- [ ] Garantir que `.env` não está versionado

---

## Exemplos de Uso

### Desenvolvimento Local

```bash
# 1. Copiar template
cp .env.example .env

# 2. Iniciar containers
docker-compose up -d

# 3. Verificar logs
docker-compose logs -f vehicle-resale-api
```

### Testes com Dados Limpos

```bash
# Configurar para recriar banco a cada vez
# Editar .env:
QUARKUS_HIBERNATE_ORM_DATABASE_GENERATION=drop-and-create

# Reiniciar
docker-compose down -v
docker-compose up -d
```

### Produção

```bash
# 1. Copiar template de produção
cp .env.production.example .env

# 2. Editar e configurar senhas fortes
nano .env

# 3. Verificar configurações (sem exibir no terminal)
docker-compose config > /dev/null && echo "Configuração OK"

# 4. Iniciar
docker-compose up -d

# 5. Monitorar
docker-compose logs -f --tail=100
```

### Mudança de Porta

```bash
# Editar .env
POSTGRES_PORT=5434
APP_PORT=8081

# Reiniciar
docker-compose down
docker-compose up -d
```

### Debug Completo

```bash
# Editar .env
QUARKUS_LOG_LEVEL=DEBUG
QUARKUS_LOG_CATEGORY_COM_VEHICLERESALE_LEVEL=TRACE
QUARKUS_HIBERNATE_ORM_LOG_SQL=true

# Reiniciar
docker-compose restart vehicle-resale-api

# Ver logs
docker-compose logs -f vehicle-resale-api
```

---

## Troubleshooting

### Problema: Variáveis não estão sendo carregadas

**Solução:**
```bash
# Verificar se o arquivo existe
ls -la .env

# Verificar conteúdo
cat .env

# Testar carga de variáveis
docker-compose config | grep POSTGRES_USER
```

### Problema: Porta já em uso

**Solução:**
```bash
# Alterar porta no .env
POSTGRES_PORT=5434
APP_PORT=8081

# Reiniciar
docker-compose down
docker-compose up -d
```

### Problema: Senha do banco incorreta

**Solução:**
```bash
# Verificar variáveis carregadas
docker-compose config | grep PASSWORD

# Se necessário, limpar volumes e recriar
docker-compose down -v
docker-compose up -d
```

### Problema: Schema não está sendo atualizado

**Solução:**
```bash
# Verificar estratégia configurada
grep DATABASE_GENERATION .env

# Ajustar conforme necessário
QUARKUS_HIBERNATE_ORM_DATABASE_GENERATION=update

# Reiniciar
docker-compose restart vehicle-resale-api
```

---

## Integração com CI/CD

### GitHub Actions

```yaml
- name: Create .env file
  run: |
    echo "POSTGRES_PASSWORD=${{ secrets.POSTGRES_PASSWORD }}" >> .env
    echo "DB_PASSWORD=${{ secrets.DB_PASSWORD }}" >> .env
    # ... outras variáveis
```

### Jenkins

```groovy
environment {
    POSTGRES_PASSWORD = credentials('postgres-password')
    DB_PASSWORD = credentials('db-password')
}
```

### GitLab CI

```yaml
variables:
  POSTGRES_PASSWORD: $CI_POSTGRES_PASSWORD
  DB_PASSWORD: $CI_DB_PASSWORD
```

---

## Referências

- [Docker Compose Environment Variables](https://docs.docker.com/compose/environment-variables/)
- [Quarkus Configuration](https://quarkus.io/guides/config)
- [PostgreSQL Docker Official Image](https://hub.docker.com/_/postgres)
- [Twelve-Factor App - Config](https://12factor.net/config)



