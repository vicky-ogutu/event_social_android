package com.example.invyte.data.model

data class EventListResponse(
    val data: List<Event>,
    val total: Int,
    val page: Int,
    val pages: Int,
    val limit: Int
)