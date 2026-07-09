package com.example.invyte.di

import com.example.invyte.data.repository.AuthRepository
import com.example.invyte.data.repository.EventRepository
import com.example.invyte.data.repository.ProfileRepository
import com.example.invyte.data.repository.VendorRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import jakarta.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {
//    @Binds
//    @Singleton
//    abstract fun bindAuthRepository(authRepository: AuthRepository): AuthRepository
//
//    @Binds
//    @Singleton
//    abstract fun bindProfileRepository(profileRepository: ProfileRepository): ProfileRepository
//
//    @Binds
//    @Singleton
//    abstract fun bindVendorRepository(vendorRepository: VendorRepository): VendorRepository

//    @Binds
//    @Singleton
//    abstract fun bindAuthRepository(authRepository: AuthRepository): AuthRepository
//
//    @Binds
//    @Singleton
//    abstract fun bindProfileRepository(profileRepository: ProfileRepository): ProfileRepository
//
//    @Binds
//    @Singleton
//    abstract fun bindVendorRepository(vendorRepository: VendorRepository): VendorRepository
//
//    @Binds
//    @Singleton
//    abstract fun bindEventRepository(eventRepository: EventRepository): EventRepository
}