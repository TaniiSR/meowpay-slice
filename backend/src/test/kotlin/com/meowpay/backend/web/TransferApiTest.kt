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
import org.springframework.http.HttpEntity
import org.springframework.http.HttpHeaders
import org.springframework.http.HttpMethod
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
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

    @Test
    fun `400s with the API's error shape for malformed JSON`() {
        val entity = HttpEntity(
            "{not valid json",
            HttpHeaders().apply { contentType = MediaType.APPLICATION_JSON },
        )

        val response = restTemplate.exchange("/api/transfers", HttpMethod.POST, entity, ErrorResponse::class.java)

        assertEquals(HttpStatus.BAD_REQUEST, response.statusCode)
        assertEquals("MALFORMED_REQUEST", response.body!!.error)
    }

    @Test
    fun `400s when the amount exceeds the maximum allowed treats`() {
        val sender = newCatWithBalance("Sender", 100)
        val recipient = newCatWithBalance("Recipient", 50)

        val response = restTemplate.postForEntity(
            "/api/transfers",
            CreateTransferRequest(sender, recipient, Long.MAX_VALUE),
            ErrorResponse::class.java,
        )

        assertEquals(HttpStatus.BAD_REQUEST, response.statusCode)
        assertEquals("VALIDATION_ERROR", response.body!!.error)
    }

    @Test
    fun `400s when a transfer would push the recipient's balance past the maximum allowed treats`() {
        val sender = newCatWithBalance("Sender", com.meowpay.backend.domain.Wallet.MAX_TREATS)
        val recipient = newCatWithBalance("Recipient", 1)

        val response = restTemplate.postForEntity(
            "/api/transfers",
            CreateTransferRequest(sender, recipient, com.meowpay.backend.domain.Wallet.MAX_TREATS),
            ErrorResponse::class.java,
        )

        assertEquals(HttpStatus.BAD_REQUEST, response.statusCode)
        assertEquals("INVALID_TRANSFER", response.body!!.error)
        assertEquals(com.meowpay.backend.domain.Wallet.MAX_TREATS, walletRepository.findByCatId(sender)!!.balanceTreats)
        assertEquals(1L, walletRepository.findByCatId(recipient)!!.balanceTreats)
    }

    @Test
    fun `paginates history when page and size are both provided`() {
        val sender = newCatWithBalance("Sender", 1000)
        val recipient = newCatWithBalance("Recipient", 0)
        repeat(5) {
            transferRepository.save(
                com.meowpay.backend.domain.Transfer(fromCatId = sender, toCatId = recipient, amountTreats = 1),
            )
        }

        val response = restTemplate.getForEntity("/api/transfers?catId=$sender&page=0&size=2", Array<TransferDto>::class.java)

        assertEquals(HttpStatus.OK, response.statusCode)
        assertEquals(2, response.body!!.size)
        assertEquals("5", response.headers.getFirst("X-Total-Count"))
    }
}
