# Documento de Arquitetura – Vehicle Resale API
## Fase 5 – Dados e Segurança da Informação
### Pós-Graduação FIAP – Arquitetura de Software

**Projeto:** API de Revenda de Veículos  
**Versão:** 1.0  
**Data:** Março/2026  
**Stack:** Quarkus 3.6.4 · Java 17 · PostgreSQL 15 · Keycloak 23 · Docker · Kubernetes

---

## 1. Visão Geral

A **Vehicle Resale API** é uma API RESTful construída com **Quarkus 3.6.4 (Java 17)** que gerencia o ciclo de vida completo de revenda de veículos: cadastro de veículos, cadastro de clientes/compradores, criação de vendas com geração de código de pagamento e atualização de status via webhook. A autenticação e autorização são delegadas ao **Keycloak 23** (serviço de identidade separado).

A arquitetura segue os princípios de **Clean Architecture (Arquitetura Hexagonal)** com **Domain-Driven Design (DDD)**, separando claramente as camadas de domínio, aplicação e infraestrutura.

---

## 2. Diagrama de Arquitetura

### 2.1 Visão Macro – Fluxo de Requisições

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        ZONA PÚBLICA (Internet)                          │
│                                                                         │
│   ┌──────────┐    ┌──────────┐    ┌─────────────┐   ┌───────────────┐  │
│   │  Cliente │    │ Comprador│    │  Sistema de │   │   Admin       │  │
│   │ (Browse) │    │  (App)   │    │  Pagamento  │   │  (Backoffice) │  │
│   └────┬─────┘    └────┬─────┘    └──────┬──────┘   └───────┬───────┘  │
└────────┼───────────────┼─────────────────┼───────────────────┼──────────┘
         │               │                 │                   │
         ▼               ▼                 ▼                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    INGRESS / API GATEWAY / LOAD BALANCER                │
│              (TLS Termination · Rate Limiting · WAF)                    │
└─────────────────────────────┬───────────────────────────────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         │                   │                    │
         ▼                   ▼                    ▼
┌─────────────────┐ ┌──────────────────┐ ┌──────────────────────┐
│  Swagger UI /   │ │  Vehicle Resale  │ │     Keycloak 23      │
│  OpenAPI        │ │  API (Quarkus)   │ │  (Identity Provider) │
│  (Documentação) │ │  Port: 8080      │ │  Port: 8180          │
└─────────────────┘ └────────┬─────────┘ └──────────┬───────────┘
                             │  verifica token JWT   │
                             └───────────────────────┘
                             │
              ┌──────────────┼─────────────────┐
              │              │                 │
              ▼              ▼                 ▼
   ┌──────────────────┐ ┌──────────┐ ┌───────────────────┐
   │  PostgreSQL API  │ │ Prometheus│ │ PostgreSQL Keycloak│
   │  (Dados negócio) │ │ /Metrics │ │ (Dados identidade) │
   │  Port: 5432      │ └──────────┘ │  Port: 5433        │
   └──────────────────┘             └───────────────────────┘
```

### 2.2 Diagrama de Componentes (Clean Architecture)

```
┌─────────────────────────────────────────────────────────────────┐
│                    CAMADA DE INFRAESTRUTURA                      │
│  ┌──────────────────────┐    ┌────────────────────────────────┐  │
│  │   REST Resources     │    │     Database (Panache/JPA)     │  │
│  │  VehicleResource     │    │   VehicleRepositoryEnhanced    │  │
│  │  CustomerResource    │    │   CustomerRepository           │  │
│  │  SaleResource        │    │   SaleRepository               │  │
│  │  WebhookResource     │    └────────────────────────────────┘  │
│  └──────────┬───────────┘                   ▲                   │
└─────────────┼─────────────────────────────────┼──────────────────┘
              │                                 │
              ▼                                 │
┌─────────────────────────────────────────────────────────────────┐
│                    CAMADA DE APLICAÇÃO                           │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │              Controllers (Use Cases)                     │    │
│  │  VehicleController · CustomerController · SaleController│    │
│  │  (Orquestram Gateways + Presenters; SAGA Compensation)  │    │
│  └──────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     CAMADA DE DOMÍNIO                            │
│  ┌──────────────┐  ┌───────────────┐  ┌───────────────────────┐  │
│  │  Entities    │  │   Services    │  │      Gateways         │  │
│  │  Vehicle     │  │ VehicleService│  │  VehicleGateway       │  │
│  │  Customer    │  │ CustomerService│ │  CustomerGateway      │  │
│  │  Sale        │  │ SaleService   │  │  SaleGateway          │  │
│  └──────────────┘  └───────────────┘  └───────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.3 Fluxo SAGA – Processo de Compra

