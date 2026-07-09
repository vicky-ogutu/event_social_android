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

@Singleton
class AuthRepository @Inject constructor(
    private val api: ApiService,
    private val tokenManager: TokenManager
) {

    suspend fun register(request: RegisterRequest): AuthResponse {
        return api.register(request)
    }

    suspend fun login(request: LoginRequest): AuthResponse {
        return api.login(request)
    }

//    suspend fun saveAuthData(token: String, userType: String) {
//        tokenManager.saveToken(token)
//        tokenManager.saveUserType(userType)
//        Log.d("AuthRepo", "Token saved: ${token.take(10)}...")
//    }

    fun getToken(): Flow<String?> = tokenManager.getToken()
    fun getUserType(): Flow<String?> = tokenManager.getUserType()

    suspend fun saveUser(user: User) {
        tokenManager.saveUser(user)
    }


    suspend fun clear() {
        tokenManager.clear()
    }

    suspend fun saveAuthData(token: String, userType: String, user: User) {
        tokenManager.saveToken(token)
        tokenManager.saveUserType(userType)
        tokenManager.saveUser(user)
    }

    fun getUser(): Flow<User?> = tokenManager.getUser()
}