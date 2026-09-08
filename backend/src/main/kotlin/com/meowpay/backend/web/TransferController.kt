package com.meowpay.backend.web

import com.meowpay.backend.service.InvalidTransferException
import com.meowpay.backend.service.TransferService
import com.meowpay.backend.web.dto.CreateTransferRequest
import com.meowpay.backend.web.dto.TransferDto
import jakarta.validation.Valid
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Sort
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

@RestController
@RequestMapping("/api/transfers")
class TransferController(private val transferService: TransferService) {

    @PostMapping
    fun createTransfer(@Valid @RequestBody body: CreateTransferRequest): ResponseEntity<TransferDto> {
        val transfer = transferService.transfer(body.fromCatId!!, body.toCatId!!, body.amountTreats!!)
        val dto = TransferDto(transfer.id, transfer.fromCatId, transfer.toCatId, transfer.amountTreats, transfer.createdAt)
        return ResponseEntity.status(HttpStatus.CREATED).body(dto)
    }

    @GetMapping
    fun history(
        @RequestParam(required = false) catId: UUID?,
        @RequestParam(required = false) page: Int?,
        @RequestParam(required = false) size: Int?,
    ): ResponseEntity<List<TransferDto>> {
        if (page == null && size == null) {
            val dtos = transferService.history(catId)
                .map { TransferDto(it.id, it.fromCatId, it.toCatId, it.amountTreats, it.createdAt) }
            return ResponseEntity.ok(dtos)
        }

        if (page == null || page < 0 || size == null || size <= 0) {
            throw InvalidTransferException("page must be >= 0 and size must be > 0")
        }

        val result = transferService.historyPage(catId, PageRequest.of(page, size, Sort.by("createdAt").descending()))
        val dtos = result.content.map { TransferDto(it.id, it.fromCatId, it.toCatId, it.amountTreats, it.createdAt) }
        return ResponseEntity.ok().header("X-Total-Count", result.totalElements.toString()).body(dtos)
    }
}
