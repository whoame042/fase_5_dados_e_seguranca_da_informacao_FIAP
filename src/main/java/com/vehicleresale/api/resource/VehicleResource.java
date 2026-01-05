package com.vehicleresale.api.resource;

import com.vehicleresale.api.dto.PageDTO;
import com.vehicleresale.api.dto.VehicleFilterDTO;
import com.vehicleresale.api.dto.VehicleRequestDTO;
import com.vehicleresale.api.dto.VehicleResponseDTO;
import com.vehicleresale.application.controller.VehicleController;
import jakarta.annotation.security.PermitAll;
import jakarta.annotation.security.RolesAllowed;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.media.Content;
import org.eclipse.microprofile.openapi.annotations.media.Schema;
import org.eclipse.microprofile.openapi.annotations.parameters.Parameter;
import org.eclipse.microprofile.openapi.annotations.responses.APIResponse;
import org.eclipse.microprofile.openapi.annotations.security.SecurityRequirement;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

/**
 * REST Adapter - Camada de Interface com HTTP.
 * 
 * Responsabilidades:
 * - Mapear requisicoes HTTP para chamadas do Controller Clean
 * - Tratar status HTTP (200, 201, 404, etc.)
 * - Validar dados de entrada (@Valid)
 * - Documentar API (OpenAPI/Swagger)
 * - NAO conter logica de negocio
 * - Delegar tudo para o Controller Clean Architecture
 * 
 * Seguranca:
 * - Listagens publicas (GET) - qualquer um pode visualizar veiculos
 * - Gestao (POST/PUT/DELETE) - apenas admin
 */
@Path("/api/vehicles")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Veiculos", description = "Operacoes relacionadas a veiculos")
public class VehicleResource {

    /**
     * Injeta Controller Clean Architecture (nao mais Service direto)
     * Controller orquestra Gateway + Presenter + Use Case
     */
    @Inject
    VehicleController vehicleController;

    @GET
    @Path("/available")
    @PermitAll
    @Operation(
        summary = "Listar veiculos disponiveis com paginacao e filtros",
        description = "Lista todos os veiculos disponiveis para venda com paginacao e filtros opcionais, ordenados por preco (do mais barato para o mais caro). Endpoint publico."
    )
    @APIResponse(
        responseCode = "200",
        description = "Pagina de veiculos disponiveis",
        content = @Content(schema = @Schema(implementation = PageDTO.class))
    )
    public Response listAvailableVehicles(
            @Parameter(description = "Numero da pagina (comeca em 0)")
            @QueryParam("page") @DefaultValue("0") int page,
            @Parameter(description = "Tamanho da pagina")
            @QueryParam("size") @DefaultValue("10") int size,
            @Parameter(description = "Filtro por marca")
            @QueryParam("brand") String brand,
            @Parameter(description = "Filtro por modelo")
            @QueryParam("model") String model,
            @Parameter(description = "Filtro por ano exato")
            @QueryParam("year") Integer year,
            @Parameter(description = "Filtro por ano minimo")
            @QueryParam("yearFrom") Integer yearFrom,
            @Parameter(description = "Filtro por ano maximo")
            @QueryParam("yearTo") Integer yearTo,
            @Parameter(description = "Filtro por cor")
            @QueryParam("color") String color,
            @Parameter(description = "Filtro por preco minimo")
            @QueryParam("priceFrom") Double priceFrom,
            @Parameter(description = "Filtro por preco maximo")
            @QueryParam("priceTo") Double priceTo) {
        
        // Monta o filtro (responsabilidade do adapter HTTP)
        VehicleFilterDTO filter = new VehicleFilterDTO();
        filter.brand = brand;
        filter.model = model;
        filter.year = year;
        filter.yearFrom = yearFrom;
        filter.yearTo = yearTo;
        filter.color = color;
        filter.priceFrom = priceFrom;
        filter.priceTo = priceTo;
        
        // Delega para Controller Clean Architecture
        PageDTO<VehicleResponseDTO> vehicles = vehicleController.listAvailableVehicles(page, size, filter);
        
        // Retorna resposta HTTP
        return Response.ok(vehicles).build();
    }

