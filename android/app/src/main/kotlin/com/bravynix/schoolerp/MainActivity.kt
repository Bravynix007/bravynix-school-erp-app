package com.bravynix.schoolerp

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
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
}
