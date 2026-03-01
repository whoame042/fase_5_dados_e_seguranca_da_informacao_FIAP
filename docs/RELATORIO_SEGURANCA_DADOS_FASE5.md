# Relatório de Segurança de Dados (Fase 5)

## 1. Dados armazenados pela solução

| Entidade | Dados armazenados |
|----------|-------------------|
| **Vehicle** | id, brand, model, year, color, price, status (AVAILABLE/SOLD), createdAt, updatedAt, deletedAt. |
| **Customer** | id, userId (Keycloak), name, email, cpf, phone, address, city, state, zipCode, active, createdAt, updatedAt. |
| **Sale** | id, vehicle_id, buyerName, buyerEmail, buyerCpf, saleDate, salePrice, paymentCode, paymentStatus (PENDING/APPROVED/REJECTED), createdAt, updatedAt. |

O Keycloak (serviço separado) armazena: usuários, credenciais, roles (admin, buyer) e tokens. Não armazena CPF nem endereço do cliente da API.

---

## 2. Dados sensíveis

- **CPF:** armazenado em `Customer.cpf` e em `Sale.buyerCpf`. Dado pessoal (LGPD), utilizado para emissão de código de pagamento e documentação na retirada.
- **E-mail:** em `Customer.email` e `Sale.buyerEmail`. Dado pessoal e canal de comunicação.
- **Nome completo:** em `Customer.name` e `Sale.buyerName`. Dado pessoal.
- **Endereço (telefone, address, city, state, zipCode):** em `Customer`. Dados pessoais para documentação e contato.
- **paymentCode:** identificador da transação de pagamento; não é dado sensível do titular, mas deve ser tratado com confidencialidade operacional.

Recomendações: (1) considerar mascaramento de CPF em logs e respostas quando não necessário; (2) em produção, uso de HTTPS e de criptografia em repouso (ex.: TDE no banco); (3) política de retenção e exclusão alinhada à LGPD.

---

## 3. Políticas de acesso a dados implementadas

- **Autenticação:** Keycloak (OAuth2/OIDC). Acesso à API com token JWT.
- **Autorização por path e método (application.properties):**
  - Público (sem autenticação): `GET /api/vehicles/available`, `GET /api/vehicles/{id}`, `GET /api/vehicles/sold`, health, metrics, openapi, swagger-ui.
  - Autenticado (qualquer role): `GET/POST/PUT /api/customers`, `GET/POST /api/sales`, `GET /api/sales/*`.
  - Role **admin:** `POST/PUT/DELETE /api/vehicles` e `DELETE /api/vehicles/*`.
- **Regras de negócio:** Venda exige cliente cadastrado (CPF válido no sistema); edição/exclusão de veículo vendido é bloqueada.
- **Webhook de pagamento:** Atualmente permitido sem autenticação (`permit`). Em produção recomenda-se restringir (ex.: header secreto, assinatura ou IP permitido).

---

## 4. Políticas de segurança da operação implementadas

- **Separação de responsabilidades:** Keycloak para identidade e acesso; API para dados transacionais (veículos, clientes, vendas).
- **Dois bancos:** PostgreSQL da API e PostgreSQL do Keycloak, reduzindo superfície de exposição de credenciais.
- **Proteção contra brute force:** Keycloak com `bruteForceProtected`, `failureFactor`, `maxFailureWaitSeconds` (realm-export.json).
- **Tokens:** accessTokenLifespan, ssoSessionIdleTimeout configurados no realm.
- **Logging:** logs de aplicação e de OIDC (nível configurável em application.properties).
- **Health e métricas:** endpoints para monitoramento (Prometheus); em produção devem ser restritos ou não expostos publicamente.

---

## 5. Riscos e ações de mitigação

| Risco | Mitigação implementada | Mitigação recomendada |
|-------|------------------------|------------------------|
| Acesso não autorizado à API | Autenticação Keycloak e políticas por path/role | HTTPS obrigatório; revisão periódica de permissões. |
| Exposição de dados sensíveis (CPF, e-mail) | Acesso a clientes e vendas apenas autenticado | Mascarar CPF em logs; criptografia em repouso; política de retenção. |
| Webhook de pagamento falsificado | — | Autenticar webhook (header/secreto ou assinatura); rate limit. |
| Venda com CPF não cadastrado | Validação em SaleService; cadastro obrigatório antes da compra | Mantida. |
| Veículo “preso” se pagamento falhar | Compensação SAGA: reverter veículo para AVAILABLE quando pagamento rejeitado | Mantida. |
| Perda/indisponibilidade de dados | Backup e alta disponibilidade do banco (fora do escopo da API) | Backup automatizado; replicação conforme SLA. |

---

## 6. Conclusão

A solução implementa controle de acesso (autenticação e autorização), separação entre identidade (Keycloak) e dados de negócio (API), e tratamento de dados sensíveis (CPF, e-mail, endereço) com acesso restrito a usuários autenticados. O relatório pode ser expandido com detalhes de criptografia, LGPD e operação em nuvem e exportado para PDF para entrega na Fase 5.