```
Cliente            VehicleResource   SaleService        VehicleController  Pagamento
   │                    │                 │                     │              │
   │── POST /sales ────▶│                 │                     │              │
   │                    │── create() ────▶│                     │              │
   │                    │                 │── markAsSold() ────▶│              │
   │                    │                 │                     │── SOLD ──────│
   │                    │                 │── persist Sale ─────│              │
   │                    │                 │   (PENDING)         │              │
   │◀─ paymentCode ─────│◀────────────────│                     │              │
   │                    │                 │                     │              │
   │    (cliente paga)  │                 │                     │              │
   │                    │                 │                     │◀─ webhook ──▶│
   │                    │                 │◀── updatePayment() ─│              │
   │                    │                 │                     │              │
   │         [paid=true]│                 │── APPROVED ─────────│              │
   │                    │                 │                     │              │
   │         [paid=false│                 │── REJECTED ─────────│              │
   │                    │                 │── markAsAvailable() ▶│ ◀─ SAGA ──  │
   │                    │                 │   (COMPENSAÇÃO)     │── AVAILABLE  │
```

---

## 3. Modelo de Dados

```
┌──────────────────────────────────────────────────────────────────┐
│  BANCO DE DADOS: vehicle_resale_db (PostgreSQL 15)               │
│                                                                  │
│  ┌─────────────────┐        ┌──────────────────────────────┐     │
│  │    vehicles     │        │          customers           │     │
│  ├─────────────────┤        ├──────────────────────────────┤     │
│  │ id (PK)         │        │ id (PK)                      │     │
│  │ brand           │        │ user_id (FK → Keycloak)      │     │
│  │ model           │        │ name                         │     │
│  │ year            │        │ email (unique)               │     │
│  │ color           │        │ cpf (unique)  ◀──── SENSÍVEL │     │
│  │ price           │        │ phone                        │     │
│  │ status          │        │ address       ◀──── SENSÍVEL │     │
│  │   AVAILABLE     │        │ city                         │     │
│  │   SOLD          │        │ state                        │     │
│  │ created_at      │        │ zip_code                     │     │
│  │ updated_at      │        │ active                       │     │
│  │ deleted_at      │        │ created_at                   │     │
│  └────────┬────────┘        │ updated_at                   │     │
│           │                 └─────────────┬────────────────┘     │
│           │                               │                      │
│           ▼                               ▼                      │
│  ┌────────────────────────────────────────────────────────┐      │
│  │                        sales                           │      │
│  ├────────────────────────────────────────────────────────┤      │
│  │ id (PK)                                                │      │
│  │ vehicle_id (FK → vehicles)                             │      │
│  │ buyer_name                      ◀──── SENSÍVEL         │      │
│  │ buyer_email                     ◀──── SENSÍVEL         │      │
│  │ buyer_cpf                       ◀──── SENSÍVEL         │      │
│  │ sale_date                                              │      │
│  │ sale_price                                             │      │
│  │ payment_code (UUID)                                    │      │
│  │ payment_status: PENDING / APPROVED / REJECTED          │      │
│  │ created_at                                             │      │
│  │ updated_at                                             │      │
│  └────────────────────────────────────────────────────────┘      │
└──────────────────────────────────────────────────────────────────┘
```

---

## 4. Arquitetura de Implantação em Nuvem (AWS)

### 4.1 Justificativa da escolha da AWS

A AWS foi escolhida como plataforma de nuvem por:

- **Maturidade e ecossistema:** Serviços gerenciados para todos os componentes da solução (EKS, RDS, Secrets Manager, WAF, ACM).
- **Serviços serverless nativos:** Suporte a contêineres (Fargate) e funções serverless (Lambda) sem necessidade de gerenciar infraestrutura.
- **Conformidade com LGPD:** Regiões brasileiras (sa-east-1 – São Paulo) com certificações SOC 2, ISO 27001, PCI DSS; contratos DPA disponíveis.
- **Segurança gerenciada:** AWS WAF, Shield, GuardDuty, Secrets Manager e KMS integrados de forma nativa.

### 4.2 Diagrama de Implantação na AWS

