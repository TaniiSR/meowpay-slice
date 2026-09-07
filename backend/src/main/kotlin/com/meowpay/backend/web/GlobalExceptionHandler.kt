package com.meowpay.backend.web

import com.meowpay.backend.service.CatNotFoundException
import com.meowpay.backend.service.InsufficientTreatsException
import com.meowpay.backend.service.InvalidTransferException
import com.meowpay.backend.web.dto.ErrorResponse
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice

@RestControllerAdvice
class GlobalExceptionHandler {

    @ExceptionHandler(CatNotFoundException::class)
    fun handleCatNotFound(ex: CatNotFoundException): ResponseEntity<ErrorResponse> =
        ResponseEntity.status(HttpStatus.NOT_FOUND).body(ErrorResponse("NOT_FOUND", ex.message!!))

    @ExceptionHandler(InsufficientTreatsException::class)
    fun handleInsufficientTreats(ex: InsufficientTreatsException): ResponseEntity<ErrorResponse> =
        ResponseEntity.status(HttpStatus.CONFLICT).body(ErrorResponse("INSUFFICIENT_TREATS", ex.message!!))

    @ExceptionHandler(InvalidTransferException::class)
    fun handleInvalidTransfer(ex: InvalidTransferException): ResponseEntity<ErrorResponse> =
        ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ErrorResponse("INVALID_TRANSFER", ex.message!!))

    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidation(ex: MethodArgumentNotValidException): ResponseEntity<ErrorResponse> {
        val message = ex.bindingResult.fieldErrors.firstOrNull()?.defaultMessage ?: "Invalid request"
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ErrorResponse("VALIDATION_ERROR", message))
    }
}
