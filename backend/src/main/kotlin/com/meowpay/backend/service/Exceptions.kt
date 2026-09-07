package com.meowpay.backend.service

import java.util.UUID

class CatNotFoundException(val catId: UUID) : RuntimeException("Cat $catId not found")

class InsufficientTreatsException(val catId: UUID, val catName: String) :
    RuntimeException("$catName doesn't have enough treats")

class InvalidTransferException(message: String) : RuntimeException(message)
