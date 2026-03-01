# Relatório – Orquestração SAGA (Fase 5)

## 1. Contexto do fluxo de venda

O processo de compra envolve:

1. **Criação da venda** (`POST /api/sales`): validação do comprador cadastrado, marcação do veículo como vendido (SOLD) e geração do código de pagamento (UUID).
2. **Processamento do pagamento** (webhook `POST /api/webhook/payment`): atualização do status da venda para APPROVED ou REJECTED.

Se o pagamento for **rejeitado** ou o cliente desistir, o veículo deve voltar a ficar disponível para venda. Isso caracteriza um cenário de **transação distribuída** (marca veículo + cria venda + depois atualiza status) em que uma falha em etapa posterior exige **compensação**.

---

## 2. Tipo de SAGA utilizada: compensação (backward recovery)

Foi adotada uma **SAGA de compensação** (backward recovery):

- **Passos forward:** (1) Marcar veículo como SOLD, (2) Criar registro de venda com status PENDING, (3) Retornar código de pagamento.
- **Falha considerada:** pagamento rejeitado (webhook com `paid: false`).
- **Compensação:** reverter o efeito do passo 1, ou seja, voltar o veículo para **AVAILABLE**, liberando-o novamente no estoque.

Não é necessário compensar a criação da venda: o registro de venda permanece com `paymentStatus = REJECTED`, o que mantém o histórico e a auditoria.

---

## 3. Justificativa

- **Orquestração implícita:** O orquestrador é o próprio fluxo da aplicação (SaleService + VehicleController). Não há um motor de orquestração externo (ex.: máquina de estados).
- **Compensação explícita:** A ação compensatória está implementada em `SaleService.updatePaymentStatus()`: quando `paid == false`, além de persistir `REJECTED`, é chamado `vehicleController.markAsAvailable(sale.vehicle.id)`.
- **Consistência eventual:** Após o webhook de pagamento rejeitado, o veículo volta a aparecer na listagem de disponíveis; a venda continua com status REJECTED.
- **Simplicidade:** Com apenas dois recursos (veículo e venda) e um único ponto de falha tratado (pagamento rejeitado), a compensação em um único serviço é suficiente. Para mais serviços (ex.: gateway de pagamento, notificações), poderia ser considerada SAGA orquestrada com um orquestrador central.

---

## 4. Implementação no código

| Componente | Responsabilidade |
|------------|------------------|
| `SaleService.create()` | Marca veículo como SOLD via `vehicleController.markAsSold(vehicleId)` e persiste a venda com PENDING. |
| `SaleService.updatePaymentStatus(paymentCode, paid)` | Atualiza status para APPROVED ou REJECTED; se `paid == false`, chama `vehicleController.markAsAvailable(sale.vehicle.id)` (compensação). |
| `VehicleController.markAsSold(vehicleId)` | Atualiza o veículo para status SOLD. |
| `VehicleController.markAsAvailable(vehicleId)` | Atualiza o veículo para status AVAILABLE (usado na compensação). |

---

## 5. Conclusão

O tipo de orquestração SAGA utilizado é **SAGA de compensação (backward recovery)**, com compensação implementada no mesmo serviço (monolito). A justificativa está no cenário de falha (pagamento não efetuado ou desistência), na necessidade de devolver o veículo ao estoque e na simplicidade do fluxo com dois recursos principais (veículo e venda).

Este relatório pode ser exportado para PDF para entrega na Fase 5.
