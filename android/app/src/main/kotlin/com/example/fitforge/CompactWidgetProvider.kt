package com.example.fitforge

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class CompactWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_compact).apply {
                val weekCount = widgetData.getInt("week_count", 0)
                val totalVolume = widgetData.getString("total_volume_pretty", "0 kg")

                setTextViewText(R.id.compact_streak_value, weekCount.toString())
                setTextViewText(R.id.compact_total_volume, "$totalVolume total")

                val launchIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("fitforge://start-workout")
                )
                setOnClickPendingIntent(R.id.compact_start_btn, launchIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
