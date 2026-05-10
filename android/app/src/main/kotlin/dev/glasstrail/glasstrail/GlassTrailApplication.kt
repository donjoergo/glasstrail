package dev.glasstrail.glasstrail

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

class GlassTrailApplication : Application() {
  override fun onCreate() {
    super.onCreate()
    createNotificationChannel()
  }

  private fun createNotificationChannel() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
      return
    }

    val notificationManager = getSystemService(NotificationManager::class.java)
      ?: return
    val channelId = getString(R.string.default_notification_channel_id)
    val channel = NotificationChannel(
      channelId,
      getString(R.string.default_notification_channel_name),
      NotificationManager.IMPORTANCE_HIGH,
    ).apply {
      description = getString(R.string.default_notification_channel_description)
    }
    notificationManager.createNotificationChannel(channel)
  }
}
