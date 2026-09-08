package com.meowpay.backend.web

import com.meowpay.backend.TestcontainersConfig
import com.meowpay.backend.domain.Cat
import com.meowpay.backend.domain.Wallet
import com.meowpay.backend.repository.CatRepository
import com.meowpay.backend.repository.WalletRepository
import com.meowpay.backend.web.dto.CatDto
import com.meowpay.backend.web.dto.ErrorResponse
import com.meowpay.backend.web.dto.TopUpRequest
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
class CatApiTest {

    @Autowired
    lateinit var restTemplate: TestRestTemplate

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
    fun `gets a single cat by id with its balance`() {
        val catId = newCatWithBalance("Fetchme", 42)

        val response = restTemplate.getForEntity("/api/cats/$catId", CatDto::class.java)

        assertEquals(HttpStatus.OK, response.statusCode)
        val body = response.body!!
        assertEquals(catId, body.id)
        assertEquals("Fetchme", body.name)
        assertEquals(42L, body.balanceTreats)
    }

    @Test
    fun `404s for an unknown cat id`() {
        val unknown = UUID.randomUUID()

        val response = restTemplate.getForEntity("/api/cats/$unknown", ErrorResponse::class.java)

        assertEquals(HttpStatus.NOT_FOUND, response.statusCode)
        assertEquals("NOT_FOUND", response.body!!.error)
    }

    @Test
    fun `lists cats including one just inserted`() {
        val catId = newCatWithBalance("Listable Cat ${UUID.randomUUID()}", 17)
        val cat = catRepository.findById(catId).orElseThrow()

        val response = restTemplate.getForEntity("/api/cats", Array<CatDto>::class.java)

        assertEquals(HttpStatus.OK, response.statusCode)
        val match = response.body!!.find { it.id == catId }
        assertTrue(match != null, "expected inserted cat to appear in listing")
        assertEquals(cat.name, match.name)
        assertEquals(17L, match.balanceTreats)
    }

    @Test
    fun `tops up a cat's balance`() {
        val catId = newCatWithBalance("Topper", 10)

        val response = restTemplate.postForEntity("/api/cats/$catId/topup", TopUpRequest(5), CatDto::class.java)

        assertEquals(HttpStatus.OK, response.statusCode)
        assertEquals(15L, response.body!!.balanceTreats)
        assertEquals(15L, walletRepository.findByCatId(catId)!!.balanceTreats)
    }

    @Test
    fun `rejects a non-positive topup amount`() {
        val catId = newCatWithBalance("Topper", 10)

        val response = restTemplate.postForEntity("/api/cats/$catId/topup", TopUpRequest(0), ErrorResponse::class.java)

        assertEquals(HttpStatus.BAD_REQUEST, response.statusCode)
        assertEquals("VALIDATION_ERROR", response.body!!.error)
    }

    @Test
    fun `rejects a topup amount exceeding the maximum allowed treats`() {
        val catId = newCatWithBalance("Topper", 10)

        val response = restTemplate.postForEntity(
            "/api/cats/$catId/topup",
            TopUpRequest(Long.MAX_VALUE),
            ErrorResponse::class.java,
        )

        assertEquals(HttpStatus.BAD_REQUEST, response.statusCode)
        assertEquals("VALIDATION_ERROR", response.body!!.error)
    }
}
