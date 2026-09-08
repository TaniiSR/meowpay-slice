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
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Sort
import java.util.UUID
import java.util.concurrent.ConcurrentLinkedQueue
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
    fun `rejects a transfer that would push the recipient's balance past the maximum allowed treats`() {
        val sender = newCatWithBalance("Sender", Wallet.MAX_TREATS)
        val recipient = newCatWithBalance("Recipient", 1)

        assertThrows<InvalidTransferException> {
            transferService.transfer(sender, recipient, Wallet.MAX_TREATS)
        }
        assertEquals(Wallet.MAX_TREATS, walletRepository.findByCatId(sender)!!.balanceTreats)
        assertEquals(1L, walletRepository.findByCatId(recipient)!!.balanceTreats)
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
    fun `historyPage returns only the requested page`() {
        val sender = newCatWithBalance("Sender", 1000)
        val recipient = newCatWithBalance("Recipient", 0)
        repeat(5) { transferService.transfer(sender, recipient, 1) }

        val page = transferService.historyPage(catId = sender, pageable = PageRequest.of(0, 2, Sort.by("createdAt").descending()))

        assertEquals(5L, page.totalElements)
        assertEquals(2, page.content.size)
    }

    @Test
    fun `concurrent opposing transfers between the same two cats never lose treats`() {
        val catA = newCatWithBalance("A", 100)
        val catB = newCatWithBalance("B", 100)

        val executor = Executors.newFixedThreadPool(4)
        val latch = CountDownLatch(40)
        val failures = ConcurrentLinkedQueue<Throwable>()

        repeat(20) {
            executor.submit {
                try {
                    transferService.transfer(catA, catB, 1)
                } catch (t: Throwable) {
                    failures.add(t)
                } finally {
                    latch.countDown()
                }
            }
            executor.submit {
                try {
                    transferService.transfer(catB, catA, 1)
                } catch (t: Throwable) {
                    failures.add(t)
                } finally {
                    latch.countDown()
                }
            }
        }

        val completed = latch.await(30, TimeUnit.SECONDS)
        executor.shutdown()

        assertTrue(completed, "transfers did not complete in time (possible deadlock)")
        assertTrue(failures.isEmpty(), "expected no failures, got: $failures")
        val total = walletRepository.findByCatId(catA)!!.balanceTreats +
            walletRepository.findByCatId(catB)!!.balanceTreats
        assertEquals(200L, total)
    }
}
