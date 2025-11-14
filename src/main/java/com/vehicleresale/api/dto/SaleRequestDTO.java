package com.vehicleresale.api.dto;

import jakarta.validation.constraints.*;
import java.time.LocalDate;

public class SaleRequestDTO {

    @NotNull(message = "ID do veículo é obrigatório")
    public Long vehicleId;

    @NotBlank(message = "Nome do comprador é obrigatório")
    @Size(min = 3, max = 200, message = "Nome deve ter entre 3 e 200 caracteres")
    public String buyerName;

    @NotBlank(message = "Email do comprador é obrigatório")
    @Email(message = "Email inválido")
    @Size(max = 200, message = "Email deve ter no máximo 200 caracteres")
    public String buyerEmail;

    @NotBlank(message = "CPF do comprador é obrigatório")
    @Pattern(regexp = "\\d{11}", message = "CPF deve conter 11 dígitos numéricos")
    public String buyerCpf;

    @NotNull(message = "Data da venda é obrigatória")
    public LocalDate saleDate;
}

