package com.vehicleresale.api.dto;

import jakarta.validation.constraints.*;

/**
 * DTO para criacao e atualizacao de clientes.
 * O cadastro deve ser feito antes da compra de veiculos.
 */
public class CustomerRequestDTO {

    @NotBlank(message = "Nome e obrigatorio")
    @Size(min = 3, max = 200, message = "Nome deve ter entre 3 e 200 caracteres")
    public String name;

    @NotBlank(message = "Email e obrigatorio")
    @Email(message = "Email invalido")
    @Size(max = 200, message = "Email deve ter no maximo 200 caracteres")
    public String email;

    @NotBlank(message = "CPF e obrigatorio")
    @Pattern(regexp = "\\d{11}", message = "CPF deve conter 11 digitos numericos")
    public String cpf;

    @Size(max = 20, message = "Telefone deve ter no maximo 20 caracteres")
    public String phone;

    @Size(max = 500, message = "Endereco deve ter no maximo 500 caracteres")
    public String address;

    @Size(max = 100, message = "Cidade deve ter no maximo 100 caracteres")
    public String city;

    @Size(min = 2, max = 2, message = "Estado deve ter 2 caracteres (UF)")
    public String state;

    @Pattern(regexp = "\\d{5}-?\\d{3}", message = "CEP deve estar no formato 00000-000 ou 00000000")
    public String zipCode;
}

