package com.vehicleresale.api.resource;

import com.vehicleresale.api.dto.SaleRequestDTO;
import com.vehicleresale.api.dto.SaleResponseDTO;
import com.vehicleresale.domain.service.SaleService;
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
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

@Path("/api/sales")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Vendas", description = "Operacoes relacionadas a vendas de veiculos")
public class SaleResource {

    @Inject
    SaleService saleService;

    @GET
    @Path("/{id}")
    @Operation(
        summary = "Buscar venda por ID",
        description = "Retorna os detalhes de uma venda especifica"
    )
    @APIResponse(
        responseCode = "200",
        description = "Venda encontrada",
        content = @Content(schema = @Schema(implementation = SaleResponseDTO.class))
    )
    @APIResponse(
        responseCode = "404",
        description = "Venda nao encontrada"
    )
    public Response getSaleById(
            @Parameter(description = "ID da venda", required = true)
            @PathParam("id") Long id) {
        SaleResponseDTO sale = new SaleResponseDTO(saleService.findById(id));
        return Response.ok(sale).build();
    }

    @POST
    @Operation(
        summary = "Efetuar venda de veiculo",
        description = "Registra a venda de um veiculo e gera codigo de pagamento"
    )
    @APIResponse(
        responseCode = "201",
        description = "Venda registrada com sucesso",
        content = @Content(schema = @Schema(implementation = SaleResponseDTO.class))
    )
    @APIResponse(
        responseCode = "400",
        description = "Dados invalidos ou veiculo ja vendido"
    )
    @APIResponse(
        responseCode = "404",
        description = "Veiculo nao encontrado"
    )
    public Response createSale(@Valid SaleRequestDTO request) {
        SaleResponseDTO sale = new SaleResponseDTO(saleService.create(request));
        return Response.status(Response.Status.CREATED).entity(sale).build();
    }
}

