package com.meowpay.backend.domain

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import jakarta.persistence.Version
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

    @Version
    val version: Int = 0,
) {
    fun credit(amount: Long) {
        require(amount > 0)
        balanceTreats += amount
    }

    fun debit(amount: Long) {
        require(amount > 0)
        check(balanceTreats >= amount)
        balanceTreats -= amount
    }
}
