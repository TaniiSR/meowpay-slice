package com.meowpay.backend.repository

import com.meowpay.backend.TestcontainersConfig
import com.meowpay.backend.domain.Cat
import com.meowpay.backend.domain.Transfer
import com.meowpay.backend.domain.Wallet
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest
import org.springframework.boot.jdbc.test.autoconfigure.AutoConfigureTestDatabase
import org.springframework.context.annotation.Import
import org.springframework.dao.DataIntegrityViolationException
import org.springframework.data.domain.PageRequest
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Import(TestcontainersConfig::class)
class TransferRepositoryTest {

    @Autowired
    lateinit var catRepository: CatRepository

    @Autowired
    lateinit var walletRepository: WalletRepository

    @Autowired
    lateinit var transferRepository: TransferRepository

    @Test
    fun `saving and reading back a transfer round-trips its fields`() {
        val fromCat = catRepository.save(Cat(name = "From Cat"))
        val toCat = catRepository.save(Cat(name = "To Cat"))
        walletRepository.save(Wallet(catId = fromCat.id, balanceTreats = 100))
        walletRepository.save(Wallet(catId = toCat.id, balanceTreats = 0))

        val saved = transferRepository.save(
            Transfer(fromCatId = fromCat.id, toCatId = toCat.id, amountTreats = 10)
        )

        val found = transferRepository.findById(saved.id).orElse(null)

        assertNotNull(found)
        assertEquals(saved.id, found.id)
        assertEquals(fromCat.id, found.fromCatId)
        assertEquals(toCat.id, found.toCatId)
        assertEquals(10L, found.amountTreats)
        assertEquals(saved.createdAt, found.createdAt)
    }

    @Test
    fun `rejects a transfer with non-positive amount`() {
        val fromCat = catRepository.save(Cat(name = "From Cat"))
        val toCat = catRepository.save(Cat(name = "To Cat"))
        val transfer = Transfer(fromCatId = fromCat.id, toCatId = toCat.id, amountTreats = 0)

        assertThrows<DataIntegrityViolationException> {
            transferRepository.saveAndFlush(transfer)
        }
    }

    @Test
    fun `rejects a transfer from a cat to itself`() {
        val cat = catRepository.save(Cat(name = "Solo Cat"))
        val transfer = Transfer(fromCatId = cat.id, toCatId = cat.id, amountTreats = 10)

        assertThrows<DataIntegrityViolationException> {
            transferRepository.saveAndFlush(transfer)
        }
    }

    @Test
    fun `paginates transfers ordered newest first`() {
        val fromCat = catRepository.save(Cat(name = "From Cat"))
        val toCat = catRepository.save(Cat(name = "To Cat"))
        walletRepository.save(Wallet(catId = fromCat.id, balanceTreats = 1000))
        walletRepository.save(Wallet(catId = toCat.id, balanceTreats = 0))
        val saved = (1..5).map {
            transferRepository.save(Transfer(fromCatId = fromCat.id, toCatId = toCat.id, amountTreats = it.toLong()))
        }

        val page = transferRepository.findAllByOrderByCreatedAtDesc(PageRequest.of(0, 2))

        assertEquals(5L, page.totalElements)
        assertEquals(2, page.content.size)
        assertEquals(saved.last().id, page.content.first().id)
    }
}
