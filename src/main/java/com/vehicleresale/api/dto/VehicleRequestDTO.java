package com.vehicleresale.api.dto;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public class VehicleRequestDTO {

    @NotBlank(message = "Marca é obrigatória")
    @Size(max = 100, message = "Marca deve ter no máximo 100 caracteres")
    public String brand;

    @NotBlank(message = "Modelo é obrigatório")
    @Size(max = 100, message = "Modelo deve ter no máximo 100 caracteres")
    public String model;

    @NotNull(message = "Ano é obrigatório")
    @Min(value = 1900, message = "Ano deve ser maior que 1900")
    @Max(value = 2100, message = "Ano deve ser menor que 2100")
    public Integer year;

    @NotBlank(message = "Cor é obrigatória")
    @Size(max = 50, message = "Cor deve ter no máximo 50 caracteres")
    public String color;

    @NotNull(message = "Preço é obrigatório")
    @DecimalMin(value = "0.01", message = "Preço deve ser maior que zero")
    public BigDecimal price;
}

