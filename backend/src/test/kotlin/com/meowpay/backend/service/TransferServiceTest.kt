package com.meowpay.backend.service

import com.meowpay.backend.TestcontainersConfig
import com.meowpay.backend.domain.Cat
import com.meowpay.backend.domain.Wallet
import com.meowpay.backend.repository.CatRepository
import com.meowpay.backend.repository.TransferRepository
import com.meowpay.backend.repository.WalletRepository
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.context.annotation.Import
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import kotlin.test.assertEquals
import kotlin.test.assertTrue

@SpringBootTest
@Import(TestcontainersConfig::class)
class TransferServiceTest {

    @Autowired
    lateinit var transferService: TransferService

    @Autowired
    lateinit var catRepository: CatRepository

    @Autowired
    lateinit var walletRepository: WalletRepository

    @Autowired
    lateinit var transferRepository: TransferRepository

    private fun newCatWithBalance(name: String, balance: Long): UUID {
        val cat = catRepository.save(Cat(name = name))
        walletRepository.save(Wallet(catId = cat.id, balanceTreats = balance))
        return cat.id
    }

    @Test
    fun `moves treats from sender to recipient`() {
        val sender = newCatWithBalance("Sender", 100)
        val recipient = newCatWithBalance("Recipient", 50)

        val result = transferService.transfer(sender, recipient, 30)

        assertEquals(30L, result.amountTreats)
        assertEquals(sender, result.fromCatId)
        assertEquals(recipient, result.toCatId)
        assertEquals(70L, walletRepository.findByCatId(sender)!!.balanceTreats)
        assertEquals(80L, walletRepository.findByCatId(recipient)!!.balanceTreats)
        assertTrue(transferRepository.findById(result.id).isPresent)
    }

    @Test
    fun `rejects a transfer that would overdraw the sender`() {
        val sender = newCatWithBalance("A", 0)
        val recipient = newCatWithBalance("B", 0)

        assertThrows<InsufficientTreatsException> {
            transferService.transfer(sender, recipient, 1)
        }

        assertEquals(0L, walletRepository.findByCatId(sender)!!.balanceTreats)
    }

    @Test
    fun `rejects a cat sending treats to itself`() {
        val cat = newCatWithBalance("Solo", 10)

        assertThrows<InvalidTransferException> {
            transferService.transfer(cat, cat, 5)
        }
    }

    @Test
    fun `rejects a non-positive amount`() {
        val sender = newCatWithBalance("Sender", 10)
        val recipient = newCatWithBalance("Recipient", 10)

        assertThrows<InvalidTransferException> {
            transferService.transfer(sender, recipient, 0)
        }
        assertThrows<InvalidTransferException> {
            transferService.transfer(sender, recipient, -5)
        }
    }

    @Test
    fun `rejects a transfer from an unknown cat`() {
        val unknown = UUID.randomUUID()
        val recipient = newCatWithBalance("Recipient", 10)

        val exception = assertThrows<CatNotFoundException> {
            transferService.transfer(unknown, recipient, 5)
        }
        assertEquals(unknown, exception.catId)
    }

    @Test
    fun `rejects a transfer to an unknown cat`() {
        val sender = newCatWithBalance("Sender", 10)
        val unknown = UUID.randomUUID()

        val exception = assertThrows<CatNotFoundException> {
            transferService.transfer(sender, unknown, 5)
        }
        assertEquals(unknown, exception.catId)
    }

    @Test
    fun `concurrent opposing transfers between the same two cats never lose treats`() {
        val catA = newCatWithBalance("A", 100)
        val catB = newCatWithBalance("B", 100)

        val executor = Executors.newFixedThreadPool(4)
        val latch = CountDownLatch(40)

        repeat(20) {
            executor.submit {
                try {
                    runCatching { transferService.transfer(catA, catB, 1) }
                } finally {
                    latch.countDown()
                }
            }
            executor.submit {
                try {
                    runCatching { transferService.transfer(catB, catA, 1) }
                } finally {
                    latch.countDown()
                }
            }
        }

        val completed = latch.await(30, TimeUnit.SECONDS)
        executor.shutdown()

        assertTrue(completed, "transfers did not complete in time (possible deadlock)")
        val total = walletRepository.findByCatId(catA)!!.balanceTreats +
            walletRepository.findByCatId(catB)!!.balanceTreats
        assertEquals(200L, total)
    }
}