```
┌─────────────────────────────────────────────────────────────────────────┐
│  REGIÃO AWS: sa-east-1 (São Paulo)                                      │
│                                                                         │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │  VPC: 10.0.0.0/16                                                  │ │
│  │                                                                    │ │
│  │  ┌──────────────────────┐      ┌────────────────────────────────┐  │ │
│  │  │  PUBLIC SUBNETS      │      │  PRIVATE SUBNETS               │  │ │
│  │  │  (10.0.1.0/24)       │      │  (10.0.2.0/24)                 │  │ │
│  │  │                      │      │                                │  │ │
│  │  │  ┌────────────────┐  │      │  ┌────────────────────────┐   │  │ │
│  │  │  │  Application   │  │      │  │  Amazon EKS Cluster    │   │  │ │
│  │  │  │  Load Balancer │  │      │  │                        │   │  │ │
│  │  │  │  (ALB + WAF)   │──┼──────┼▶ │  ┌──────────────────┐ │   │  │ │
│  │  │  │  ACM (TLS)     │  │      │  │  │  vehicle-resale  │ │   │  │ │
│  │  │  └────────────────┘  │      │  │  │  api (Quarkus)   │ │   │  │ │
│  │  │                      │      │  │  │  Pod(s)          │ │   │  │ │
│  │  │  ┌────────────────┐  │      │  │  └──────────────────┘ │   │  │ │
│  │  │  │  Amazon Route53│  │      │  │                        │   │  │ │
│  │  │  │  (DNS)         │  │      │  │  ┌──────────────────┐ │   │  │ │
│  │  │  └────────────────┘  │      │  │  │  keycloak-idp    │ │   │  │ │
│  │  │                      │      │  │  │  Pod(s)          │ │   │  │ │
│  │  └──────────────────────┘      │  │  └──────────────────┘ │   │  │ │
│  │                                │  └────────────────────────┘   │  │ │
│  │                                │                                │  │ │
│  │                                │  ┌────────────────────────┐   │  │ │
│  │                                │  │  Amazon RDS PostgreSQL │   │  │ │
│  │                                │  │  (Multi-AZ)            │   │  │ │
│  │                                │  │                        │   │  │ │
│  │                                │  │  DB: vehicle_resale_db │   │  │ │
│  │                                │  │  DB: keycloak_db       │   │  │ │
│  │                                │  │  (Instâncias separadas)│   │  │ │
│  │                                │  └────────────────────────┘   │  │ │
│  │                                │                                │  │ │
│  │                                │  ┌────────────────────────┐   │  │ │
│  │                                │  │  AWS Secrets Manager   │   │  │ │
│  │                                │  │  (DB passwords, OIDC   │   │  │ │
│  │                                │  │   secrets)             │   │  │ │
│  │                                │  └────────────────────────┘   │  │ │
│  │                                └────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐│
│  │  SERVIÇOS DE SEGURANÇA E OBSERVABILIDADE                            ││
│  │  AWS WAF · AWS Shield Standard · AWS GuardDuty · AWS CloudTrail    ││
│  │  Amazon CloudWatch · AWS KMS (criptografia em repouso)             ││
│  │  AWS ACM (certificados TLS) · Amazon ECR (imagens de contêineres)  ││
│  └─────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Serviços de Nuvem Selecionados e Justificativas

### 5.1 Computação

| Serviço | Função | Justificativa |
|---------|--------|---------------|
| **Amazon EKS (Kubernetes)** | Orquestração de contêineres para API Quarkus e Keycloak | Gerenciado (sem gestão do control plane); escalonamento automático; integração nativa com ALB, IAM e Secrets Manager. |
| **AWS Fargate** (opção serverless para EKS) | Execução dos Pods sem gerenciar nós EC2 | Serverless: não há servidores a provisionar ou patchear; billing por CPU/memória consumidos pelo Pod; ideal para workloads variáveis. |
| **Amazon ECR** | Registro de imagens Docker | Integrado ao EKS e ao pipeline CI/CD (GitHub Actions → ECR → EKS); suporte a scan de vulnerabilidades (ECR image scanning). |

### 5.2 Banco de Dados

| Serviço | Função | Justificativa |
|---------|--------|---------------|
| **Amazon RDS for PostgreSQL** (Multi-AZ) | Banco transacional (vehicle_resale_db e keycloak_db em instâncias separadas) | Gerenciado: backups automáticos, failover Multi-AZ, patches de segurança; criptografia em repouso via KMS habilitada por padrão; compatível com PostgreSQL 15. |
| **Amazon RDS Proxy** (opcional) | Pool de conexões entre EKS e RDS | Reduz latência de conexão; suporte a failover transparente; integração com IAM Authentication (elimina senhas na aplicação). |

### 5.3 Rede e Exposição

| Serviço | Função | Justificativa |
|---------|--------|---------------|
| **Amazon VPC** | Isolamento de rede | Subnets públicas (ALB) e privadas (EKS, RDS); Security Groups restringem tráfego inter-serviços. |
| **Application Load Balancer (ALB)** | Entrada pública, TLS termination | Integração nativa com EKS Ingress Controller e ACM para TLS; health checks; roteamento por path. |
| **AWS Certificate Manager (ACM)** | Certificados TLS gerenciados | Provisionamento e renovação automáticos; sem custo adicional para certificados públicos. |
| **Amazon Route 53** | DNS | Roteamento de domínio; health checks de failover. |

### 5.4 Segurança

| Serviço | Função | Justificativa |
|---------|--------|---------------|
| **AWS WAF** | Firewall de aplicação web (integrado ao ALB) | Proteção contra OWASP Top 10 (SQLi, XSS, etc.); rate limiting por IP; regras gerenciadas pela AWS. |
| **AWS Shield Standard** | Proteção DDoS (incluso sem custo extra) | Proteção automática contra ataques volumétricos de camada 3/4. |
| **AWS Secrets Manager** | Armazenamento de credenciais (senhas de BD, client_secret do Keycloak, chave do webhook) | Rotação automática de secrets; integração com EKS via External Secrets Operator; elimina secrets em variáveis de ambiente em texto plano. |
| **AWS KMS (Key Management Service)** | Criptografia em repouso | Chaves gerenciadas para RDS (criptografia transparente) e para dados sensíveis (CPF) se implementada criptografia em nível de aplicação. |
| **AWS GuardDuty** | Detecção de ameaças e comportamentos anômalos | Monitora logs CloudTrail, VPC Flow Logs e DNS; alertas automáticos via SNS/EventBridge. |
| **AWS CloudTrail** | Auditoria de todas as ações na conta AWS | Conformidade; trilha de auditoria para LGPD e SOC 2. |
| **AWS IAM** | Controle de acesso aos serviços AWS | Princípio do menor privilégio; roles para EKS nodes e Fargate tasks (sem access keys em código). |

### 5.5 CI/CD e Observabilidade

| Serviço | Função | Justificativa |
|---------|--------|---------------|
| **GitHub Actions** | Pipeline CI/CD (build, test, push para ECR, deploy no EKS) | Já configurado no projeto; integração com ECR e kubectl. |
| **Amazon CloudWatch** | Logs centralizados e métricas (complementa Prometheus) | Coleta de logs dos Pods EKS (via Fluent Bit); alertas; integração com Grafana. |
| **AWS X-Ray** (opcional) | Rastreamento distribuído | Útil se a solução evoluir para microsserviços com comunicação entre APIs. |

---

## 6. Segurança em Profundidade

### 6.1 Camadas de Segurança

```
Camada 1 – Rede:
  VPC + Security Groups + NACLs
  ALB + WAF (OWASP rules, rate limiting)
  Shield Standard (DDoS)
  Acesso externo apenas via ALB (portas 80/443)
  EKS Nodes em subnets privadas (sem IP público)
  RDS sem acesso público (apenas VPC)

