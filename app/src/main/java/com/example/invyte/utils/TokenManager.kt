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

@Singleton
class TokenManager @Inject constructor(@ApplicationContext private val context: Context) {


    private val Context.dataStore: DataStore<Preferences> by preferencesDataStore("auth")

    companion object {
        private val TOKEN_KEY = stringPreferencesKey("token")
        private val USER_TYPE_KEY = stringPreferencesKey("user_type")
        private val USER_DATA_KEY = stringPreferencesKey("user_data") // store as JSON if needed
        private val USER_JSON_KEY = stringPreferencesKey("user_json")
    }

    suspend fun saveToken(token: String) {
        context.dataStore.edit { prefs ->
            prefs[TOKEN_KEY] = token
        }
    }


    suspend fun saveUserType(userType: String) {
        context.dataStore.edit { prefs ->
            prefs[USER_TYPE_KEY] = userType
        }
    }

    fun getToken(): Flow<String?> = context.dataStore.data.map { prefs ->
        prefs[TOKEN_KEY]
    }

    fun getUserType(): Flow<String?> = context.dataStore.data.map { prefs ->
        prefs[USER_TYPE_KEY]
    }


    suspend fun saveUser(user: User) {
        val json = Gson().toJson(user)
        context.dataStore.edit { prefs ->
            prefs[USER_JSON_KEY] = json
        }
    }

    fun getUser(): Flow<User?> = context.dataStore.data.map { prefs ->
        val json = prefs[USER_JSON_KEY] ?: return@map null
        try {
            Gson().fromJson(json, User::class.java)
        } catch (e: Exception) {
            null
        }
    }

    suspend fun clear() {
        context.dataStore.edit { prefs ->
            prefs.clear()
        }
    }
}