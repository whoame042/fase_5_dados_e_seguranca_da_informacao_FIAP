package com.vehicleresale.api.resource;

import com.vehicleresale.api.dto.CustomerRequestDTO;
import com.vehicleresale.api.dto.CustomerResponseDTO;
import com.vehicleresale.domain.entity.Customer;
import com.vehicleresale.domain.service.CustomerService;
import io.quarkus.security.identity.SecurityIdentity;
import jakarta.annotation.security.RolesAllowed;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.jwt.JsonWebToken;
import jakarta.enterprise.inject.Instance;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.media.Content;
import org.eclipse.microprofile.openapi.annotations.media.Schema;
import org.eclipse.microprofile.openapi.annotations.parameters.Parameter;
import org.eclipse.microprofile.openapi.annotations.responses.APIResponse;
import org.eclipse.microprofile.openapi.annotations.security.SecurityRequirement;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.List;
import java.util.stream.Collectors;

/**
 * REST Resource para gerenciamento de clientes/compradores.
 * 
 * O cadastro de clientes e obrigatorio ANTES da compra de veiculos.
 * Este recurso permite que usuarios autenticados gerenciem seu proprio cadastro.
 */
@Path("/api/customers")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Clientes", description = "Operacoes de cadastro e gerenciamento de clientes/compradores")
@SecurityRequirement(name = "keycloak")
public class CustomerResource {

    @Inject
    CustomerService customerService;

    @Inject
    SecurityIdentity securityIdentity;

    @Inject
    Instance<JsonWebToken> jwtInstance;
    
    private JsonWebToken getJwt() {
        return jwtInstance.isResolvable() ? jwtInstance.get() : null;
    }

    @GET
    @Operation(
        summary = "Listar todos os clientes",
        description = "Lista todos os clientes cadastrados (apenas admin)"
    )
    @APIResponse(
        responseCode = "200",
        description = "Lista de clientes",
        content = @Content(schema = @Schema(implementation = CustomerResponseDTO.class))
    )
    @RolesAllowed("admin")
    public Response listAll() {
        List<CustomerResponseDTO> customers = customerService.findAll().stream()
                .map(CustomerResponseDTO::new)
                .collect(Collectors.toList());
        return Response.ok(customers).build();
    }

    @GET
    @Path("/{id}")
    @Operation(
        summary = "Buscar cliente por ID",
        description = "Retorna os detalhes de um cliente especifico"
    )
    @APIResponse(
        responseCode = "200",
        description = "Cliente encontrado",
        content = @Content(schema = @Schema(implementation = CustomerResponseDTO.class))
    )
    @APIResponse(
        responseCode = "404",
        description = "Cliente nao encontrado"
    )
    @RolesAllowed({"admin", "buyer"})
    public Response getById(
            @Parameter(description = "ID do cliente", required = true)
            @PathParam("id") Long id) {
        Customer customer = customerService.findById(id);
        
        // Verificar se o usuario pode ver este cliente
        if (!isAdminOrOwner(customer)) {
            return Response.status(Response.Status.FORBIDDEN).build();
        }
        
        return Response.ok(new CustomerResponseDTO(customer)).build();
    }

    @GET
    @Path("/me")
    @Operation(
        summary = "Buscar meu cadastro",
        description = "Retorna os dados do cliente vinculado ao usuario autenticado"
    )
    @APIResponse(
        responseCode = "200",
        description = "Cliente encontrado",
        content = @Content(schema = @Schema(implementation = CustomerResponseDTO.class))
    )
    @APIResponse(
        responseCode = "404",
        description = "Cliente nao cadastrado"
    )
    @RolesAllowed({"admin", "buyer"})
    public Response getMyProfile() {
        JsonWebToken jwt = getJwt();
        if (jwt == null) {
            throw new IllegalStateException("JWT token não disponível");
        }
        String userId = jwt.getSubject();
        Customer customer = customerService.findByUserId(userId);
        return Response.ok(new CustomerResponseDTO(customer)).build();
    }

