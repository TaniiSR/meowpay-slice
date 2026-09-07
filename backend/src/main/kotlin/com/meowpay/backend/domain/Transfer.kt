package com.meowpay.backend.domain

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "transfers")
class Transfer(
    @Id
    val id: UUID = UUID.randomUUID(),

    @Column(name = "from_cat_id", nullable = false)
    val fromCatId: UUID,

    @Column(name = "to_cat_id", nullable = false)
    val toCatId: UUID,

    @Column(name = "amount_treats", nullable = false)
    val amountTreats: Long,

    @Column(name = "created_at", nullable = false)
    val createdAt: Instant = Instant.now(),
)