Camada 2 – Identidade e Acesso:
  Keycloak 23 (OAuth2/OIDC) para autenticação de usuários
  Roles: admin (gestão de veículos) / buyer (comprar, ver clientes, vendas)
  AWS IAM para acesso a serviços AWS (EKS, RDS, Secrets Manager)
  Sem credenciais em código: senhas via Secrets Manager

Camada 3 – Aplicação:
  Autenticação obrigatória por path (application.properties)
  Validação de entrada (Bean Validation) em todos os DTOs
  HTTPS forçado (TLS terminado no ALB; HSTS)
  CORS configurado
  Webhook de pagamento: recomendado validar com header secreto ou HMAC

Camada 4 – Dados:
  RDS criptografado em repouso (KMS)
  CPF, e-mail, endereço: acesso apenas autenticado
  Recomendação: mascaramento de CPF em logs
  Recomendação: criptografia em nível de aplicação para CPF (AES-256)
  Retenção e exclusão alinhadas à LGPD

Camada 5 – Auditoria e Monitoramento:
  CloudTrail: auditoria de ações na AWS
  GuardDuty: detecção de ameaças
  CloudWatch Logs: logs centralizados de aplicação e Keycloak
  Prometheus + Grafana: métricas e alertas operacionais
```

### 6.2 Conformidade LGPD

| Princípio LGPD | Implementação |
|----------------|---------------|
| **Finalidade** | CPF e endereço coletados exclusivamente para emissão de código de pagamento e documentação na retirada. |
| **Necessidade** | Apenas os dados estritamente necessários são armazenados (sem dados biométricos, sem documentos além do CPF). |
| **Acesso do Titular** | Endpoint `GET /api/customers/{id}` (autenticado) permite consulta dos próprios dados. |
| **Segurança** | Autenticação Keycloak, autorização por role, criptografia em trânsito (TLS) e em repouso (KMS/RDS). |
| **Responsabilização** | CloudTrail e logs de acesso auditáveis; DPA com a AWS disponível para a região sa-east-1. |

---

## 7. Decisões Arquiteturais (ADR – Architecture Decision Records)

### ADR-01: Clean Architecture (Hexagonal)

- **Decisão:** Adotar Clean Architecture com separação em camadas Domain, Application, Infrastructure.
- **Justificativa:** Desacopla a lógica de negócio de frameworks e detalhes de infraestrutura; facilita testes unitários; permite troca de banco ou framework sem alterar o domínio.
- **Consequências:** Mais arquivos e abstrações; necessidade de mappers DTO ↔ Entity; compensado pela testabilidade e manutenibilidade.

### ADR-02: Keycloak como serviço separado

- **Decisão:** Keycloak em contêiner/Pod separado com banco próprio (keycloak_db).
- **Justificativa:** Separação de responsabilidades (identidade vs. dados de negócio); banco de identidade isolado reduz superfície de ataque; Keycloak pode ser escalado independentemente.
- **Consequências:** Dois bancos PostgreSQL a gerenciar; configuração OIDC necessária; compensada pela robustez de segurança.

### ADR-03: SAGA de Compensação para rejeição de pagamento

- **Decisão:** Implementar SAGA de compensação no próprio serviço (`SaleService` + `VehicleController.markAsAvailable()`).
- **Justificativa:** Fluxo com dois recursos (veículo e venda) e único ponto de falha (pagamento rejeitado); compensação local é suficiente e evita complexidade de um orquestrador externo.
- **Consequências:** Se o sistema evoluir com mais serviços (gateway de pagamento externo, notificações), seria necessário evoluir para SAGA orquestrada com um motor de estados (ex.: AWS Step Functions).

### ADR-04: Amazon EKS com Fargate (serverless nodes)

- **Decisão:** Usar EKS com Fargate para execução dos Pods.
- **Justificativa:** Elimina gestão de servidores EC2; billing baseado em consumo real; integração nativa com IAM, Secrets Manager e ALB; adequado para o estágio atual da aplicação.
- **Consequências:** Limitações do Fargate (sem DaemonSets, sem acesso SSH a nodes); aceitas dado o contexto.

### ADR-05: Amazon RDS PostgreSQL Multi-AZ

- **Decisão:** Usar RDS PostgreSQL gerenciado em vez de PostgreSQL self-managed em contêiner.
- **Justificativa:** Backups automáticos; failover automático Multi-AZ (SLA 99,95%); patches de segurança gerenciados; criptografia em repouso inclusa; evita perda de dados em falhas de Pod.
- **Consequências:** Custo maior que contêiner self-managed; aceito dado o SLA e a criticidade dos dados.

---

## 8. Resumo dos Entregáveis

| Entregável | Documento | Status |
|------------|-----------|--------|
| Desenho da Arquitetura | `docs/ARQUITETURA_FASE5.md` (este documento) | Criado |
| Relatório de Segurança de Dados | `docs/RELATORIO_SEGURANCA_DADOS_FASE5.md` | Criado |
| Relatório SAGA | `docs/RELATORIO_SAGA_FASE5.md` | Criado |
| Validação de Requisitos | `docs/FASE_5_VALIDACAO_REQUISITOS.md` | Criado |
| Código-fonte (GitHub) | Repositório `vehicle-resale-api` | Disponível |

---

*Documento gerado para a Fase 5 – Dados e Segurança da Informação – PÓS-FIAP Arquitetura de Software.*
