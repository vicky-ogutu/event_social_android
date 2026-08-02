package com.example.invyte.data.network

import com.example.invyte.data.model.AuthResponse
import com.example.invyte.data.model.Booking
import com.example.invyte.data.model.ChangePasswordRequest
import com.example.invyte.data.model.ChatMessage
import com.example.invyte.data.model.Comment
import com.example.invyte.data.model.Conversation
import com.example.invyte.data.model.CreateBookingRequest
import com.example.invyte.data.model.CreateCommentRequest
import com.example.invyte.data.model.CreateLivestreamRequest
import com.example.invyte.data.model.CreatePaymentIntentRequest
import com.example.invyte.data.model.CreatePostRequest
import com.example.invyte.data.model.Event
import com.example.invyte.data.model.EventListResponse
import com.example.invyte.data.model.EventRequest
import com.example.invyte.data.model.EventResponse
import com.example.invyte.data.model.EventsResponse
import com.example.invyte.data.model.GenericResponse
import com.example.invyte.data.model.JoinEventRequest
import com.example.invyte.data.model.LikeResponse
import com.example.invyte.data.model.Livestream
import com.example.invyte.data.model.LivestreamAccessResponse
import com.example.invyte.data.model.LivestreamPurchaseRequest
import com.example.invyte.data.model.LoginRequest
import com.example.invyte.data.model.Message
import com.example.invyte.data.model.PaymentIntentResponse
import com.example.invyte.data.model.PortfolioResponse
import com.example.invyte.data.model.RegisterRequest
import com.example.invyte.data.model.SendChatMessageRequest
import com.example.invyte.data.model.Service
import com.example.invyte.data.model.ServiceRequest
import com.example.invyte.data.model.ServiceResponse
import com.example.invyte.data.model.ServicesResponse
import com.example.invyte.data.model.SocialPost
import com.example.invyte.data.model.UpdateProfileRequest
import com.example.invyte.data.model.Vendor
import com.example.invyte.data.model.VendorListResponse
import com.example.invyte.data.model.VendorProfileRequest
import com.example.invyte.data.model.VendorProfileResponse
import okhttp3.MultipartBody
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.GET
import retrofit2.http.Multipart
import retrofit2.http.POST
import retrofit2.http.PUT
import retrofit2.http.Part
import retrofit2.http.Path
import retrofit2.http.Query

interface ApiService {
    @POST("api/auth/register")
    suspend fun register(@Body request: RegisterRequest): AuthResponse

    @POST("api/auth/login")
    suspend fun login(@Body request: LoginRequest): AuthResponse

    // ---- User Profile ----
    @PUT("api/users/profile")
    suspend fun updateProfile(
        @Body request: UpdateProfileRequest
    ): Response<AuthResponse> // reuse AuthResponse, or create a generic one

    @PUT("api/users/password")
    suspend fun changePassword(
        @Body request: ChangePasswordRequest
    ): Response<AuthResponse>

    @Multipart
    @POST("api/users/upload-avatar")
    suspend fun uploadAvatar(
        @Part file: MultipartBody.Part
    ): Response<AuthResponse> // returns updated user

    // ---- Vendor Profile ----
    @POST("api/vendors/profile")
    suspend fun createVendorProfile(
        @Body request: VendorProfileRequest
    ): Response<VendorProfileResponse>

    @GET("api/vendors/profile")
    suspend fun getVendorProfile(): Response<VendorProfileResponse>

    @PUT("api/vendors/profile")
    suspend fun updateVendorProfile(
        @Body request: VendorProfileRequest
    ): Response<VendorProfileResponse>

    // ---- Vendor Services ----
    @POST("api/vendors/services")
    suspend fun createService(
        @Body request: ServiceRequest
    ): Response<ServiceResponse>

    @GET("api/vendors/services")
    suspend fun getServices(): Response<ServicesResponse>

    @PUT("api/vendors/services/{id}")
    suspend fun updateService(
        @Path("id") serviceId: Int,
        @Body request: ServiceRequest
    ): Response<ServiceResponse>

    @DELETE("api/vendors/services/{id}")
    suspend fun deleteService(
        @Path("id") serviceId: Int
    ): Response<com.example.invyte.data.model.GenericResponse> // we'll define

    // ---- Vendor Portfolio ----
    @Multipart
    @POST("api/vendors/portfolio")
    suspend fun uploadPortfolio(
        @Part file: MultipartBody.Part,
        @Part("caption") caption: String?
    ): Response<PortfolioResponse> // or single item

    @GET("api/vendors/portfolio")
    suspend fun getPortfolio(): Response<PortfolioResponse>

    // ---- Events ----
    @POST("api/events")
    suspend fun createEvent(@Body request: EventRequest): Response<EventResponse>

    @GET("api/events")
    suspend fun listEvents(
        @Query("event_type") eventType: String? = null,
        @Query("date_from") dateFrom: String? = null,
        @Query("date_to") dateTo: String? = null,
        @Query("search") search: String? = null,
        @Query("page") page: Int = 1,
        @Query("limit") limit: Int = 20
    ): Response<EventsResponse>

//    @GET("api/events")
//    suspend fun listEvents(): Response<EventsResponse>

    @GET("api/events/{id}")
    suspend fun getEvent(@Path("id") id: Int): Response<EventResponse>

    @PUT("api/events/{id}")
    suspend fun updateEvent(
        @Path("id") id: Int,
        @Body request: EventRequest
    ): Response<EventResponse>

    @DELETE("api/events/{id}")
    suspend fun deleteEvent(@Path("id") id: Int): Response<GenericResponse>

