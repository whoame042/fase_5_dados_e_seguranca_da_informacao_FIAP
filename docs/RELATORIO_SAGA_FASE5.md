---
title: "Relatório de Orquestração SAGA"
subtitle: "Vehicle Resale API – Fase 5: Dados e Segurança da Informação"
author: "PÓS-FIAP – Arquitetura de Software"
date: "Março/2026"
---

# Relatório de Orquestração SAGA

**Projeto:** Vehicle Resale API  
**Disciplina:** Fase 5 – Dados e Segurança da Informação  
**Curso:** Pós-Graduação FIAP – Arquitetura de Software  
**Data:** Fevereiro/2026

---

## Sumário

1. [Contexto do Fluxo de Venda](#1-contexto-do-fluxo-de-venda)
2. [Tipo de SAGA Utilizada](#2-tipo-de-saga-utilizada)
3. [Diagrama do Fluxo SAGA](#3-diagrama-do-fluxo-saga)
4. [Justificativa da Escolha](#4-justificativa-da-escolha)
5. [Implementação no Código](#5-implementação-no-código)
6. [Conclusão](#6-conclusão)

---

## 1. Contexto do Fluxo de Venda

O processo de compra de veículos envolve múltiplas etapas que alteram o estado de recursos distintos — o **veículo** e a **venda**. Essa sequência caracteriza uma **transação distribuída** cujas etapas são:

| Etapa | Operação | Endpoint |
|-------|----------|----------|
| **1** | Comprador solicita a compra | `POST /api/sales` |
| **2** | Sistema valida CPF do comprador | Validação interna (`SaleService`) |
| **3** | Veículo é marcado como **SOLD** | `VehicleController.markAsSold()` |
| **4** | Venda é criada com status **PENDING** | Persistência via `SaleService` |
| **5** | Código de pagamento (UUID) é retornado | Resposta ao cliente |
| **6** | Pagamento é processado externamente | — |
| **7** | Status do pagamento é atualizado via webhook | `POST /api/webhook/payment` |

> **Problema de consistência:** se o pagamento for **rejeitado** na etapa 7, o veículo permanece como `SOLD` — bloqueado — mesmo sem uma venda efetivada. É necessário um mecanismo de **compensação** para reverter esse estado.

---

## 2. Tipo de SAGA Utilizada

Foi adotada a **SAGA de Compensação** (*backward recovery*), também conhecida como SAGA Coreografada com ação compensatória.

### Comparativo dos tipos de SAGA

| Critério | SAGA de Compensação *(adotada)* | SAGA Orquestrada |
|----------|---------------------------------|------------------|
| **Coordenação** | Implícita, dentro do próprio serviço | Orquestrador central externo |
| **Complexidade** | Baixa (2 recursos, 1 ponto de falha) | Alta (adequada para muitos serviços) |
| **Ferramentas** | Nenhuma adicional necessária | Requer motor de estados (ex.: AWS Step Functions) |
| **Rastreabilidade** | Via logs e status da venda (`REJECTED`) | Via dashboard do orquestrador |
| **Adequação ao projeto** | ✅ Ideal para o cenário atual | Recomendado em caso de expansão |

### Passos da transação

**Caminho feliz (pagamento aprovado):**

1. Marcar veículo → `SOLD`
2. Criar venda → `PENDING`
3. Receber webhook `paid: true` → venda passa para `APPROVED`

**Caminho de falha (pagamento rejeitado) — COMPENSAÇÃO:**

1. Marcar veículo → `SOLD`
2. Criar venda → `PENDING`
3. Receber webhook `paid: false` → venda passa para `REJECTED`
4. **Ação compensatória:** reverter veículo → `AVAILABLE` *(estoque liberado)*

> **Nota:** A criação da venda **não é compensada** intencionalmente. O registro com `paymentStatus = REJECTED` é mantido para fins de histórico e auditoria.

---

## 3. Diagrama do Fluxo SAGA

### Fluxo completo (caminho feliz e compensação)

```
 Cliente         SaleService          VehicleController     Webhook
    │                 │                       │                 │
    │── POST /sales ─▶│                       │                 │
    │                 │── markAsSold() ───────▶│                 │
    │                 │                       │── status: SOLD  │
    │                 │── persist(PENDING) ────│                 │
    │◀── paymentCode ─│                       │                 │
    │                 │                       │                 │
    │   (pagamento)   │                       │                 │
    │                 │◀─────────── POST /webhook/payment ──────│
    │                 │                       │                 │
    │        ┌────────┴────────┐              │                 │
    │        │  paid = true?   │              │                 │
    │        └────┬───────┬────┘              │                 │
    │         SIM │       │ NÃO               │                 │
    │             ▼       ▼                   │                 │
    │        APPROVED   REJECTED              │                 │
    │                     │                  │                 │
    │                     │── markAsAvailable()──────────────▶ │
    │                     │   (COMPENSAÇÃO SAGA)               │
    │                     │                  │── status: AVAILABLE
    │                     │                  │                 │
```

### Estados do veículo ao longo do fluxo

```
  AVAILABLE  ──[POST /sales]──▶  SOLD  ──[paid: true]──▶  SOLD (definitivo)
                                   │
                                   └──[paid: false]──▶  AVAILABLE (compensado)
```

---

## 4. Justificativa da Escolha

### Por que SAGA de Compensação?

**a) Simplicidade do domínio**

A solução possui dois recursos transacionais (veículo e venda) e um único ponto de falha tratado (rejeição do pagamento). Uma SAGA orquestrada com motor de estados externo adicionaria complexidade desnecessária.

**b) Orquestração implícita suficiente**

O `SaleService` já conhece ambos os recursos. A compensação pode ser executada diretamente, sem necessidade de um mediador externo.

**c) Consistência eventual aceitável**

O intervalo entre a criação da venda e o processamento do webhook é curto. O veículo fica temporariamente como `SOLD` até o webhook chegar, o que é aceitável para este domínio.

**d) Auditabilidade preservada**

A venda com `paymentStatus = REJECTED` é mantida no banco, garantindo rastreabilidade completa do ciclo de vida da transação.

### Evolução futura

Se a solução evoluir para incluir serviços adicionais (gateway de pagamento externo, serviço de notificações, geração de documentos), recomenda-se migrar para uma **SAGA Orquestrada** com um motor de estados como **AWS Step Functions** ou **Apache Camel Saga**.

---

## 5. Implementação no Código

### Componentes envolvidos

| Componente | Camada | Responsabilidade na SAGA |
|------------|--------|--------------------------|
| `SaleService.create()` | Domínio | Chama `markAsSold()` e persiste a venda com status `PENDING` |
| `SaleService.updatePaymentStatus()` | Domínio | Atualiza status para `APPROVED` ou `REJECTED`; aciona a compensação se `paid == false` |
| `VehicleController.markAsSold()` | Aplicação | Atualiza o veículo para status `SOLD` |
| `VehicleController.markAsAvailable()` | Aplicação | **Ação compensatória:** reverte o veículo para `AVAILABLE` |

### Trecho relevante da compensação

```java
// SaleService.java — updatePaymentStatus()
if (Boolean.FALSE.equals(paid)) {
    sale.paymentStatus = PaymentStatus.REJECTED;
    // Compensação SAGA: liberar o veículo de volta ao estoque
    vehicleController.markAsAvailable(sale.vehicle.id);
} else {
    sale.paymentStatus = PaymentStatus.APPROVED;
}
```

### Localização no repositório

| Arquivo | Caminho |
|---------|---------|
| `SaleService.java` | `src/main/java/com/vehicleresale/domain/service/` |
| `VehicleController.java` | `src/main/java/com/vehicleresale/application/controller/` |
| `SaleServiceTest.java` | `src/test/java/com/vehicleresale/domain/service/` |

> O teste `SaleServiceTest.testUpdatePaymentStatus_Rejected()` valida que `vehicleController.markAsAvailable()` é invocado quando `paid = false`, cobrindo o comportamento compensatório.

---

## 6. Conclusão

O padrão **SAGA de Compensação (backward recovery)** foi adotado por ser adequado ao porte e à complexidade da solução atual: dois recursos transacionais, um único ponto de falha e orquestração implícita dentro do próprio serviço de domínio.

A compensação garante que um veículo nunca fique "preso" no estoque com status `SOLD` após um pagamento rejeitado, mantendo a **consistência do inventário** e a **auditabilidade** da transação.

| Aspecto | Resultado |
|---------|-----------|
| Tipo de SAGA | Compensação (*backward recovery*) |
| Orquestrador | Implícito (`SaleService` + `VehicleController`) |
| Ponto de falha tratado | Pagamento rejeitado (`paid: false`) |
| Ação compensatória | `VehicleController.markAsAvailable()` |
| Consistência | Eventual (aceitável para o domínio) |
| Cobertura por teste | Sim (`SaleServiceTest`) |

---

*Documento elaborado para a Fase 5 – Dados e Segurança da Informação – PÓS-FIAP Arquitetura de Software.*