    @GET
    @Path("/sold")
    @PermitAll
    @Operation(
        summary = "Listar veiculos vendidos com paginacao e filtros",
        description = "Lista todos os veiculos vendidos com paginacao e filtros opcionais, ordenados por preco (do mais barato para o mais caro). Endpoint publico."
    )
    @APIResponse(
        responseCode = "200",
        description = "Pagina de veiculos vendidos",
        content = @Content(schema = @Schema(implementation = PageDTO.class))
    )
    public Response listSoldVehicles(
            @Parameter(description = "Numero da pagina (comeca em 0)")
            @QueryParam("page") @DefaultValue("0") int page,
            @Parameter(description = "Tamanho da pagina")
            @QueryParam("size") @DefaultValue("10") int size,
            @Parameter(description = "Filtro por marca")
            @QueryParam("brand") String brand,
            @Parameter(description = "Filtro por modelo")
            @QueryParam("model") String model,
            @Parameter(description = "Filtro por ano exato")
            @QueryParam("year") Integer year,
            @Parameter(description = "Filtro por ano minimo")
            @QueryParam("yearFrom") Integer yearFrom,
            @Parameter(description = "Filtro por ano maximo")
            @QueryParam("yearTo") Integer yearTo,
            @Parameter(description = "Filtro por cor")
            @QueryParam("color") String color,
            @Parameter(description = "Filtro por preco minimo")
            @QueryParam("priceFrom") Double priceFrom,
            @Parameter(description = "Filtro por preco maximo")
            @QueryParam("priceTo") Double priceTo) {
        
        // Monta o filtro
        VehicleFilterDTO filter = new VehicleFilterDTO();
        filter.brand = brand;
        filter.model = model;
        filter.year = year;
        filter.yearFrom = yearFrom;
        filter.yearTo = yearTo;
        filter.color = color;
        filter.priceFrom = priceFrom;
        filter.priceTo = priceTo;
        
        // Delega para Controller Clean
        PageDTO<VehicleResponseDTO> vehicles = vehicleController.listSoldVehicles(page, size, filter);
        return Response.ok(vehicles).build();
    }

    @GET
    @Path("/{id}")
    @PermitAll
    @Operation(
        summary = "Buscar veiculo por ID",
        description = "Retorna os detalhes de um veiculo especifico. Endpoint publico."
    )
    @APIResponse(
        responseCode = "200",
        description = "Veiculo encontrado",
        content = @Content(schema = @Schema(implementation = VehicleResponseDTO.class))
    )
    @APIResponse(
        responseCode = "404",
        description = "Veiculo nao encontrado"
    )
    public Response getVehicleById(
            @Parameter(description = "ID do veiculo", required = true)
            @PathParam("id") Long id) {
        // Delega para Controller Clean
        VehicleResponseDTO vehicle = vehicleController.getVehicleById(id);
        return Response.ok(vehicle).build();
    }

    @POST
    @RolesAllowed("admin")
    @SecurityRequirement(name = "keycloak")
    @Operation(
        summary = "Cadastrar novo veiculo",
        description = "Cadastra um novo veiculo para venda. Requer autenticacao de administrador."
    )
    @APIResponse(
        responseCode = "201",
        description = "Veiculo cadastrado com sucesso",
        content = @Content(schema = @Schema(implementation = VehicleResponseDTO.class))
    )
    @APIResponse(
        responseCode = "400",
        description = "Dados invalidos"
    )
    @APIResponse(
        responseCode = "401",
        description = "Nao autenticado"
    )
    @APIResponse(
        responseCode = "403",
        description = "Acesso negado - requer role admin"
    )
    public Response createVehicle(@Valid VehicleRequestDTO request) {
        // Delega para Controller Clean
        VehicleResponseDTO vehicle = vehicleController.createVehicle(request);
        return Response.status(Response.Status.CREATED).entity(vehicle).build();
    }

    @PUT
    @Path("/{id}")
    @RolesAllowed("admin")
    @SecurityRequirement(name = "keycloak")
    @Operation(
        summary = "Atualizar veiculo",
        description = "Atualiza os dados de um veiculo existente. Requer autenticacao de administrador."
    )
    @APIResponse(
        responseCode = "200",
        description = "Veiculo atualizado com sucesso",
        content = @Content(schema = @Schema(implementation = VehicleResponseDTO.class))
    )
    @APIResponse(
        responseCode = "404",
        description = "Veiculo nao encontrado"
    )
    @APIResponse(
        responseCode = "400",
        description = "Dados invalidos ou veiculo ja vendido"
    )
    @APIResponse(
        responseCode = "401",
        description = "Nao autenticado"
    )
    @APIResponse(
        responseCode = "403",
        description = "Acesso negado - requer role admin"
    )
    public Response updateVehicle(
            @Parameter(description = "ID do veiculo", required = true)
            @PathParam("id") Long id,
            @Valid VehicleRequestDTO request) {
        // Delega para Controller Clean
        VehicleResponseDTO vehicle = vehicleController.updateVehicle(id, request);
        return Response.ok(vehicle).build();
    }

    @DELETE
    @Path("/{id}")
    @RolesAllowed("admin")
    @SecurityRequirement(name = "keycloak")
    @Operation(
        summary = "Excluir veiculo (soft delete)",
        description = "Exclui logicamente um veiculo do sistema (soft delete). Requer autenticacao de administrador."
    )
    @APIResponse(
        responseCode = "204",
        description = "Veiculo excluido com sucesso"
    )
    @APIResponse(
        responseCode = "404",
        description = "Veiculo nao encontrado"
    )
    @APIResponse(
        responseCode = "400",
        description = "Nao e possivel excluir veiculo ja vendido"
    )
    @APIResponse(
        responseCode = "401",
        description = "Nao autenticado"
    )
    @APIResponse(
        responseCode = "403",
        description = "Acesso negado - requer role admin"
    )
    public Response deleteVehicle(
            @Parameter(description = "ID do veiculo", required = true)
            @PathParam("id") Long id) {
        // Delega para Controller Clean
        vehicleController.deleteVehicle(id);
        return Response.noContent().build();
    }
}
