package com.vehicleresale.domain.service;

import com.vehicleresale.api.dto.SaleRequestDTO;
import com.vehicleresale.application.controller.VehicleController;
import com.vehicleresale.application.gateway.VehicleGateway;
import com.vehicleresale.domain.entity.Customer;
import com.vehicleresale.domain.entity.Sale;
import com.vehicleresale.domain.entity.Vehicle;
import com.vehicleresale.domain.enums.PaymentStatus;
import com.vehicleresale.domain.repository.SaleRepository;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.NotFoundException;
import java.util.UUID;

/**
 * Servico de vendas de veiculos.
 * 
 * Regra de negocio: O comprador DEVE estar cadastrado antes de realizar a compra.
 * O CPF informado na venda deve pertencer a um cliente ativo no sistema.
 */
@ApplicationScoped
public class SaleService {

    @Inject
    SaleRepository saleRepository;

    /**
     * Injeta VehicleController Clean Architecture
     * (nao mais VehicleService direto)
     */
    @Inject
    VehicleController vehicleController;
    
    /**
     * Injeta VehicleGateway para buscar entidades
     * (isola persistencia)
     */
    @Inject
    VehicleGateway vehicleGateway;

    /**
     * Injeta CustomerService para validar cliente cadastrado
     */
    @Inject
    CustomerService customerService;

    public Sale findById(Long id) {
        return saleRepository.findByIdOptional(id)
                .orElseThrow(() -> new NotFoundException("Venda nao encontrada com ID: " + id));
    }

    public Sale findByPaymentCode(String paymentCode) {
        return saleRepository.findByPaymentCode(paymentCode)
                .orElseThrow(() -> new NotFoundException("Venda nao encontrada com codigo de pagamento: " + paymentCode));
    }

    @Transactional
    public Sale create(SaleRequestDTO dto) {
        // VALIDACAO: O CPF deve pertencer a um cliente cadastrado
        Customer customer = customerService.findByCpfOptional(dto.buyerCpf)
                .orElseThrow(() -> new BadRequestException(
                    "O CPF informado nao esta cadastrado. " +
                    "O cadastro do cliente e obrigatorio ANTES da compra. " +
                    "Por favor, realize o cadastro em /api/customers primeiro."
                ));
        
        // Valida se os dados informados conferem com o cadastro do cliente
        if (!customer.name.equalsIgnoreCase(dto.buyerName)) {
            throw new BadRequestException(
                "O nome informado nao confere com o cadastro do cliente. " +
                "Verifique os dados informados."
            );
        }
        
        if (!customer.email.equalsIgnoreCase(dto.buyerEmail)) {
            throw new BadRequestException(
                "O email informado nao confere com o cadastro do cliente. " +
                "Verifique os dados informados."
            );
        }
        
        // Busca veiculo via Gateway (retorna Entity pura)
        Vehicle vehicle = vehicleGateway.findById(dto.vehicleId)
                .orElseThrow(() -> new NotFoundException("Veiculo nao encontrado com ID: " + dto.vehicleId));
        
        // Marca o veiculo como vendido usando Controller Clean
        vehicleController.markAsSold(vehicle.id);
        
        // Cria a venda
        Sale sale = new Sale();
        sale.vehicle = vehicle;
        sale.buyerName = customer.name;
        sale.buyerEmail = customer.email;
        sale.buyerCpf = customer.cpf;
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
            throw new IllegalStateException("Pagamento ja foi processado");
        }
        
        sale.paymentStatus = paid ? PaymentStatus.APPROVED : PaymentStatus.REJECTED;
        saleRepository.persist(sale);

        // Compensação SAGA: se pagamento rejeitado, devolver veículo ao estoque (disponível)
        if (!paid && sale.vehicle != null) {
            vehicleController.markAsAvailable(sale.vehicle.id);
        }
        
        return sale;
    }

    private String generatePaymentCode() {
        return UUID.randomUUID().toString();
    }
}
