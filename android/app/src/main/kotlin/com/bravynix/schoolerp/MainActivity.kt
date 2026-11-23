package com.bravynix.schoolerp

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // The channel the server names for every push (SDD 18); Android 8 and later need it to exist before one shows.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(ALERTS_CHANNEL, getString(R.string.alerts_channel_name), NotificationManager.IMPORTANCE_HIGH),
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // While something sensitive is on screen (a whole Aadhaar number) the window is kept out of screenshots,
        // screen recordings and the app switcher preview.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.bravynix.schoolerp/screen")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "protect" -> {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    "release" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private companion object {
        const val ALERTS_CHANNEL = "alerts"
    }
}
