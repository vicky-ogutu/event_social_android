package com.example.invyte.data.repository


import android.util.Log
import com.example.invyte.data.model.AuthResponse
import com.example.invyte.data.model.LoginRequest
import com.example.invyte.data.model.RegisterRequest
import com.example.invyte.data.model.User
import com.example.invyte.data.network.ApiService
import com.example.invyte.utils.TokenManager
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton



/**
 * Repository for authentication-related operations.
 * Handles API calls and local storage via TokenManager.
 */
@Singleton
class AuthRepository @Inject constructor(
    private val api: ApiService,
    private val tokenManager: TokenManager
) {

    // -------- API Calls --------

    /**
     * Register a new user.
     */
    suspend fun register(request: RegisterRequest): AuthResponse {
        return api.register(request)
    }

    /**
     * Login an existing user.
     */
    suspend fun login(request: LoginRequest): AuthResponse {
        return api.login(request)
    }

    // -------- Save / Clear Auth Data --------

    /**
     * Save authentication data (token, user type, user object) to local storage.
     * Also saves the user ID separately for quick access.
     */
    suspend fun saveAuthData(token: String, userType: String, user: User) {
        tokenManager.saveToken(token)
        tokenManager.saveUserType(userType)
        tokenManager.saveUser(user) // This also saves the user ID internally
    }
    suspend fun saveUser( user: User) {
        tokenManager.saveUser(user) // This also saves the user ID internally
    }

    /**
     * Clear all authentication data from local storage.
     */
    suspend fun clear() {
        tokenManager.clear()
    }

    // -------- Flow-based Getters (for observing changes) --------

    /**
     * Get the current token as a Flow.
     */
    fun getToken(): Flow<String?> = tokenManager.getTokenFlow()

    /**
     * Get the current user type as a Flow.
     */
    fun getUserType(): Flow<String?> = tokenManager.getUserTypeFlow()

    /**
     * Get the current user object as a Flow.
     */
    fun getUser(): Flow<User?> = tokenManager.getUserFlow()

    /**
     * Get the current user ID as a Flow.
     */
    fun getUserId(): Flow<Int?> = tokenManager.getUserIdFlow()

    // -------- Synchronous Getters (for use in coroutines) --------

    /**
     * Get the current token synchronously (suspend).
     */
    suspend fun getTokenSync(): String? = tokenManager.getTokenSync()

    /**
     * Get the current user type synchronously (suspend).
     */
    suspend fun getUserTypeSync(): String? = tokenManager.getUserTypeSync()

    /**
     * Get the current user object synchronously (suspend).
     */
    suspend fun getUserSync(): User? = tokenManager.getUserSync()

    /**
     * Get the current user ID synchronously (suspend).
     */
    suspend fun getUserIdSync(): Int? = tokenManager.getUserIdSync()
}