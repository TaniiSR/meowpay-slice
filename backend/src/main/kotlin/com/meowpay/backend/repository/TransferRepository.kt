package com.meowpay.backend.repository

import com.meowpay.backend.domain.Transfer
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface TransferRepository : JpaRepository<Transfer, UUID> {
    fun findAllByFromCatIdOrToCatIdOrderByCreatedAtDesc(fromCatId: UUID, toCatId: UUID): List<Transfer>

    fun findAllByOrderByCreatedAtDesc(): List<Transfer>

    fun findAllByFromCatIdOrToCatIdOrderByCreatedAtDesc(fromCatId: UUID, toCatId: UUID, pageable: Pageable): Page<Transfer>

    fun findAllByOrderByCreatedAtDesc(pageable: Pageable): Page<Transfer>
}
