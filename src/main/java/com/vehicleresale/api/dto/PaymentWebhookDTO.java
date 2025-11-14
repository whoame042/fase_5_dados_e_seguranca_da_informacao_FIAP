package com.vehicleresale.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class PaymentWebhookDTO {

    @NotBlank(message = "Código do pagamento é obrigatório")
    public String paymentCode;

    @NotNull(message = "Status do pagamento é obrigatório")
    public Boolean paid;  // true = pagamento efetuado, false = pagamento cancelado
}

