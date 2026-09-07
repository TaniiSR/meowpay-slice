package com.meowpay.backend.web

import com.meowpay.backend.service.WalletService
import com.meowpay.backend.web.dto.CatDto
import com.meowpay.backend.web.dto.TopUpRequest
import jakarta.validation.Valid
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

@RestController
@RequestMapping("/api/cats")
class CatController(private val walletService: WalletService) {

    @GetMapping
    fun listCats(): List<CatDto> =
        walletService.listCats().map { (cat, wallet) -> CatDto(cat.id, cat.name, wallet.balanceTreats) }

    @GetMapping("/{id}")
    fun getCat(@PathVariable id: UUID): CatDto {
        val (cat, wallet) = walletService.getCat(id)
        return CatDto(cat.id, cat.name, wallet.balanceTreats)
    }

    @PostMapping("/{id}/topup")
    fun topUp(@PathVariable id: UUID, @Valid @RequestBody body: TopUpRequest): CatDto {
        walletService.topUp(id, body.amountTreats!!)
        val (cat, wallet) = walletService.getCat(id)
        return CatDto(cat.id, cat.name, wallet.balanceTreats)
    }
}
