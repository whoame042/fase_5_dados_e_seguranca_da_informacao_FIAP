package com.vehicleresale.api.dto;

import com.vehicleresale.domain.entity.Sale;
import com.vehicleresale.domain.enums.PaymentStatus;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

public class SaleResponseDTO {

    public Long id;
    public VehicleResponseDTO vehicle;
    public String buyerName;
    public String buyerEmail;
    public String buyerCpf;
    public LocalDate saleDate;
    public BigDecimal salePrice;
    public String paymentCode;
    public PaymentStatus paymentStatus;
    public LocalDateTime createdAt;
    public LocalDateTime updatedAt;

    public SaleResponseDTO() {
    }

    public SaleResponseDTO(Sale sale) {
        this.id = sale.id;
        this.vehicle = new VehicleResponseDTO(sale.vehicle);
        this.buyerName = sale.buyerName;
        this.buyerEmail = sale.buyerEmail;
        this.buyerCpf = sale.buyerCpf;
        this.saleDate = sale.saleDate;
        this.salePrice = sale.salePrice;
        this.paymentCode = sale.paymentCode;
        this.paymentStatus = sale.paymentStatus;
        this.createdAt = sale.createdAt;
        this.updatedAt = sale.updatedAt;
    }
}

