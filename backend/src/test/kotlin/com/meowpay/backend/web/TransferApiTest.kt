package com.meowpay.backend.web

import com.meowpay.backend.TestcontainersConfig
import com.meowpay.backend.domain.Cat
import com.meowpay.backend.domain.Wallet
import com.meowpay.backend.repository.CatRepository
import com.meowpay.backend.repository.TransferRepository
import com.meowpay.backend.repository.WalletRepository
import com.meowpay.backend.web.dto.CreateTransferRequest
import com.meowpay.backend.web.dto.ErrorResponse
import com.meowpay.backend.web.dto.TransferDto
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.resttestclient.TestRestTemplate
import org.springframework.boot.resttestclient.autoconfigure.AutoConfigureTestRestTemplate
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment
import org.springframework.context.annotation.Import
import org.springframework.http.HttpStatus
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue

@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(TestcontainersConfig::class)
class TransferApiTest {

    @Autowired
    lateinit var restTemplate: TestRestTemplate

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
    fun `creates a transfer and returns it`() {
        val sender = newCatWithBalance("Sender", 100)
        val recipient = newCatWithBalance("Recipient", 50)

        val response = restTemplate.postForEntity(
            "/api/transfers",
            CreateTransferRequest(sender, recipient, 20),
            TransferDto::class.java,
        )

        assertEquals(HttpStatus.CREATED, response.statusCode)
        val body = response.body!!
        assertEquals(sender, body.fromCatId)
        assertEquals(recipient, body.toCatId)
        assertEquals(20L, body.amountTreats)

        assertEquals(80L, walletRepository.findByCatId(sender)!!.balanceTreats)
        assertEquals(70L, walletRepository.findByCatId(recipient)!!.balanceTreats)
    }

    @Test
    fun `409s when the sender can't afford it`() {
        val sender = newCatWithBalance("Poor", 0)
        val recipient = newCatWithBalance("Recipient", 50)

        val response = restTemplate.postForEntity(
            "/api/transfers",
            CreateTransferRequest(sender, recipient, 1),
            ErrorResponse::class.java,
        )

        assertEquals(HttpStatus.CONFLICT, response.statusCode)
        assertEquals("INSUFFICIENT_TREATS", response.body!!.error)
    }

    @Test
    fun `400s for a self-transfer`() {
        val cat = newCatWithBalance("Solo", 50)

        val response = restTemplate.postForEntity(
            "/api/transfers",
            CreateTransferRequest(cat, cat, 5),
            ErrorResponse::class.java,
        )

        assertEquals(HttpStatus.BAD_REQUEST, response.statusCode)
        assertEquals("INVALID_TRANSFER", response.body!!.error)
    }

    @Test
    fun `404s when the recipient doesn't exist`() {
        val sender = newCatWithBalance("Sender", 50)
        val unknown = UUID.randomUUID()

        val response = restTemplate.postForEntity(
            "/api/transfers",
            CreateTransferRequest(sender, unknown, 5),
            ErrorResponse::class.java,
        )

        assertEquals(HttpStatus.NOT_FOUND, response.statusCode)
        assertEquals("NOT_FOUND", response.body!!.error)
    }

    @Test
    fun `lists transfer history filtered by cat`() {
        val sender = newCatWithBalance("Sender", 100)
        val recipient = newCatWithBalance("Recipient", 50)
        val saved = transferRepository.save(
            com.meowpay.backend.domain.Transfer(fromCatId = sender, toCatId = recipient, amountTreats = 10),
        )

        val response = restTemplate.getForEntity("/api/transfers?catId=$sender", Array<TransferDto>::class.java)

        assertEquals(HttpStatus.OK, response.statusCode)
        val match = response.body!!.find { it.id == saved.id }
        assertTrue(match != null, "expected created transfer to appear in filtered history")
        assertEquals(sender, match.fromCatId)
        assertEquals(recipient, match.toCatId)
        assertEquals(10L, match.amountTreats)
    }
}
