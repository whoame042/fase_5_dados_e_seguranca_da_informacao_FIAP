package com.vehicleresale.api.resource;

import com.vehicleresale.api.dto.PaymentWebhookDTO;
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
import org.eclipse.microprofile.openapi.annotations.responses.APIResponse;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

@Path("/api/webhook/payment")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Webhook de Pagamento", description = "Endpoint para processamento de pagamentos")
public class PaymentWebhookResource {

    @Inject
    SaleService saleService;

    @POST
    @Operation(
        summary = "Processar status de pagamento",
        description = "Webhook para receber notificacoes de pagamento da entidade processadora"
    )
    @APIResponse(
        responseCode = "200",
        description = "Pagamento processado com sucesso",
        content = @Content(schema = @Schema(implementation = SaleResponseDTO.class))
    )
    @APIResponse(
        responseCode = "400",
        description = "Dados invalidos ou pagamento ja processado"
    )
    @APIResponse(
        responseCode = "404",
        description = "Codigo de pagamento nao encontrado"
    )
    public Response processPayment(@Valid PaymentWebhookDTO request) {
        SaleResponseDTO sale = new SaleResponseDTO(
            saleService.updatePaymentStatus(request.paymentCode, request.paid)
        );
        return Response.ok(sale).build();
    }
}

