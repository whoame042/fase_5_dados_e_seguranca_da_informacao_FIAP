---
title: "Relatório de Segurança de Dados"
subtitle: "Vehicle Resale API – Fase 5: Dados e Segurança da Informação"
author: "PÓS-FIAP – Arquitetura de Software"
date: "Março/2026"
---

# Relatório de Segurança de Dados

**Projeto:** Vehicle Resale API  
**Disciplina:** Fase 5 – Dados e Segurança da Informação  
**Curso:** Pós-Graduação FIAP – Arquitetura de Software  
**Data:** Fevereiro/2026

---

## Sumário

1. [Dados Armazenados pela Solução](#1-dados-armazenados-pela-solução)
2. [Dados Sensíveis e Classificação](#2-dados-sensíveis-e-classificação)
3. [Políticas de Acesso Implementadas](#3-políticas-de-acesso-implementadas)
4. [Políticas de Segurança Operacional](#4-políticas-de-segurança-operacional)
5. [Matriz de Riscos e Mitigações](#5-matriz-de-riscos-e-mitigações)
6. [Conformidade com a LGPD](#6-conformidade-com-a-lgpd)
7. [Conclusão](#7-conclusão)

---

## 1. Dados Armazenados pela Solução

A solução utiliza **dois bancos de dados PostgreSQL independentes**, separando dados de identidade (Keycloak) de dados transacionais de negócio (API).

### 1.1 Banco da API — `vehicle_resale_db`

**Entidade: `vehicles`**

| Campo | Tipo | Sensível |
|-------|------|----------|
| id | Long | Não |
| brand | String | Não |
| model | String | Não |
| year | Integer | Não |
| color | String | Não |
| price | BigDecimal | Não |
| status | Enum (AVAILABLE / SOLD) | Não |
| createdAt / updatedAt / deletedAt | LocalDateTime | Não |

**Entidade: `customers`**

| Campo | Tipo | Sensível | Base Legal (LGPD) |
|-------|------|----------|--------------------|
| id | Long | Não | — |
| userId | String | Não | — |
| name | String | **Sim** | Dado pessoal — Art. 5º, I |
| email | String | **Sim** | Dado pessoal — Art. 5º, I |
| cpf | String | **Sim** | Dado pessoal — Art. 5º, I |
| phone | String | **Sim** | Dado pessoal — Art. 5º, I |
| address / city / state / zipCode | String | **Sim** | Dado pessoal — Art. 5º, I |
| active | Boolean | Não | — |
| createdAt / updatedAt | LocalDateTime | Não | — |

**Entidade: `sales`**

| Campo | Tipo | Sensível | Observação |
|-------|------|----------|------------|
| id | Long | Não | — |
| vehicle_id | Long (FK) | Não | Referência ao veículo |
| buyerName | String | **Sim** | Replicado de `Customer.name` |
| buyerEmail | String | **Sim** | Replicado de `Customer.email` |
| buyerCpf | String | **Sim** | Replicado de `Customer.cpf` |
| saleDate | LocalDate | Não | — |
| salePrice | BigDecimal | Não | — |
| paymentCode | UUID | Parcial | Confidencialidade operacional |
| paymentStatus | Enum (PENDING / APPROVED / REJECTED) | Não | — |
| createdAt / updatedAt | LocalDateTime | Não | — |

### 1.2 Banco do Keycloak — `keycloak_db`

Gerenciado exclusivamente pelo **Keycloak 23**. Armazena: usuários, credenciais (hash bcrypt), roles (`admin`, `buyer`) e tokens de sessão.

> **Importante:** o Keycloak **não armazena** CPF, endereço nem dados financeiros da aplicação. A separação é intencional e garante isolamento entre identidade e dados de negócio.

---

## 2. Dados Sensíveis e Classificação

### 2.1 Mapa de dados sensíveis

| Dado | Onde está armazenado | Finalidade | Classificação |
|------|----------------------|------------|---------------|
| **CPF** | `Customer.cpf`, `Sale.buyerCpf` | Identificação e emissão de documentação | Dado pessoal (LGPD) |
| **Nome completo** | `Customer.name`, `Sale.buyerName` | Identificação e documentação na retirada | Dado pessoal (LGPD) |
| **E-mail** | `Customer.email`, `Sale.buyerEmail` | Contato e comunicação | Dado pessoal (LGPD) |
| **Telefone** | `Customer.phone` | Contato | Dado pessoal (LGPD) |
| **Endereço** | `Customer.address/city/state/zipCode` | Documentação e entrega | Dado pessoal (LGPD) |
| **paymentCode** | `Sale.paymentCode` | Rastreamento da transação | Confidencial operacional |

### 2.2 Recomendações para produção

> **Mascaramento em logs:** CPF e e-mail não devem aparecer em texto plano nos logs de aplicação. Recomenda-se uso de filtros de log ou mascaramento (`***.***.***-**`).

> **Criptografia em repouso:** Habilitar TDE (*Transparent Data Encryption*) no PostgreSQL em produção — nativo no Amazon RDS com AWS KMS, sem alteração no código da aplicação.

> **Criptografia em nível de aplicação (opcional):** Para CPF, pode-se aplicar AES-256 antes de persistir, armazenando apenas o valor cifrado no banco. Exige gerenciamento de chaves (ex.: AWS Secrets Manager / KMS).

> **Retenção e exclusão:** Definir política de retenção de dados pessoais conforme Art. 16 da LGPD. Implementar endpoint de exclusão/anonimização de `Customer` quando solicitado pelo titular.

---

## 3. Políticas de Acesso Implementadas

### 3.1 Modelo de autenticação e autorização

```
  Usuário/Sistema
       │
       ▼
  [Keycloak 23] ──── emite JWT com roles
       │
       ▼
  [ALB / Ingress] ──── repassa o token
       │
       ▼
  [Vehicle Resale API] ──── valida JWT + aplica políticas por path/role
       │
       ├── Público (sem token): listagem de veículos, health, swagger
       ├── Autenticado (qualquer role): clientes, vendas
       └── Role admin: criar/editar/excluir veículos
```

### 3.2 Matriz de acesso por endpoint

| Grupo de Endpoints | Método | Política | Role necessária |
|--------------------|--------|----------|-----------------|
| `/api/vehicles/available` | GET | Público | — |
| `/api/vehicles/sold` | GET | Público | — |
| `/api/vehicles/{id}` | GET | Público | — |
| `/api/vehicles` | POST | Autenticado | `admin` |
| `/api/vehicles/{id}` | PUT / DELETE | Autenticado | `admin` |
| `/api/customers` | GET / POST / PUT | Autenticado | `admin` ou `buyer` |
| `/api/customers/{id}` | GET / PUT | Autenticado | `admin` ou `buyer` |
| `/api/sales` | POST | Autenticado | `admin` ou `buyer` |
| `/api/sales/{id}` | GET | Autenticado | `admin` ou `buyer` |
| `/api/webhook/payment` | POST | Público\* | — |
| `/health/*`, `/metrics`, `/swagger-ui/*` | GET | Público | — |

> **\* Atenção — webhook:** o endpoint de webhook está atualmente sem autenticação (`permit`). **Em produção, é obrigatório** restringir o acesso por meio de um header secreto compartilhado (ex.: `X-Webhook-Secret`), assinatura HMAC ou whitelist de IPs.

### 3.3 Configuração na aplicação

As políticas estão definidas em `src/main/resources/application.properties`:

```properties
quarkus.http.auth.permission.public.paths=/health/*,/metrics,/openapi,/swagger-ui/*,/q/*
quarkus.http.auth.permission.public.policy=permit

quarkus.http.auth.permission.vehicles-admin.paths=/api/vehicles,/api/vehicles/*
quarkus.http.auth.permission.vehicles-admin.methods=POST,PUT,DELETE
quarkus.http.auth.policy.vehicles-admin.roles-allowed=admin

quarkus.http.auth.permission.customers.paths=/api/customers,/api/customers/*
quarkus.http.auth.permission.customers.policy=authenticated
```

---

## 4. Políticas de Segurança Operacional

### 4.1 Separação de responsabilidades

| Camada | Responsabilidade | Tecnologia |
|--------|-----------------|------------|
| Identidade e acesso | Autenticação, emissão de tokens, gestão de usuários e roles | Keycloak 23 (serviço separado) |
| Dados transacionais | Veículos, clientes, vendas | Vehicle Resale API + PostgreSQL |
| Isolamento de dados | Banco da API separado do banco do Keycloak | Dois containers / instâncias RDS distintas |

### 4.2 Proteção contra ataques

| Controle | Implementação |
|----------|---------------|
| **Brute force** | Keycloak: `bruteForceProtected=true`, `failureFactor`, `maxFailureWaitSeconds` configurados no `realm-export.json` |
| **Expiração de sessão** | `accessTokenLifespan` e `ssoSessionIdleTimeout` configurados no realm |
| **Validação de entrada** | Bean Validation (`@NotBlank`, `@Size`, `@Pattern`) em todos os DTOs de requisição |
| **SQL Injection** | Hibernate/Panache com queries parametrizadas (sem SQL dinâmico manual) |
| **Usuário não-root** | Container Docker executa com UID 185 (não-root) |
| **HTTPS/TLS** | Configurável via `quarkus.oidc.tls.*`; em produção, terminação TLS no ALB/Ingress |

### 4.3 Monitoramento e auditoria

| Recurso | Configuração |
|---------|-------------|
| **Health check** | `GET /health/ready` e `/health/live` (Smallrye Health) |
| **Métricas** | `GET /metrics` (formato Prometheus) |
| **Logging** | Nível configurável por pacote em `application.properties`; OIDC com nível DEBUG disponível |
| **Auditoria AWS** | CloudTrail para ações na infraestrutura; GuardDuty para detecção de anomalias (ambiente de produção) |

---

## 5. Matriz de Riscos e Mitigações

| Risco | Probabilidade | Impacto | Mitigação Implementada | Mitigação Recomendada |
|-------|:-------------:|:-------:|------------------------|----------------------|
| Acesso não autorizado à API | Média | Alto | Autenticação Keycloak; autorização por path e role | HTTPS obrigatório; revisão periódica de permissões |
| Exposição de CPF e e-mail em logs | Alta | Alto | — | Mascarar dados sensíveis nos logs; nível INFO em produção |
| Webhook de pagamento falsificado | Alta | Alto | — | Header secreto (`X-Webhook-Secret`) ou assinatura HMAC; rate limiting |
| Venda com CPF inválido ou não cadastrado | Baixa | Médio | Validação em `SaleService`; CPF obrigatório no cadastro | Mantida |
| Veículo bloqueado após pagamento rejeitado | Média | Médio | Compensação SAGA: reverte veículo para `AVAILABLE` | Mantida |
| Exposição de dados em repouso | Baixa | Alto | — | Criptografia TDE no RDS (KMS); criptografia de CPF em nível de aplicação |
| Indisponibilidade / perda de dados | Baixa | Alto | — | Backup automatizado (RDS); replicação Multi-AZ; definir RTO/RPO |
| Acesso direto ao banco de dados | Baixa | Crítico | Banco em rede privada (VPC) | Security Groups restritivos; RDS sem IP público; IAM Authentication |

---

## 6. Conformidade com a LGPD

A Lei Geral de Proteção de Dados (Lei nº 13.709/2018) estabelece obrigações para o tratamento de dados pessoais. A tabela abaixo mapeia os principais princípios ao estado atual da solução.

| Princípio (Art. 6º) | Situação na solução | Status |
|---------------------|---------------------|:------:|
| **Finalidade** | CPF e endereço coletados exclusivamente para emissão de código de pagamento e documentação na retirada | ✅ Atendido |
| **Adequação** | Dados coletados são compatíveis com a finalidade informada | ✅ Atendido |
| **Necessidade** | Apenas dados estritamente necessários são armazenados (sem biometria, sem documentos além do CPF) | ✅ Atendido |
| **Acesso do Titular** | `GET /api/customers/{id}` permite consulta dos próprios dados (autenticado) | ✅ Atendido |
| **Qualidade dos dados** | `PUT /api/customers/{id}` permite atualização dos dados pelo titular | ✅ Atendido |
| **Segurança** | Autenticação Keycloak, autorização por role, TLS em trânsito | ⚠️ Parcial — criptografia em repouso pendente |
| **Prevenção** | Validação de entrada; proteção contra brute force no Keycloak | ⚠️ Parcial — webhook sem autenticação |
| **Responsabilização** | Logs de acesso; estrutura auditável | ⚠️ Parcial — auditoria completa depende do ambiente de produção (CloudTrail) |
| **Não discriminação** | Não aplicável ao domínio | — |

> **Ações prioritárias para conformidade plena:** (1) autenticar o webhook de pagamento; (2) habilitar criptografia em repouso no banco de produção; (3) implementar endpoint de exclusão/anonimização de dados do titular; (4) documentar o ciclo de vida e a retenção dos dados pessoais.

---

## 7. Conclusão

A solução **Vehicle Resale API** implementa os controles fundamentais de segurança de dados:

- **Autenticação robusta** via Keycloak 23 (OAuth2/OIDC) com proteção contra brute force
- **Autorização granular** por path e role (`admin` / `buyer`) configurada diretamente no framework
- **Separação de identidade e dados de negócio** em serviços e bancos independentes
- **Tratamento de dados sensíveis** (CPF, e-mail, endereço) com acesso restrito a usuários autenticados
- **Resiliência transacional** via SAGA de compensação, que impede inconsistências no estoque

| Controle | Status |
|----------|:------:|
| Autenticação (Keycloak / OAuth2 / JWT) | ✅ Implementado |
| Autorização por role e path | ✅ Implementado |
| Separação identidade × negócio | ✅ Implementado |
| Validação de entrada (Bean Validation) | ✅ Implementado |
| Compensação SAGA | ✅ Implementado |
| Criptografia em trânsito (TLS) | ⚠️ Configurável (ALB/Ingress) |
| Criptografia em repouso | ⚠️ Recomendada (RDS KMS) |
| Autenticação do webhook | ⚠️ Pendente |
| Mascaramento de dados em logs | ⚠️ Recomendado |

---

*Documento elaborado para a Fase 5 – Dados e Segurança da Informação – PÓS-FIAP Arquitetura de Software.*
