package com.meowpay.backend.repository

import com.meowpay.backend.domain.Transfer
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface TransferRepository : JpaRepository<Transfer, UUID>
