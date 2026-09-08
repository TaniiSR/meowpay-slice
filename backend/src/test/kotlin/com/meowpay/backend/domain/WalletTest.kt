package com.meowpay.backend.domain

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import java.util.UUID
import kotlin.test.assertEquals

class WalletTest {

    @Test
    fun `credit rejects an amount that would overflow the balance`() {
        val wallet = Wallet(catId = UUID.randomUUID(), balanceTreats = 100)

        assertThrows<IllegalArgumentException> { wallet.credit(Long.MAX_VALUE - 50) }

        assertEquals(100L, wallet.balanceTreats)
    }

    @Test
    fun `credit rejects an amount that individually is fine but would push balance above the maximum`() {
        val wallet = Wallet(catId = UUID.randomUUID(), balanceTreats = Wallet.MAX_TREATS - 10)

        assertThrows<IllegalArgumentException> { wallet.credit(20) }

        assertEquals(Wallet.MAX_TREATS - 10, wallet.balanceTreats)
    }

    @Test
    fun `credit allows an amount that lands exactly on the maximum`() {
        val wallet = Wallet(catId = UUID.randomUUID(), balanceTreats = Wallet.MAX_TREATS - 10)

        wallet.credit(10)

        assertEquals(Wallet.MAX_TREATS, wallet.balanceTreats)
    }
}
