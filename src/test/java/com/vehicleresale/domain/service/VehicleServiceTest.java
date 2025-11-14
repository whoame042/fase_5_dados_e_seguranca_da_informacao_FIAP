package com.vehicleresale.domain.service;

import com.vehicleresale.api.dto.VehicleRequestDTO;
import com.vehicleresale.domain.entity.Vehicle;
import com.vehicleresale.domain.enums.VehicleStatus;
import com.vehicleresale.domain.repository.VehicleRepositoryEnhanced;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.InjectMock;
import jakarta.inject.Inject;
import jakarta.ws.rs.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@QuarkusTest
class VehicleServiceTest {

    @Inject
    VehicleService vehicleService;

    @InjectMock
    VehicleRepositoryEnhanced vehicleRepository;

    private Vehicle testVehicle;

    @BeforeEach
    void setUp() {
        testVehicle = new Vehicle();
        testVehicle.id = 1L;
        testVehicle.brand = "Toyota";
        testVehicle.model = "Corolla";
        testVehicle.year = 2023;
        testVehicle.color = "Prata";
        testVehicle.price = new BigDecimal("95000.00");
        testVehicle.status = VehicleStatus.AVAILABLE;
    }

    @Test
    void testCreateVehicle() {
        // Given
        VehicleRequestDTO dto = new VehicleRequestDTO();
        dto.brand = "Toyota";
        dto.model = "Corolla";
        dto.year = 2023;
        dto.color = "Prata";
        dto.price = new BigDecimal("95000.00");

        doNothing().when(vehicleRepository).persist(any(Vehicle.class));

        // When
        Vehicle result = vehicleService.create(dto);

        // Then
        assertNotNull(result);
        assertEquals("Toyota", result.brand);
        assertEquals("Corolla", result.model);
        assertEquals(VehicleStatus.AVAILABLE, result.status);
        verify(vehicleRepository, times(1)).persist(any(Vehicle.class));
    }

    @Test
    void testFindById_Success() {
        // Given
        when(vehicleRepository.findByIdOptional(1L)).thenReturn(Optional.of(testVehicle));

        // When
        Vehicle result = vehicleService.findById(1L);

        // Then
        assertNotNull(result);
        assertEquals(1L, result.id);
        assertEquals("Toyota", result.brand);
    }

    @Test
    void testFindById_NotFound() {
        // Given
        when(vehicleRepository.findByIdOptional(999L)).thenReturn(Optional.empty());

        // When & Then
        assertThrows(NotFoundException.class, () -> vehicleService.findById(999L));
    }

    @Test
    void testFindById_Deleted() {
        // Given
        testVehicle.softDelete();
        when(vehicleRepository.findByIdOptional(1L)).thenReturn(Optional.of(testVehicle));

        // When & Then
        assertThrows(NotFoundException.class, () -> vehicleService.findById(1L));
    }

    @Test
    void testUpdateVehicle_Success() {
        // Given
        VehicleRequestDTO dto = new VehicleRequestDTO();
        dto.brand = "Toyota";
        dto.model = "Corolla XEI";
        dto.year = 2023;
        dto.color = "Preto";
        dto.price = new BigDecimal("98000.00");

        when(vehicleRepository.findByIdOptional(1L)).thenReturn(Optional.of(testVehicle));
        doNothing().when(vehicleRepository).persist(any(Vehicle.class));

        // When
        Vehicle result = vehicleService.update(1L, dto);

        // Then
        assertEquals("Corolla XEI", result.model);
        assertEquals("Preto", result.color);
        verify(vehicleRepository, times(1)).persist(any(Vehicle.class));
    }

    @Test
    void testUpdateVehicle_AlreadySold() {
        // Given
        testVehicle.status = VehicleStatus.SOLD;
        VehicleRequestDTO dto = new VehicleRequestDTO();
        
        when(vehicleRepository.findByIdOptional(1L)).thenReturn(Optional.of(testVehicle));

        // When & Then
        assertThrows(IllegalStateException.class, () -> vehicleService.update(1L, dto));
    }

    @Test
    void testMarkAsSold_Success() {
        // Given
        when(vehicleRepository.findByIdOptional(1L)).thenReturn(Optional.of(testVehicle));
        doNothing().when(vehicleRepository).persist(any(Vehicle.class));

        // When
        vehicleService.markAsSold(1L);

        // Then
        assertEquals(VehicleStatus.SOLD, testVehicle.status);
        verify(vehicleRepository, times(1)).persist(testVehicle);
    }

    @Test
    void testMarkAsSold_AlreadySold() {
        // Given
        testVehicle.status = VehicleStatus.SOLD;
        when(vehicleRepository.findByIdOptional(1L)).thenReturn(Optional.of(testVehicle));

        // When & Then
        assertThrows(IllegalStateException.class, () -> vehicleService.markAsSold(1L));
    }

    @Test
    void testDeleteVehicle_Success() {
        // Given
        when(vehicleRepository.findByIdOptional(1L)).thenReturn(Optional.of(testVehicle));
        doNothing().when(vehicleRepository).persist(any(Vehicle.class));

        // When
        vehicleService.delete(1L);

        // Then
        assertTrue(testVehicle.isDeleted());
        assertNotNull(testVehicle.deletedAt);
        verify(vehicleRepository, times(1)).persist(testVehicle);
    }

    @Test
    void testDeleteVehicle_AlreadySold() {
        // Given
        testVehicle.status = VehicleStatus.SOLD;
        when(vehicleRepository.findByIdOptional(1L)).thenReturn(Optional.of(testVehicle));

        // When & Then
        assertThrows(IllegalStateException.class, () -> vehicleService.delete(1L));
    }
}

