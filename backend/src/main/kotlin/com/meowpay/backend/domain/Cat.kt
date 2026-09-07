package com.meowpay.backend.domain

import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.util.UUID

@Entity
@Table(name = "cats")
class Cat(
    @Id
    val id: UUID = UUID.randomUUID(),
    val name: String,
)
