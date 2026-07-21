package com.example.invyte.utils

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.dataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.example.invyte.data.model.User
import com.google.gson.Gson
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

import androidx.datastore.preferences.core.*
import kotlinx.coroutines.flow.first



private val Context.dataStore: DataStore<Preferences> by preferencesDataStore("auth")

@Singleton
class TokenManager @Inject constructor(
    @ApplicationContext private val context: Context
) {

    companion object {
        private val TOKEN_KEY = stringPreferencesKey("token")
        private val USER_TYPE_KEY = stringPreferencesKey("user_type")
        private val USER_ID_KEY = intPreferencesKey("user_id")
        private val USER_JSON_KEY = stringPreferencesKey("user_json")
    }

    // -------- Token --------
    suspend fun saveToken(token: String) {
        context.dataStore.edit { prefs ->
            prefs[TOKEN_KEY] = token
        }
    }

    fun getTokenFlow(): Flow<String?> = context.dataStore.data.map { prefs ->
        prefs[TOKEN_KEY]
    }

    suspend fun getTokenSync(): String? = getTokenFlow().first()

    // -------- User Type --------
    suspend fun saveUserType(userType: String) {
        context.dataStore.edit { prefs ->
            prefs[USER_TYPE_KEY] = userType
        }
    }

    fun getUserTypeFlow(): Flow<String?> = context.dataStore.data.map { prefs ->
        prefs[USER_TYPE_KEY]
    }

    suspend fun getUserTypeSync(): String? = getUserTypeFlow().first()

    // -------- User ID --------
    suspend fun saveUserId(userId: Int) {
        context.dataStore.edit { prefs ->
            prefs[USER_ID_KEY] = userId
        }
    }

    fun getUserIdFlow(): Flow<Int?> = context.dataStore.data.map { prefs ->
        prefs[USER_ID_KEY]
    }

    suspend fun getUserIdSync(): Int? = getUserIdFlow().first()

    // -------- Full User (JSON) --------
    suspend fun saveUser(user: User) {
        val json = Gson().toJson(user)
        context.dataStore.edit { prefs ->
            prefs[USER_JSON_KEY] = json
            // Also store the user ID separately for quick access
            prefs[USER_ID_KEY] = user.id
        }
    }

    fun getUserFlow(): Flow<User?> = context.dataStore.data.map { prefs ->
        val json = prefs[USER_JSON_KEY] ?: return@map null
        try {
            Gson().fromJson(json, User::class.java)
        } catch (e: Exception) {
            null
        }
    }

    suspend fun getUserSync(): User? = getUserFlow().first()

    // -------- Clear --------
    suspend fun clear() {
        context.dataStore.edit { prefs ->
            prefs.clear()
        }
    }
}