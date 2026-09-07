package com.meowpay.backend.repository

import com.meowpay.backend.domain.Wallet
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface WalletRepository : JpaRepository<Wallet, UUID> {
    fun findByCatId(catId: UUID): Wallet?
}
