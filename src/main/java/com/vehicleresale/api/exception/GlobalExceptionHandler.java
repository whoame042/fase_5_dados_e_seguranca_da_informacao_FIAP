package com.vehicleresale.api.exception;

import com.vehicleresale.api.dto.ErrorResponseDTO;
import jakarta.validation.ConstraintViolationException;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;

@Provider
public class GlobalExceptionHandler implements ExceptionMapper<Exception> {

    @Override
    public Response toResponse(Exception exception) {
        ErrorResponseDTO error = new ErrorResponseDTO();

        if (exception instanceof NotFoundException) {
            error.message = exception.getMessage();
            error.status = Response.Status.NOT_FOUND.getStatusCode();
            return Response.status(Response.Status.NOT_FOUND).entity(error).build();
        }

        if (exception instanceof IllegalStateException) {
            error.message = exception.getMessage();
            error.status = Response.Status.BAD_REQUEST.getStatusCode();
            return Response.status(Response.Status.BAD_REQUEST).entity(error).build();
        }

        if (exception instanceof ConstraintViolationException) {
            error.message = "Dados inválidos: " + exception.getMessage();
            error.status = Response.Status.BAD_REQUEST.getStatusCode();
            return Response.status(Response.Status.BAD_REQUEST).entity(error).build();
        }

        error.message = "Erro interno do servidor: " + exception.getMessage();
        error.status = Response.Status.INTERNAL_SERVER_ERROR.getStatusCode();
        return Response.status(Response.Status.INTERNAL_SERVER_ERROR).entity(error).build();
    }
}

