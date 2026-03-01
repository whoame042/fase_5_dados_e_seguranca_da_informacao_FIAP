package com.vehicleresale.domain.service;

import com.vehicleresale.api.dto.SaleRequestDTO;
import com.vehicleresale.application.controller.VehicleController;
import com.vehicleresale.application.gateway.VehicleGateway;
import com.vehicleresale.domain.entity.Customer;
import com.vehicleresale.domain.entity.Sale;
import com.vehicleresale.domain.entity.Vehicle;
import com.vehicleresale.domain.enums.PaymentStatus;
import com.vehicleresale.domain.enums.VehicleStatus;
import com.vehicleresale.domain.repository.SaleRepository;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.InjectMock;
import jakarta.inject.Inject;
import jakarta.ws.rs.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@QuarkusTest
class SaleServiceTest {

    @Inject
    SaleService saleService;

    @InjectMock
    SaleRepository saleRepository;

    @InjectMock
    VehicleGateway vehicleGateway;

    @InjectMock
    VehicleController vehicleController;

    @InjectMock
    CustomerService customerService;

    private Vehicle testVehicle;
    private Sale testSale;
    private Customer testCustomer;

    @BeforeEach
    void setUp() {
        testVehicle = new Vehicle();
        testVehicle.id = 1L;
        testVehicle.brand = "Toyota";
        testVehicle.model = "Corolla";
        testVehicle.price = new BigDecimal("95000.00");
        testVehicle.status = VehicleStatus.AVAILABLE;

        testSale = new Sale();
        testSale.id = 1L;
        testSale.vehicle = testVehicle;
        testSale.buyerName = "João Silva";
        testSale.buyerEmail = "joao.silva@email.com";
        testSale.buyerCpf = "12345678901";
        testSale.saleDate = LocalDate.now();
        testSale.salePrice = new BigDecimal("95000.00");
        testSale.paymentCode = "test-payment-code";
        testSale.paymentStatus = PaymentStatus.PENDING;

        testCustomer = new Customer();
        testCustomer.id = 1L;
        testCustomer.name = "João Silva";
        testCustomer.email = "joao.silva@email.com";
        testCustomer.cpf = "12345678901";
        testCustomer.active = true;
    }

    @Test
    void testCreateSale_Success() {
        // Given
        SaleRequestDTO dto = new SaleRequestDTO();
        dto.vehicleId = 1L;
        dto.buyerName = "João Silva";
        dto.buyerEmail = "joao.silva@email.com";
        dto.buyerCpf = "12345678901";
        dto.saleDate = LocalDate.now();

        when(vehicleGateway.findById(1L)).thenReturn(Optional.of(testVehicle));
        doNothing().when(vehicleController).markAsSold(1L);
        doNothing().when(saleRepository).persist(any(Sale.class));
        when(customerService.findByCpfOptional("12345678901")).thenReturn(Optional.of(testCustomer));

        // When
        Sale result = saleService.create(dto);

        // Then
        assertNotNull(result);
        assertEquals("João Silva", result.buyerName);
        assertEquals("joao.silva@email.com", result.buyerEmail);
        assertEquals("12345678901", result.buyerCpf);
        assertNotNull(result.paymentCode);
        assertEquals(PaymentStatus.PENDING, result.paymentStatus);
        verify(vehicleGateway, times(1)).findById(1L);
        verify(vehicleController, times(1)).markAsSold(1L);
        verify(saleRepository, times(1)).persist(any(Sale.class));
    }

    @Test
    void testFindById_Success() {
        // Given
        when(saleRepository.findByIdOptional(1L)).thenReturn(Optional.of(testSale));

        // When
        Sale result = saleService.findById(1L);

        // Then
        assertNotNull(result);
        assertEquals(1L, result.id);
        assertEquals("12345678901", result.buyerCpf);
    }

    @Test
    void testFindById_NotFound() {
        // Given
        when(saleRepository.findByIdOptional(999L)).thenReturn(Optional.empty());

        // When & Then
        assertThrows(NotFoundException.class, () -> saleService.findById(999L));
    }

    @Test
    void testFindByPaymentCode_Success() {
        // Given
        when(saleRepository.findByPaymentCode("test-payment-code"))
            .thenReturn(Optional.of(testSale));

        // When
        Sale result = saleService.findByPaymentCode("test-payment-code");

        // Then
        assertNotNull(result);
        assertEquals("test-payment-code", result.paymentCode);
    }

    @Test
    void testFindByPaymentCode_NotFound() {
        // Given
        when(saleRepository.findByPaymentCode("invalid-code"))
            .thenReturn(Optional.empty());

        // When & Then
        assertThrows(NotFoundException.class, 
            () -> saleService.findByPaymentCode("invalid-code"));
    }

    @Test
    void testUpdatePaymentStatus_Paid() {
        // Given
        when(saleRepository.findByPaymentCode("test-payment-code"))
            .thenReturn(Optional.of(testSale));
        doNothing().when(saleRepository).persist(any(Sale.class));

        // When
        Sale result = saleService.updatePaymentStatus("test-payment-code", true);

        // Then
        assertEquals(PaymentStatus.APPROVED, result.paymentStatus);
        verify(saleRepository, times(1)).persist(testSale);
    }

    @Test
    void testUpdatePaymentStatus_Rejected() {
        // Given - pagamento rejeitado deve disparar compensação SAGA (devolver veículo ao estoque)
        testSale.vehicle = testVehicle;
        testVehicle.id = 1L;
        when(saleRepository.findByPaymentCode("test-payment-code"))
            .thenReturn(Optional.of(testSale));
        doNothing().when(saleRepository).persist(any(Sale.class));
        doNothing().when(vehicleController).markAsAvailable(1L);

        // When
        Sale result = saleService.updatePaymentStatus("test-payment-code", false);

        // Then
        assertEquals(PaymentStatus.REJECTED, result.paymentStatus);
        verify(saleRepository, times(1)).persist(testSale);
        verify(vehicleController, times(1)).markAsAvailable(1L);
    }

    @Test
    void testUpdatePaymentStatus_AlreadyProcessed() {
        // Given
        testSale.paymentStatus = PaymentStatus.APPROVED;
        when(saleRepository.findByPaymentCode("test-payment-code"))
            .thenReturn(Optional.of(testSale));

        // When & Then
        assertThrows(IllegalStateException.class, 
            () -> saleService.updatePaymentStatus("test-payment-code", false));
    }
}

