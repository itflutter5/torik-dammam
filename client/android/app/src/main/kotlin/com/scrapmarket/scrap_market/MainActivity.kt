package com.scrapmarket.scrap_market

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(NotificationChannel(
                "new_posts", "New marketplace posts", NotificationManager.IMPORTANCE_HIGH
            ).apply { description = "Notifications when new posts become available" })
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "com.torikdammam.marketplace/notifications").setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> result.success(null)
                "show" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && !manager.areNotificationsEnabled()) {
                        result.success(null)
                        return@setMethodCallHandler
                    }
                    val intent = Intent(this, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    }
                    val pendingIntent = PendingIntent.getActivity(this, 0, intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                    val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                        Notification.Builder(this, "new_posts") else Notification.Builder(this)
                    val body = call.argument<String>("body") ?: ""
                    val notification = builder.setSmallIcon(com.scrapmarket.scrap_market.R.drawable.ic_notification)
                        .setContentTitle(call.argument<String>("title"))
                        .setContentText(body)
                        .setStyle(Notification.BigTextStyle().bigText(body))
                        .setContentIntent(pendingIntent).setAutoCancel(true).build()
                    try {
                        manager.notify((call.argument<String>("id") ?: "new-post").hashCode(), notification)
                        result.success(null)
                    } catch (_: SecurityException) {
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
