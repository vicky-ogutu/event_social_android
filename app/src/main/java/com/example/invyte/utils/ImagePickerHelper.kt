package com.example.invyte.utils

import android.content.Context
import android.net.Uri
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import java.io.File

object ImagePickerHelper {
    fun createMultipartBody(context: Context, uri: Uri, fieldName: String = "cover_image"): MultipartBody.Part? {
        val file = File(uri.path ?: return null)
        val requestBody = file.asRequestBody("image/*".toMediaTypeOrNull())
        return MultipartBody.Part.createFormData(fieldName, file.name, requestBody)
    }
}