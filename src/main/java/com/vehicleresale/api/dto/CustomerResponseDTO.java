package com.vehicleresale.api.dto;

import com.vehicleresale.domain.entity.Customer;
import java.time.LocalDateTime;

/**
 * DTO de resposta para dados de cliente.
 */
public class CustomerResponseDTO {

    public Long id;
    public String userId;
    public String name;
    public String email;
    public String cpf;
    public String phone;
    public String address;
    public String city;
    public String state;
    public String zipCode;
    public Boolean active;
    public LocalDateTime createdAt;
    public LocalDateTime updatedAt;

    public CustomerResponseDTO() {}

    public CustomerResponseDTO(Customer customer) {
        this.id = customer.id;
        this.userId = customer.userId;
        this.name = customer.name;
        this.email = customer.email;
        this.cpf = maskCpf(customer.cpf);
        this.phone = customer.phone;
        this.address = customer.address;
        this.city = customer.city;
        this.state = customer.state;
        this.zipCode = customer.zipCode;
        this.active = customer.active;
        this.createdAt = customer.createdAt;
        this.updatedAt = customer.updatedAt;
    }

    /**
     * Mascara o CPF para exibicao (XXX.XXX.XXX-XX -> ***.***.XXX-XX)
     */
    private String maskCpf(String cpf) {
        if (cpf == null || cpf.length() != 11) {
            return cpf;
        }
        return "***.***.".concat(cpf.substring(6, 9)).concat("-").concat(cpf.substring(9));
    }
}

