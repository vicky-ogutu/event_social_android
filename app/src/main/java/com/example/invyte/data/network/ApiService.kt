package com.example.invyte.data.network

import com.example.invyte.data.model.AuthResponse
import com.example.invyte.data.model.ChangePasswordRequest
import com.example.invyte.data.model.EventRequest
import com.example.invyte.data.model.EventResponse
import com.example.invyte.data.model.EventsResponse
import com.example.invyte.data.model.GenericResponse
import com.example.invyte.data.model.JoinEventRequest
import com.example.invyte.data.model.LikeResponse
import com.example.invyte.data.model.LoginRequest
import com.example.invyte.data.model.PortfolioResponse
import com.example.invyte.data.model.RegisterRequest
import com.example.invyte.data.model.ServiceRequest
import com.example.invyte.data.model.ServiceResponse
import com.example.invyte.data.model.ServicesResponse
import com.example.invyte.data.model.UpdateProfileRequest
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

    @GET("api/events/my-events")
    suspend fun getMyEvents(
        @Query("page") page: Int = 1,
        @Query("limit") limit: Int = 20
    ): Response<EventsResponse>

    @POST("api/events/{id}/like")
    suspend fun toggleLike(@Path("id") id: Int): Response<LikeResponse>
}