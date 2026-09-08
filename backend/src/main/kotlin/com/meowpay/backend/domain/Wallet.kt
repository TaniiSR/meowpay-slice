package com.meowpay.backend.domain

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.util.UUID

@Entity
@Table(name = "wallets")
class Wallet(
    @Id
    val id: UUID = UUID.randomUUID(),

    @Column(name = "cat_id", nullable = false, unique = true)
    val catId: UUID,

    @Column(name = "balance_treats", nullable = false)
    var balanceTreats: Long,
) {
    companion object {
        const val MAX_TREATS = 1_000_000_000_000L
    }

    fun credit(amount: Long) {
        require(amount > 0)
        require(amount <= MAX_TREATS) { "Amount must not exceed $MAX_TREATS treats" }
        require(balanceTreats <= MAX_TREATS - amount) { "Balance would exceed $MAX_TREATS treats" }
        balanceTreats += amount
    }

    fun debit(amount: Long) {
        require(amount > 0)
        check(balanceTreats >= amount)
        balanceTreats -= amount
    }
}