    @GET
    @Path("/cpf/{cpf}")
    @Operation(
        summary = "Buscar cliente por CPF",
        description = "Retorna os dados do cliente pelo CPF (apenas admin)"
    )
    @APIResponse(
        responseCode = "200",
        description = "Cliente encontrado",
        content = @Content(schema = @Schema(implementation = CustomerResponseDTO.class))
    )
    @APIResponse(
        responseCode = "404",
        description = "Cliente nao encontrado"
    )
    @RolesAllowed("admin")
    public Response getByCpf(
            @Parameter(description = "CPF do cliente (11 digitos)", required = true)
            @PathParam("cpf") String cpf) {
        Customer customer = customerService.findByCpf(cpf);
        return Response.ok(new CustomerResponseDTO(customer)).build();
    }

    @GET
    @Path("/check/{cpf}")
    @Operation(
        summary = "Verificar se CPF esta cadastrado",
        description = "Verifica se existe um cliente cadastrado com o CPF informado"
    )
    @APIResponse(
        responseCode = "200",
        description = "Resultado da verificacao"
    )
    @RolesAllowed({"admin", "buyer"})
    public Response checkCpfRegistered(
            @Parameter(description = "CPF do cliente (11 digitos)", required = true)
            @PathParam("cpf") String cpf) {
        boolean isRegistered = customerService.isRegisteredCustomer(cpf);
        return Response.ok(new CheckCpfResponse(cpf, isRegistered)).build();
    }

    @POST
    @Operation(
        summary = "Cadastrar novo cliente",
        description = "Cadastra um novo cliente no sistema. O cadastro e obrigatorio antes de realizar compras."
    )
    @APIResponse(
        responseCode = "201",
        description = "Cliente cadastrado com sucesso",
        content = @Content(schema = @Schema(implementation = CustomerResponseDTO.class))
    )
    @APIResponse(
        responseCode = "400",
        description = "Dados invalidos ou CPF/email ja cadastrado"
    )
    @RolesAllowed({"admin", "buyer"})
    public Response create(@Valid CustomerRequestDTO request) {
        JsonWebToken jwt = getJwt();
        if (jwt == null) {
            throw new IllegalStateException("JWT token não disponível");
        }
        String userId = jwt.getSubject();
        Customer customer = customerService.create(request, userId);
        return Response.status(Response.Status.CREATED)
                .entity(new CustomerResponseDTO(customer))
                .build();
    }

    @PUT
    @Path("/{id}")
    @Operation(
        summary = "Atualizar dados do cliente",
        description = "Atualiza os dados de um cliente existente"
    )
    @APIResponse(
        responseCode = "200",
        description = "Cliente atualizado com sucesso",
        content = @Content(schema = @Schema(implementation = CustomerResponseDTO.class))
    )
    @APIResponse(
        responseCode = "404",
        description = "Cliente nao encontrado"
    )
    @APIResponse(
        responseCode = "400",
        description = "Dados invalidos ou CPF/email ja cadastrado"
    )
    @RolesAllowed({"admin", "buyer"})
    public Response update(
            @Parameter(description = "ID do cliente", required = true)
            @PathParam("id") Long id,
            @Valid CustomerRequestDTO request) {
        Customer customer = customerService.findById(id);
        
        // Verificar se o usuario pode editar este cliente
        if (!isAdminOrOwner(customer)) {
            return Response.status(Response.Status.FORBIDDEN).build();
        }
        
        customer = customerService.update(id, request);
        return Response.ok(new CustomerResponseDTO(customer)).build();
    }

    @DELETE
    @Path("/{id}")
    @Operation(
        summary = "Desativar cliente",
        description = "Desativa o cadastro de um cliente (soft delete)"
    )
    @APIResponse(
        responseCode = "204",
        description = "Cliente desativado com sucesso"
    )
    @APIResponse(
        responseCode = "404",
        description = "Cliente nao encontrado"
    )
    @RolesAllowed("admin")
    public Response delete(
            @Parameter(description = "ID do cliente", required = true)
            @PathParam("id") Long id) {
        customerService.delete(id);
        return Response.noContent().build();
    }

    private boolean isAdminOrOwner(Customer customer) {
        if (securityIdentity.hasRole("admin")) {
            return true;
        }
        JsonWebToken jwt = getJwt();
        if (jwt == null) {
            throw new IllegalStateException("JWT token não disponível");
        }
        String userId = jwt.getSubject();
        return userId != null && userId.equals(customer.userId);
    }

    // Classe interna para resposta de verificacao de CPF
    public static class CheckCpfResponse {
        public String cpf;
        public boolean registered;

        public CheckCpfResponse(String cpf, boolean registered) {
            this.cpf = cpf;
            this.registered = registered;
        }
    }
}

