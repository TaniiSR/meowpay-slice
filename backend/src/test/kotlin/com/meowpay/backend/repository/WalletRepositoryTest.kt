package com.meowpay.backend.repository

import com.meowpay.backend.TestcontainersConfig
import com.meowpay.backend.domain.Cat
import com.meowpay.backend.domain.Wallet
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest
import org.springframework.boot.jdbc.test.autoconfigure.AutoConfigureTestDatabase
import org.springframework.context.annotation.Import
import org.springframework.dao.DataIntegrityViolationException
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Import(TestcontainersConfig::class)
class WalletRepositoryTest {

    @Autowired
    lateinit var catRepository: CatRepository

    @Autowired
    lateinit var walletRepository: WalletRepository

    @Test
    fun `findByCatId returns the wallet with its persisted balance`() {
        val cat = catRepository.save(Cat(name = "Test Cat"))
        walletRepository.save(Wallet(catId = cat.id, balanceTreats = 42))

        val found = walletRepository.findByCatId(cat.id)

        assertNotNull(found)
        assertEquals(42L, found.balanceTreats)
        assertEquals(cat.id, found.catId)
    }

    @Test
    fun `saving a wallet with a negative balance is rejected by the database`() {
        val cat = catRepository.save(Cat(name = "Test Cat"))
        val wallet = Wallet(catId = cat.id, balanceTreats = -1)

        assertThrows<DataIntegrityViolationException> {
            walletRepository.saveAndFlush(wallet)
        }
    }
}