    @POST("api/events/{id}/join")
    suspend fun joinEvent(
        @Path("id") id: Int,
        @Body request: JoinEventRequest
    ): Response<GenericResponse>

//    @GET("api/events/my-events")
//    suspend fun getMyEvents(
//        @Query("page") page: Int = 1,
//        @Query("limit") limit: Int = 20
//    ): Response<ApiResponse<List<Event>>>




    @GET("api/events/my-events")
    suspend fun getMyEvents(
        @Query("page") page: Int = 1,
        @Query("limit") limit: Int = 20
    ): Response<ApiResponse<EventListResponse>>



    @POST("api/events/{id}/like")
    suspend fun toggleLike(@Path("id") id: Int): Response<LikeResponse>







    // -------- Vendors (discovery) --------
    @GET("api/vendors")
    suspend fun listVendors(
        @Query("category") category: String? = null,
        @Query("min_rating") minRating: Double? = null,
        @Query("search") search: String? = null,
        @Query("page") page: Int = 1,
        @Query("limit") limit: Int = 20
    ): Response<ApiResponse<VendorListResponse>>

    @GET("api/vendors/{id}")
    suspend fun getVendorDetails(@Path("id") id: Int): Response<ApiResponse<Vendor>>

    @GET("api/vendors/{id}/services")
    suspend fun getVendorServices(@Path("id") id: Int): Response<ApiResponse<List<Service>>>

    // -------- Bookings --------
    @POST("api/bookings")
    suspend fun createBooking(@Body request: CreateBookingRequest): Response<ApiResponse<Booking>>

    @GET("api/bookings/my-bookings")
    suspend fun getMyBookings(
        @Query("page") page: Int = 1,
        @Query("limit") limit: Int = 20
    ): Response<ApiResponse<List<Booking>>>

    @GET("api/bookings/{id}")
    suspend fun getBookingDetails(@Path("id") id: Int): Response<ApiResponse<Booking>>

    @POST("api/bookings/{id}/confirm-service")
    suspend fun confirmService(@Path("id") id: Int): Response<ApiResponse<Unit>>

    @POST("api/bookings/{id}/complete")
    suspend fun completeBooking(@Path("id") id: Int): Response<ApiResponse<Unit>>

    // -------- Payments --------
    @POST("api/payments/create-intent")
    suspend fun createPaymentIntent(
        @Body request: CreatePaymentIntentRequest
    ): Response<ApiResponse<PaymentIntentResponse>>

    // -------- Social --------
    @POST("api/social/posts")
    suspend fun createPost(@Body request: CreatePostRequest): Response<ApiResponse<SocialPost>>

    @GET("api/bookings/vendor")
    suspend fun getVendorBookings(): Response<ApiResponse<List<Booking>>>

    @POST("api/bookings/{id}/reject")
    suspend fun rejectBooking(@Path("id") id: Int): Response<ApiResponse<Unit>>

    @GET("api/social/feed")
    suspend fun getSocialFeed(
        @Query("event_id") eventId: Int? = null,
        @Query("page") page: Int = 1,
        @Query("limit") limit: Int = 20
    ): Response<ApiResponse<List<SocialPost>>>

    @POST("api/social/posts/{id}/like")
    suspend fun togglePostLike(@Path("id") id: Int): Response<ApiResponse<Unit>>

    @POST("api/social/posts/{id}/comment")
    suspend fun addComment(@Path("id") id: Int, @Body request: CreateCommentRequest): Response<ApiResponse<Comment>>

    @GET("api/social/posts/{id}/comments")
    suspend fun getPostComments(@Path("id") id: Int): Response<ApiResponse<List<Comment>>>

    @GET("api/social/events/{eventId}/chat")
    suspend fun getChatMessages(
        @Path("eventId") eventId: Int,
        @Query("page") page: Int = 1,
        @Query("limit") limit: Int = 50
    ): Response<ApiResponse<List<ChatMessage>>>

    @POST("api/social/chat")
    suspend fun sendChatMessage(@Body request: SendChatMessageRequest): Response<ApiResponse<ChatMessage>>
    // -------- Livestream --------
    @POST("api/livestream")
    suspend fun createLivestream(@Body request: CreateLivestreamRequest): Response<ApiResponse<Livestream>>

    @POST("api/livestream/{id}/start")
    suspend fun startLivestream(@Path("id") id: Int): Response<ApiResponse<Unit>>

    @POST("api/livestream/{id}/end")
    suspend fun endLivestream(@Path("id") id: Int): Response<ApiResponse<Unit>>

    @GET("api/livestream/{id}")
    suspend fun getLivestream(@Path("id") id: Int): Response<ApiResponse<Livestream>>

    @POST("api/livestream/{id}/purchase")
    suspend fun purchaseLivestream(@Path("id") id: Int): Response<ApiResponse<PaymentIntentResponse>>

    @POST("api/livestream/confirm-purchase")
    suspend fun confirmLivestreamPurchase(@Body request: LivestreamPurchaseRequest): Response<ApiResponse<LivestreamAccessResponse>>

    @POST("api/messages")
    suspend fun sendMessage(@Body request: SendMessageRequest): Response<ApiResponse<Message>>

    @GET("api/messages/conversations")
    suspend fun getConversations(): Response<ApiResponse<List<Conversation>>>

    @GET("api/messages/{userId}")
    suspend fun getConversation(
        @Path("userId") userId: Int,
        @Query("limit") limit: Int = 50,
        @Query("offset") offset: Int = 0
    ): Response<ApiResponse<List<Message>>>

    data class SendMessageRequest(
        val receiver_id: Int,
        val message: String
    )
}



