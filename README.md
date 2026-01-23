# API de Revenda de Veiculos

Sistema de gerenciamento de revenda de veiculos automotores, desenvolvido com Quarkus e pronto para deploy em Kubernetes.

## Sumario

- [Sobre o Projeto](#sobre-o-projeto)
- [Requisitos de Negocio](#requisitos-de-negocio)
- [Arquitetura da Solucao](#arquitetura-da-solucao)
- [Tecnologias Utilizadas](#tecnologias-utilizadas)
- [Modelo de Dados](#modelo-de-dados)
- [Pre-requisitos](#pre-requisitos)
- [Instalacao e Execucao Local](#instalacao-e-execucao-local)
- [Autenticacao (Keycloak)](#autenticacao-keycloak)
- [Endpoints da API](#endpoints-da-api)
- [Fluxo Completo de Uso](#fluxo-completo-de-uso)
- [Testes](#testes)
- [CI/CD](#cicd)
- [Deploy com Kubernetes](#deploy-com-kubernetes)

## Sobre o Projeto

Este projeto foi desenvolvido como parte do Tech Challenge da Pos-Tech FIAP - Arquitetura de Software (SOAT). O sistema permite o gerenciamento completo do ciclo de vida dos veiculos, desde o cadastro ate a venda e processamento de pagamentos.

**Trabalho Substitutivo - Fase 3**

## Requisitos de Negocio

O sistema atende aos seguintes requisitos:

1. **Cadastro de Veiculos**: Cadastrar veiculos para venda com marca, modelo, ano, cor e preco
2. **Edicao de Veiculos**: Permitir a edicao dos dados de veiculos disponiveis
3. **Compra de Veiculos**: Permitir a compra via internet para pessoas cadastradas
4. **Cadastro Previo de Compradores**: O cadastro do cliente deve ser feito ANTES da compra
5. **Listagem de Veiculos a Venda**: Ordenados por preco (mais barato para mais caro)
6. **Listagem de Veiculos Vendidos**: Ordenados por preco (mais barato para mais caro)

### Requisito de Autenticacao Separada

O processo de registro e autorizacao de compradores e feito de forma separada atraves do **Keycloak**, garantindo que os dados de clientes estejam separados dos dados transacionais relacionados as vendas dos veiculos.

## Arquitetura da Solucao

```
+------------------+     +------------------+     +------------------+
|                  |     |                  |     |                  |
|   Frontend       +---->+  Vehicle API     +---->+   PostgreSQL     |
|   (Opcional)     |     |  (Quarkus)       |     |   (Transacional) |
|                  |     |                  |     |                  |
+--------+---------+     +--------+---------+     +------------------+
         |                        |
         |                        |
         v                        v
+--------+---------+     +--------+---------+
|                  |     |                  |
|   Keycloak       |     |   PostgreSQL     |
|   (Auth Server)  |     |   (Keycloak)     |
|                  |     |                  |
+------------------+     +------------------+

Servicos Separados:
- API de Veiculos: Dados transacionais (veiculos, vendas)
- Keycloak: Autenticacao e autorizacao de usuarios
```

### Estrutura do Projeto

```
vehicle-resale-api/
├── .github/
│   └── workflows/           # Pipelines CI/CD
│       ├── ci.yml           # Build e testes
│       ├── cd.yml           # Deploy automatizado
│       └── pr-check.yml     # Validacao de Pull Requests
├── keycloak/
│   └── realm-export.json    # Configuracao do realm Keycloak
├── k8s/                     # Manifestos Kubernetes
├── src/main/java/com/vehicleresale/
│   ├── api/
│   │   ├── dto/             # Data Transfer Objects
│   │   ├── resource/        # REST Controllers
│   │   └── exception/       # Exception Handlers
│   ├── application/
│   │   ├── controller/      # Clean Architecture Controllers
│   │   ├── gateway/         # Gateways
│   │   └── presenter/       # Presenters
│   └── domain/
│       ├── entity/          # Entidades JPA (Vehicle, Sale, Customer)
│       ├── repository/      # Repositorios de dados
│       ├── service/         # Regras de negocio
│       └── enums/           # Enumeracoes
└── docker-compose.yml       # Ambiente completo com Keycloak
```

## Tecnologias Utilizadas

- **Quarkus 3.6.4** - Framework Java nativo para Kubernetes
- **Java 17** - Linguagem de programacao
- **Hibernate ORM com Panache** - Persistencia de dados
- **PostgreSQL 15** - Banco de dados relacional
- **Keycloak 23** - Servidor de autenticacao (OAuth2/OIDC)
- **OpenAPI/Swagger** - Documentacao da API
- **Docker** - Containerizacao
- **Kubernetes** - Orquestracao de containers
- **GitHub Actions** - CI/CD
- **Maven** - Gerenciamento de dependencias

## Modelo de Dados

### Entidade Vehicle (Veiculo)
| Campo | Tipo | Descricao |
|-------|------|-----------|
| id | Long | Identificador unico |
| brand | String | Marca do veiculo |
| model | String | Modelo do veiculo |
| year | Integer | Ano de fabricacao |
| color | String | Cor do veiculo |
| price | BigDecimal | Preco do veiculo |
| status | VehicleStatus | Status (AVAILABLE, SOLD) |
| createdAt | LocalDateTime | Data de criacao |
| updatedAt | LocalDateTime | Data de atualizacao |

### Entidade Customer (Cliente/Comprador)
| Campo | Tipo | Descricao |
|-------|------|-----------|
| id | Long | Identificador unico |
| userId | String | ID do usuario no Keycloak |
| name | String | Nome completo |
| email | String | Email (unico) |
| cpf | String | CPF (unico, 11 digitos) |
| phone | String | Telefone |
| address | String | Endereco |
| city | String | Cidade |
| state | String | Estado (UF) |
| zipCode | String | CEP |
| active | Boolean | Status ativo |

### Entidade Sale (Venda)
| Campo | Tipo | Descricao |
|-------|------|-----------|
| id | Long | Identificador unico |
| vehicle | Vehicle | Veiculo vendido |
| buyerName | String | Nome do comprador |
| buyerEmail | String | Email do comprador |
| buyerCpf | String | CPF do comprador |
| saleDate | LocalDate | Data da venda |
| salePrice | BigDecimal | Preco da venda |
| paymentCode | String | Codigo do pagamento (UUID) |
| paymentStatus | PaymentStatus | Status (PENDING, APPROVED, REJECTED) |

## Pre-requisitos

- Java 17 ou superior
- Maven 3.8+
- Docker e Docker Compose
- Kubernetes (opcional para deploy)

## Instalacao e Execucao Local

### 1. Clone o repositorio

```bash
git clone <url-do-repositorio>
cd vehicle-resale-api
```

### 2. Iniciar ambiente com Docker Compose

Este comando inicia todos os servicos necessarios:
- PostgreSQL (banco de dados da API)
- Keycloak (servidor de autenticacao)
- PostgreSQL do Keycloak

```bash
docker-compose up -d
```

Aguarde os servicos iniciarem (pode levar alguns minutos na primeira vez).

### 3. Verificar status dos servicos

```bash
docker-compose ps
```

### 4. Executar a aplicacao em modo desenvolvimento

**Opção 1: Usando o script automatizado (recomendado)**
```bash
./dev-mode.sh
```

**Opção 2: Usando Maven diretamente**
```bash
./mvnw quarkus:dev
```

**Opção 3: Usando o script maven-build.sh**
```bash
./maven-build.sh quarkus:dev
```

A aplicacao estara disponivel em:
- **API**: http://localhost:8082
- **Swagger UI**: http://localhost:8082/swagger-ui
- **Keycloak Console**: http://localhost:8180

### Comandos Maven Comuns

| Comando | Descrição |
|---------|-----------|
| `./mvnw clean compile` | Limpa e compila o projeto |
| `./mvnw clean package` | Compila e empacota o projeto (gera JAR) |
| `./mvnw clean install` | Compila, empacota e instala no repositório local |
| `./mvnw quarkus:dev` | Inicia em modo desenvolvimento (hot reload) |
| `./mvnw test` | Executa testes unitários |
| `./mvnw verify` | Executa testes e validações |
| `./mvnw clean package -DskipTests` | Build sem executar testes |

**Usando scripts auxiliares:**
- `./dev-mode.sh` - Inicia em modo desenvolvimento (configura Java/Maven automaticamente)
- `./maven-build.sh <goal>` - Executa Maven com configuração correta de Java/Maven
- `./build-and-deploy.sh` - Build completo e deploy
- `./run-tests.sh` - Executa todos os testes

## Autenticacao (Keycloak)

### Acessar Console Administrativo do Keycloak

- URL: http://localhost:8180
- Usuario: `admin`
- Senha: `admin123`

### Usuarios Pre-configurados

| Usuario | Senha | Role | Descricao |
|---------|-------|------|-----------|
| admin@vehicleresale.com | admin123 | admin | Gerencia veiculos e ve todas as vendas |
| comprador@teste.com | comprador123 | buyer | Visualiza veiculos e realiza compras |

### Obter Token de Acesso

```bash
# Token de administrador
curl -X POST "http://localhost:8180/realms/vehicle-resale/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=vehicle-resale-api" \
  -d "client_secret=vehicle-resale-secret" \
  -d "grant_type=password" \
  -d "username=admin@vehicleresale.com" \
  -d "password=admin123"

# Token de comprador
curl -X POST "http://localhost:8180/realms/vehicle-resale/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=vehicle-resale-api" \
  -d "client_secret=vehicle-resale-secret" \
  -d "grant_type=password" \
  -d "username=comprador@teste.com" \
  -d "password=comprador123"
```

### Usar Token nas Requisicoes

```bash
curl -X GET "http://localhost:8082/api/customers/me" \
  -H "Authorization: Bearer <seu_token_aqui>"
```

## Endpoints da API

### Veiculos (Publicos para leitura)

| Metodo | Endpoint | Descricao | Autenticacao |
|--------|----------|-----------|--------------|
| GET | /api/vehicles/available | Listar veiculos disponiveis | Nao |
| GET | /api/vehicles/sold | Listar veiculos vendidos | Nao |
| GET | /api/vehicles/{id} | Buscar veiculo por ID | Nao |
| POST | /api/vehicles | Cadastrar veiculo | Sim (admin) |
| PUT | /api/vehicles/{id} | Atualizar veiculo | Sim (admin) |
| DELETE | /api/vehicles/{id} | Excluir veiculo | Sim (admin) |

### Clientes

| Metodo | Endpoint | Descricao | Autenticacao |
|--------|----------|-----------|--------------|
| GET | /api/customers | Listar todos os clientes | Sim (admin) |
| GET | /api/customers/{id} | Buscar cliente por ID | Sim |
| GET | /api/customers/me | Buscar meu cadastro | Sim |
| GET | /api/customers/cpf/{cpf} | Buscar cliente por CPF | Sim (admin) |
| GET | /api/customers/check/{cpf} | Verificar se CPF esta cadastrado | Sim |
| POST | /api/customers | Cadastrar novo cliente | Sim |
| PUT | /api/customers/{id} | Atualizar cliente | Sim |
| DELETE | /api/customers/{id} | Desativar cliente | Sim (admin) |

### Vendas

| Metodo | Endpoint | Descricao | Autenticacao |
|--------|----------|-----------|--------------|
| GET | /api/sales/{id} | Buscar venda por ID | Sim |
| POST | /api/sales | Efetuar venda | Sim |

### Webhook de Pagamento

| Metodo | Endpoint | Descricao | Autenticacao |
|--------|----------|-----------|--------------|
| POST | /api/webhook/payment | Processar status de pagamento | Nao |

## Fluxo Completo de Uso

### 1. Cadastrar um novo usuario no Keycloak

Acesse http://localhost:8180 e crie um novo usuario ou use os usuarios pre-configurados.

### 2. Obter token de acesso

```bash
TOKEN=$(curl -s -X POST "http://localhost:8180/realms/vehicle-resale/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=vehicle-resale-api" \
  -d "client_secret=vehicle-resale-secret" \
  -d "grant_type=password" \
  -d "username=admin@vehicleresale.com" \
  -d "password=admin123" | jq -r '.access_token')
```

### 3. Cadastrar veiculo (como admin)

```bash
curl -X POST "http://localhost:8082/api/vehicles" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "brand": "Toyota",
    "model": "Corolla",
    "year": 2023,
    "color": "Prata",
    "price": 95000.00
  }'
```

### 4. Listar veiculos disponiveis

```bash
curl -X GET "http://localhost:8082/api/vehicles/available"
```

### 5. Cadastrar cliente (OBRIGATORIO antes da compra)

```bash
curl -X POST "http://localhost:8082/api/customers" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Joao Silva",
    "email": "joao@email.com",
    "cpf": "12345678901",
    "phone": "11999999999",
    "address": "Rua Exemplo, 123",
    "city": "Sao Paulo",
    "state": "SP",
    "zipCode": "01234567"
  }'
```

### 6. Efetuar compra do veiculo

```bash
curl -X POST "http://localhost:8082/api/sales" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "vehicleId": 1,
    "buyerName": "Joao Silva",
    "buyerEmail": "joao@email.com",
    "buyerCpf": "12345678901",
    "saleDate": "2024-01-15"
  }'
```

### 7. Processar pagamento (webhook)

```bash
curl -X POST "http://localhost:8082/api/webhook/payment" \
  -H "Content-Type: application/json" \
  -d '{
    "paymentCode": "<codigo_retornado_na_venda>",
    "paid": true
  }'
```

### 8. Listar veiculos vendidos

```bash
curl -X GET "http://localhost:8082/api/vehicles/sold"
```

## Testes

### Executar todos os testes

```bash
./mvnw test
```

### Executar testes com cobertura

```bash
./mvnw verify
```

## CI/CD

O projeto possui pipelines automatizados com GitHub Actions:

### Pipeline de CI (ci.yml)
- Executa em push/PR para branches main e develop
- Build do projeto
- Execucao de testes
- Verificacao de qualidade do codigo

### Pipeline de CD (cd.yml)
- Executa em push para main ou tags de versao
- Build da imagem Docker
- Push para GitHub Container Registry
- Deploy automatizado em staging/producao

### Pipeline de PR (pr-check.yml)
- Validacao de Pull Requests
- Lint e validacao
- Testes unitarios
- Build da imagem Docker (sem push)
- Scan de seguranca

### Configurar Deploy Automatico

1. Configure os secrets no repositorio GitHub:
   - `KUBECONFIG`: Configuracao do cluster Kubernetes

2. Configure os environments no GitHub:
   - `staging`: Para deploys em ambiente de staging
   - `production`: Para deploys em producao (requer aprovacao)

## Deploy com Kubernetes

### Deploy Local (Minikube) - Modo Automatico ✅

Use o script automatizado (recomendado):

```bash
./deploy-minikube-auto.sh
```

Este script faz:
- ✅ Verifica e inicia o Minikube
- ✅ Compila a aplicacao
- ✅ Cria a imagem Docker
- ✅ Aplica recursos do Kubernetes
- ✅ Aguarda todos os pods ficarem prontos
- ✅ Mostra instrucoes de acesso

**Tempo estimado:** 5-10 minutos (primeira vez)

### Deploy Manual (Minikube)

Se preferir fazer passo a passo:

```bash
# 1. Iniciar Minikube
minikube start --driver=docker --memory=4096 --cpus=2

# 2. Configurar Docker do Minikube
eval $(minikube docker-env)

# 3. Build da aplicacao
./mvnw clean package -DskipTests
./mvnw quarkus:build -DskipTests

# 4. Build da imagem Docker
docker build -t vehicle-resale-api:1.0.1 .

# 5. Criar ConfigMap do Keycloak
kubectl create configmap keycloak-realm-config \
  --from-file=realm-export.json=keycloak/realm-export.json \
  -n vehicle-resale

# 6. Deploy dos recursos
cd k8s
kubectl apply -k .
cd ..

# 7. Aguardar pods
kubectl wait --for=condition=ready pod -l app=vehicle-resale-api -n vehicle-resale --timeout=120s
```

### Acessar a Aplicacao no Kubernetes

**Terminal 1 - API:**
```bash
kubectl port-forward -n vehicle-resale svc/vehicle-resale-api-service 8082:80
```
Acesse: http://localhost:8082/swagger-ui

**Terminal 2 - Keycloak:**
```bash
kubectl port-forward -n vehicle-resale svc/keycloak-service 8180:8180
```
Acesse: http://localhost:8180 (admin/admin123)

**Ver Status:**
```bash
kubectl get all -n vehicle-resale
kubectl logs -f -l app=vehicle-resale-api -n vehicle-resale
```

📖 Documentacao completa: `ACESSO_KUBERNETES.md`

### Deploy em Cloud

Consulte os overlays disponiveis em `k8s/overlays/` para:
- AWS (EKS)
- Azure (AKS)
- GCP (GKE)

## Troubleshooting

### Keycloak nao inicia

```bash
# Verificar logs
docker-compose logs keycloak

# Reiniciar servicos
docker-compose restart keycloak
```

### Erro de conexao com banco de dados

```bash
# Verificar se PostgreSQL esta rodando
docker-compose ps postgres

# Verificar logs
docker-compose logs postgres
```

### Token invalido ou expirado

Obtenha um novo token usando o endpoint de autenticacao do Keycloak.

## Seguranca

- Autenticacao via OAuth2/OIDC (Keycloak)
- Tokens JWT para autorizacao
- Senhas armazenadas em Secrets do Kubernetes
- Aplicacao roda como usuario nao-root (UID 185)
- Validacoes de entrada em todos os endpoints

## Licenca

Projeto desenvolvido para fins educacionais - FIAP Pos-Tech Arquitetura de Software.
# fase_3_distribuicao_da_aplicacao_FIAP
