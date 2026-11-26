package com.endurain.endurain.wear

import android.app.Application

class EndurainWearApplication : Application() {
    lateinit var phoneLink: PhoneLink
        private set

    lateinit var recorder: WorkoutRecorder
        private set

    override fun onCreate() {
        super.onCreate()
        ExerciseService.createNotificationChannel(this)
        phoneLink = PhoneLink(this)
        recorder = WorkoutRecorder(this, phoneLink)
        phoneLink.republishPending()
        recorder.restoreUnfinishedRecording()
    }
}
