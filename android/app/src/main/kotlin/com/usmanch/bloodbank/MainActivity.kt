package com.usmanch.bloodbank

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel("blood_requests", "Blood requests", NotificationManager.IMPORTANCE_HIGH)
            channel.description = "Donation requests and account notifications"
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }
}
