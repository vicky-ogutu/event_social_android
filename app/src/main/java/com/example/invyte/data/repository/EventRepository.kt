package com.example.invyte.data.repository

import com.example.invyte.data.model.*
import com.example.invyte.data.network.ApiService
import com.example.invyte.utils.safeApiCall
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class EventRepository @Inject constructor(
    private val api: ApiService
) {

    suspend fun createEvent(request: EventRequest): EventResponse {
        val response = api.createEvent(request)
        return if (response.isSuccessful) {
            response.body() ?: EventResponse(false, "Unknown error", null)
        } else {
            EventResponse(false, "Server error: ${response.code()}", null)
        }
    }

    suspend fun listEvents(
        eventType: String? = null,
        dateFrom: String? = null,
        dateTo: String? = null,
        search: String? = null,
        page: Int = 1,
        limit: Int = 20
    ): EventsResponse {
        val response = api.listEvents(eventType, dateFrom, dateTo, search, page, limit)
        return if (response.isSuccessful) {
            response.body() ?: EventsResponse(false, "Unknown error", null)
        } else {
            EventsResponse(false, "Server error: ${response.code()}", null)
        }
    }

//
//    suspend fun getMyEvents(): Result<List<Event>> =
//        safeApiCall { api.getMyEvents() }

//    suspend fun getMyEvents(page: Int = 1, limit: Int = 20): Result<EventListResponse> =
//        safeApiCall { api.getMyEvents(page, limit) }



//        suspend fun listEvents(): EventsResponse {
//        val response = api.listEvents()
//        return if (response.isSuccessful) {
//            response.body() ?: EventsResponse(false, "Unknown error", null)
//        } else {
//            EventsResponse(false, "Server error: ${response.code()}", null)
//        }
//    }


    suspend fun getEvent(id: Int): EventResponse {
        val response = api.getEvent(id)
        return if (response.isSuccessful) {
            response.body() ?: EventResponse(false, "Unknown error", null)
        } else {
            EventResponse(false, "Server error: ${response.code()}", null)
        }
    }

    suspend fun updateEvent(id: Int, request: EventRequest): EventResponse {
        val response = api.updateEvent(id, request)
        return if (response.isSuccessful) {
            response.body() ?: EventResponse(false, "Unknown error", null)
        } else {
            EventResponse(false, "Server error: ${response.code()}", null)
        }
    }

    suspend fun deleteEvent(id: Int): GenericResponse {
        val response = api.deleteEvent(id)
        return if (response.isSuccessful) {
            response.body() ?: GenericResponse(false, "Unknown error")
        } else {
            GenericResponse(false, "Server error: ${response.code()}")
        }
    }

    suspend fun joinEvent(id: Int, accessCode: String): GenericResponse {
        val response = api.joinEvent(id, JoinEventRequest(accessCode))
        return if (response.isSuccessful) {
            response.body() ?: GenericResponse(false, "Unknown error")
        } else {
            GenericResponse(false, "Server error: ${response.code()}")
        }
    }

//    suspend fun getMyEvents(page: Int = 1, limit: Int = 20): EventsResponse {
//        val response = api.getMyEvents(page, limit)
//        return (if (response.isSuccessful) {
//            response.body() ?: EventsResponse(false, "Unknown error", null)
//        } else {
//            EventsResponse(false, "Server error: ${response.code()}", null)
//        }) as EventsResponse
//    }

        suspend fun getMyEvents(page: Int = 1, limit: Int = 20): Result<EventListResponse> =
        safeApiCall { api.getMyEvents(page, limit) }


    suspend fun toggleLike(id: Int): LikeResponse {
        val response = api.toggleLike(id)
        return if (response.isSuccessful) {
            response.body() ?: LikeResponse(false, "Unknown error", null)
        } else {
            LikeResponse(false, "Server error: ${response.code()}", null)
        }
    }
}