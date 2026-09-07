package com.meowpay.backend.repository

import com.meowpay.backend.domain.Cat
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface CatRepository : JpaRepository<Cat, UUID>
