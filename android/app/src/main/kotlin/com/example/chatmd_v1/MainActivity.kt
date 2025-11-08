package com.example.chatmd_v1

import android.content.ActivityNotFoundException
import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "com.example.chatmd_v1/health_connect"
    private val healthConnectPackage = "com.google.android.apps.healthdata"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openHealthConnect" -> {
                        val launchIntent = packageManager
                            ?.getLaunchIntentForPackage(healthConnectPackage)
                            ?.apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }

                        if (launchIntent == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }

                        try {
                            startActivity(launchIntent)
                            result.success(true)
                        } catch (e: ActivityNotFoundException) {
                            result.success(false)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
