package com.vehicleresale.domain.service;

import com.vehicleresale.api.dto.SaleRequestDTO;
import com.vehicleresale.domain.entity.Sale;
import com.vehicleresale.domain.entity.Vehicle;
import com.vehicleresale.domain.enums.PaymentStatus;
import com.vehicleresale.domain.repository.SaleRepository;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.NotFoundException;
import java.util.UUID;

@ApplicationScoped
public class SaleService {

    @Inject
    SaleRepository saleRepository;

    @Inject
    VehicleService vehicleService;

    public Sale findById(Long id) {
        return saleRepository.findByIdOptional(id)
                .orElseThrow(() -> new NotFoundException("Venda não encontrada com ID: " + id));
    }

    public Sale findByPaymentCode(String paymentCode) {
        return saleRepository.findByPaymentCode(paymentCode)
                .orElseThrow(() -> new NotFoundException("Venda não encontrada com código de pagamento: " + paymentCode));
    }

    @Transactional
    public Sale create(SaleRequestDTO dto) {
        Vehicle vehicle = vehicleService.findById(dto.vehicleId);
        
        // Marca o veículo como vendido
        vehicleService.markAsSold(vehicle.id);
        
        // Cria a venda
        Sale sale = new Sale();
        sale.vehicle = vehicle;
        sale.buyerName = dto.buyerName;
        sale.buyerEmail = dto.buyerEmail;
        sale.buyerCpf = dto.buyerCpf;
        sale.saleDate = dto.saleDate;
        sale.salePrice = vehicle.price;
        sale.paymentCode = generatePaymentCode();
        sale.paymentStatus = PaymentStatus.PENDING;
        
        saleRepository.persist(sale);
        return sale;
    }

    @Transactional
    public Sale updatePaymentStatus(String paymentCode, Boolean paid) {
        Sale sale = findByPaymentCode(paymentCode);
        
        if (sale.paymentStatus != PaymentStatus.PENDING) {
            throw new IllegalStateException("Pagamento já foi processado");
        }
        
        sale.paymentStatus = paid ? PaymentStatus.APPROVED : PaymentStatus.REJECTED;
        saleRepository.persist(sale);
        
        return sale;
    }

    private String generatePaymentCode() {
        return UUID.randomUUID().toString();
    }
}

