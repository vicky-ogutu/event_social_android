package com.example.invyte.data.model
import com.google.gson.annotations.SerializedName

data class Event(
    val id: Int,
    val uuid: String,
    @SerializedName("organizer_id") val organizerId: Int,
    @SerializedName("event_name") val eventName: String,
    @SerializedName("event_description") val eventDescription: String?,
    @SerializedName("event_type") val eventType: String, // "public" or "private"
    @SerializedName("access_code") val accessCode: String?,
    @SerializedName("event_date") val eventDate: String,
    @SerializedName("start_time") val startTime: String,
    @SerializedName("end_time") val endTime: String?,
    @SerializedName("venue_address") val venueAddress: String?,
    val latitude: Double?,
    val longitude: Double?,
    @SerializedName("expected_attendees") val expectedAttendees: Int?,
    @SerializedName("cover_image") val coverImage: String?,
    val budget: Double?,
    @SerializedName("is_live") val isLive: Int? = 0,
    @SerializedName("view_count") val viewCount: Int?,
    @SerializedName("like_count") val likeCount: Int?,
    @SerializedName("organizer_name") val organizerName: String?,
    @SerializedName("organizer_pic") val organizerPic: String?,
    @SerializedName("created_at") val createdAt: String?,
    @SerializedName("updated_at") val updatedAt: String?
)

data class EventRequest(
    @SerializedName("event_name") val eventName: String,
    @SerializedName("event_description") val eventDescription: String? = null,
    @SerializedName("event_type") val eventType: String = "public", // "public" or "private"
    @SerializedName("access_code") val accessCode: String? = null,
    @SerializedName("event_date") val eventDate: String,
    @SerializedName("start_time") val startTime: String,
    @SerializedName("end_time") val endTime: String? = null,
    @SerializedName("venue_address") val venueAddress: String? = null,
    val latitude: Double? = null,
    val longitude: Double? = null,
    @SerializedName("expected_attendees") val expectedAttendees: Int? = null,
    @SerializedName("cover_image") val coverImage: String? = null,
    val budget: Double? = null
)

data class EventResponse(
    val success: Boolean,
    val message: String,
    val data: Event?
)

data class EventsResponse(
    val success: Boolean,
    val message: String,
    val data: EventListData?
)

data class EventListData(
    val data: List<Event>,
    val total: Int,
    val page: Int,
    val limit: Int,
    val pages: Int
)

data class JoinEventRequest(
    @SerializedName("access_code") val accessCode: String
)

data class LikeResponse(
    val success: Boolean,
    val message: String,
    val data: LikeData?
)

data class LikeData(
    val liked: Boolean
)