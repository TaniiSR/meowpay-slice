package com.meowpay.backend.service

import com.meowpay.backend.domain.Transfer
import com.meowpay.backend.repository.CatRepository
import com.meowpay.backend.repository.TransferRepository
import com.meowpay.backend.repository.WalletRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.UUID

@Service
class TransferService(
    private val catRepository: CatRepository,
    private val walletRepository: WalletRepository,
    private val transferRepository: TransferRepository,
) {
    @Transactional
    fun transfer(fromCatId: UUID, toCatId: UUID, amountTreats: Long): Transfer {
        if (fromCatId == toCatId) {
            throw InvalidTransferException("A cat can't send treats to itself")
        }
        if (amountTreats <= 0) {
            throw InvalidTransferException("Amount must be positive")
        }

        val fromCat = catRepository.findById(fromCatId).orElseThrow { CatNotFoundException(fromCatId) }
        if (!catRepository.existsById(toCatId)) {
            throw CatNotFoundException(toCatId)
        }

        val (firstId, secondId) = if (fromCatId < toCatId) fromCatId to toCatId else toCatId to fromCatId
        val firstWallet = walletRepository.findByCatIdForUpdate(firstId)!!
        val secondWallet = walletRepository.findByCatIdForUpdate(secondId)!!

        val fromWallet = if (firstWallet.catId == fromCatId) firstWallet else secondWallet
        val toWallet = if (firstWallet.catId == toCatId) firstWallet else secondWallet

        if (fromWallet.balanceTreats < amountTreats) {
            throw InsufficientTreatsException(fromCat.id, fromCat.name)
        }

        fromWallet.debit(amountTreats)
        toWallet.credit(amountTreats)
        walletRepository.save(fromWallet)
        walletRepository.save(toWallet)

        return transferRepository.save(Transfer(fromCatId = fromCatId, toCatId = toCatId, amountTreats = amountTreats))
    }

    @Transactional(readOnly = true)
    fun history(catId: UUID?): List<Transfer> =
        if (catId == null) {
            transferRepository.findAllByOrderByCreatedAtDesc()
        } else {
            transferRepository.findAllByFromCatIdOrToCatIdOrderByCreatedAtDesc(catId, catId)
        }
}
