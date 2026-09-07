package com.meowpay.backend.repository

import com.meowpay.backend.TestcontainersConfig
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest
import org.springframework.boot.jdbc.test.autoconfigure.AutoConfigureTestDatabase
import org.springframework.context.annotation.Import
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Import(TestcontainersConfig::class)
class SeedDataTest {

    @Autowired
    lateinit var catRepository: CatRepository

    @Autowired
    lateinit var walletRepository: WalletRepository

    @Test
    fun `V2 migration seeds the three named cats with their starting balances`() {
        val whiskersId = UUID.fromString("11111111-1111-1111-1111-111111111111")
        val mochiId = UUID.fromString("22222222-2222-2222-2222-222222222222")
        val biscuitId = UUID.fromString("33333333-3333-3333-3333-333333333333")

        val whiskers = catRepository.findById(whiskersId).orElse(null)
        val mochi = catRepository.findById(mochiId).orElse(null)
        val biscuit = catRepository.findById(biscuitId).orElse(null)

        assertNotNull(whiskers)
        assertEquals("Whiskers", whiskers.name)
        assertEquals(100L, walletRepository.findByCatId(whiskersId)?.balanceTreats)

        assertNotNull(mochi)
        assertEquals("Mochi", mochi.name)
        assertEquals(50L, walletRepository.findByCatId(mochiId)?.balanceTreats)

        assertNotNull(biscuit)
        assertEquals("Biscuit", biscuit.name)
        assertEquals(0L, walletRepository.findByCatId(biscuitId)?.balanceTreats)
    }
}
