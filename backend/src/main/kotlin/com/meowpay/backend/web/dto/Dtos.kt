package com.meowpay.backend.web.dto

import com.meowpay.backend.domain.Wallet
import jakarta.validation.constraints.Max
import jakarta.validation.constraints.NotNull
import jakarta.validation.constraints.Positive
import java.time.Instant
import java.util.UUID

data class CatDto(val id: UUID, val name: String, val balanceTreats: Long)

data class TransferDto(
    val id: UUID,
    val fromCatId: UUID,
    val toCatId: UUID,
    val amountTreats: Long,
    val createdAt: Instant,
)

data class CreateTransferRequest(
    @field:NotNull val fromCatId: UUID?,
    @field:NotNull val toCatId: UUID?,
    @field:NotNull @field:Positive @field:Max(Wallet.MAX_TREATS) val amountTreats: Long?,
)

data class TopUpRequest(
    @field:NotNull @field:Positive @field:Max(Wallet.MAX_TREATS) val amountTreats: Long?,
)

data class ErrorResponse(val error: String, val message: String)
