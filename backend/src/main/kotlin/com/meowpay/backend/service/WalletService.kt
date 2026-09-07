package com.meowpay.backend.service

import com.meowpay.backend.domain.Wallet
import com.meowpay.backend.repository.CatRepository
import com.meowpay.backend.repository.WalletRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.UUID

@Service
class WalletService(
    private val catRepository: CatRepository,
    private val walletRepository: WalletRepository,
) {
    @Transactional
    fun topUp(catId: UUID, amountTreats: Long): Wallet {
        if (amountTreats <= 0) {
            throw InvalidTransferException("Amount must be positive")
        }
        catRepository.findById(catId).orElseThrow { CatNotFoundException(catId) }
        val wallet = walletRepository.findByCatIdForUpdate(catId) ?: throw CatNotFoundException(catId)
        wallet.credit(amountTreats)
        return walletRepository.save(wallet)
    }
}
