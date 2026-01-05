package com.vehicleresale.domain.service;

import com.vehicleresale.api.dto.CustomerRequestDTO;
import com.vehicleresale.domain.entity.Customer;
import com.vehicleresale.domain.repository.CustomerRepository;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.NotFoundException;

import java.util.List;
import java.util.Optional;

/**
 * Servico de gestao de clientes/compradores.
 * 
 * Regra de negocio: O cadastro de clientes deve ser feito ANTES da compra.
 * O cliente pode estar vinculado a um usuario do Keycloak (userId).
 */
@ApplicationScoped
public class CustomerService {

    @Inject
    CustomerRepository customerRepository;

    public List<Customer> findAll() {
        return customerRepository.findAllActive();
    }

    public Customer findById(Long id) {
        return customerRepository.findByIdOptional(id)
                .filter(c -> c.active)
                .orElseThrow(() -> new NotFoundException("Cliente nao encontrado com ID: " + id));
    }

    public Customer findByCpf(String cpf) {
        return customerRepository.findByCpf(cpf)
                .orElseThrow(() -> new NotFoundException("Cliente nao encontrado com CPF informado"));
    }

    public Optional<Customer> findByCpfOptional(String cpf) {
        return customerRepository.findByCpf(cpf);
    }

    public Customer findByUserId(String userId) {
        return customerRepository.findByUserId(userId)
                .orElseThrow(() -> new NotFoundException("Cliente nao encontrado para este usuario"));
    }

    public Optional<Customer> findByUserIdOptional(String userId) {
        return customerRepository.findByUserId(userId);
    }

    /**
     * Verifica se o CPF esta cadastrado como cliente ativo.
     * Necessario para validar a compra de veiculos.
     */
    public boolean isRegisteredCustomer(String cpf) {
        return customerRepository.findByCpf(cpf).isPresent();
    }

    @Transactional
    public Customer create(CustomerRequestDTO dto) {
        return create(dto, null);
    }

    @Transactional
    public Customer create(CustomerRequestDTO dto, String userId) {
        validateUniqueConstraints(dto, null);

        Customer customer = new Customer();
        customer.userId = userId;
        customer.name = dto.name;
        customer.email = dto.email;
        customer.cpf = cleanCpf(dto.cpf);
        customer.phone = dto.phone;
        customer.address = dto.address;
        customer.city = dto.city;
        customer.state = dto.state != null ? dto.state.toUpperCase() : null;
        customer.zipCode = dto.zipCode != null ? dto.zipCode.replace("-", "") : null;
        customer.active = true;

        customerRepository.persist(customer);
        return customer;
    }

    @Transactional
    public Customer update(Long id, CustomerRequestDTO dto) {
        Customer customer = findById(id);
        validateUniqueConstraints(dto, id);

        customer.name = dto.name;
        customer.email = dto.email;
        customer.cpf = cleanCpf(dto.cpf);
        customer.phone = dto.phone;
        customer.address = dto.address;
        customer.city = dto.city;
        customer.state = dto.state != null ? dto.state.toUpperCase() : null;
        customer.zipCode = dto.zipCode != null ? dto.zipCode.replace("-", "") : null;

        customerRepository.persist(customer);
        return customer;
    }

    @Transactional
    public Customer linkToUser(Long customerId, String userId) {
        Customer customer = findById(customerId);
        
        // Verifica se o userId ja esta vinculado a outro cliente
        Optional<Customer> existingCustomer = customerRepository.findByUserId(userId);
        if (existingCustomer.isPresent() && !existingCustomer.get().id.equals(customerId)) {
            throw new BadRequestException("Este usuario ja esta vinculado a outro cliente");
        }

        customer.userId = userId;
        customerRepository.persist(customer);
        return customer;
    }

    @Transactional
    public void delete(Long id) {
        Customer customer = findById(id);
        // Soft delete
        customer.active = false;
        customerRepository.persist(customer);
    }

    private void validateUniqueConstraints(CustomerRequestDTO dto, Long excludeId) {
        String cpf = cleanCpf(dto.cpf);
        
        boolean cpfExists = excludeId == null 
                ? customerRepository.existsByCpf(cpf)
                : customerRepository.existsByCpfExcludingId(cpf, excludeId);
        
        if (cpfExists) {
            throw new BadRequestException("Ja existe um cliente cadastrado com este CPF");
        }

        boolean emailExists = excludeId == null 
                ? customerRepository.existsByEmail(dto.email)
                : customerRepository.existsByEmailExcludingId(dto.email, excludeId);
        
        if (emailExists) {
            throw new BadRequestException("Ja existe um cliente cadastrado com este email");
        }
    }

    private String cleanCpf(String cpf) {
        return cpf != null ? cpf.replaceAll("[^0-9]", "") : null;
    }
}

