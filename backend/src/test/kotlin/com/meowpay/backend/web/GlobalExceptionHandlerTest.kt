package com.meowpay.backend.web

import org.junit.jupiter.api.Test
import org.springframework.dao.DataIntegrityViolationException
import org.springframework.http.HttpStatus
import kotlin.test.assertEquals

class GlobalExceptionHandlerTest {

    private val handler = GlobalExceptionHandler()

    @Test
    fun `maps DataIntegrityViolationException to 409 in the API's error shape`() {
        val response = handler.handleDataIntegrityViolation(DataIntegrityViolationException("boom"))

        assertEquals(HttpStatus.CONFLICT, response.statusCode)
        assertEquals("DATA_INTEGRITY_VIOLATION", response.body!!.error)
    }

    @Test
    fun `maps an unexpected exception to a generic 500 in the API's error shape`() {
        val response = handler.handleUnexpected(RuntimeException("boom"))

        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.statusCode)
        assertEquals("INTERNAL_ERROR", response.body!!.error)
    }
}
