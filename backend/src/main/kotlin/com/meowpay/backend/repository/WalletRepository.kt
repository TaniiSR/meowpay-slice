package com.meowpay.backend.repository

import com.meowpay.backend.domain.Wallet
import jakarta.persistence.LockModeType
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Lock
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import java.util.UUID

interface WalletRepository : JpaRepository<Wallet, UUID> {
    fun findByCatId(catId: UUID): Wallet?

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select w from Wallet w where w.catId = :catId")
    fun findByCatIdForUpdate(@Param("catId") catId: UUID): Wallet?
}
