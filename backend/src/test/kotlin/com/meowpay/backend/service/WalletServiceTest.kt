package com.meowpay.backend.service

import com.meowpay.backend.TestcontainersConfig
import com.meowpay.backend.domain.Cat
import com.meowpay.backend.domain.Wallet
import com.meowpay.backend.repository.CatRepository
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

@SpringBootTest
@Import(TestcontainersConfig::class)
class WalletServiceTest {

    @Autowired
    lateinit var walletService: WalletService

    @Autowired
    lateinit var catRepository: CatRepository

    @Autowired
    lateinit var walletRepository: WalletRepository

    private fun newCatWithBalance(name: String, balance: Long): UUID {
        val cat = catRepository.save(Cat(name = name))
        walletRepository.save(Wallet(catId = cat.id, balanceTreats = balance))
        return cat.id
    }

    @Test
    fun `credits a cat's wallet`() {
        val cat = newCatWithBalance("Topper", 50)

        val wallet = walletService.topUp(cat, 25)

        assertEquals(75L, wallet.balanceTreats)
        assertEquals(75L, walletRepository.findByCatId(cat)!!.balanceTreats)
    }

    @Test
    fun `rejects a non-positive top-up amount`() {
        val cat = newCatWithBalance("Topper", 50)

        assertThrows<InvalidTransferException> {
            walletService.topUp(cat, 0)
        }
        assertThrows<InvalidTransferException> {
            walletService.topUp(cat, -10)
        }
    }

    @Test
    fun `rejects a top-up for an unknown cat`() {
        val unknown = UUID.randomUUID()

        val exception = assertThrows<CatNotFoundException> {
            walletService.topUp(unknown, 10)
        }
        assertEquals(unknown, exception.catId)
    }

    @Test
    fun `concurrent top-ups on the same wallet never lose treats`() {
        val cat = newCatWithBalance("Topper", 0)

        val executor = Executors.newFixedThreadPool(4)
        val latch = CountDownLatch(50)

        repeat(50) {
            executor.submit {
                try {
                    runCatching { walletService.topUp(cat, 1) }
                } finally {
                    latch.countDown()
                }
            }
        }

        val completed = latch.await(30, TimeUnit.SECONDS)
        executor.shutdown()

        assertEquals(true, completed)
        assertEquals(50L, walletRepository.findByCatId(cat)!!.balanceTreats)
    }
}
