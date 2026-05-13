package com.example.fitforge

import android.appwidget.AppWidgetManager
import android.content.Context
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class LargeWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_large).apply {
                val date = widgetData.getString("today_label", "")
                val week = widgetData.getInt("week_count", 0)
                val total = widgetData.getInt("total_count", 0)
                val volume = widgetData.getString("total_volume_pretty", "0")

                val recent1 = widgetData.getString("recent_1", "")
                val recent2 = widgetData.getString("recent_2", "")
                val recent3 = widgetData.getString("recent_3", "")

                setTextViewText(R.id.large_date, date)
                setTextViewText(R.id.large_week_count, week.toString())
                setTextViewText(R.id.large_total_count, total.toString())
                setTextViewText(R.id.large_total_volume, volume)

                val items = listOf(recent1, recent2, recent3)
                val anyItem = items.any { !it.isNullOrEmpty() }
                setViewVisibility(R.id.large_empty, if (anyItem) View.GONE else View.VISIBLE)

                setTextViewText(R.id.large_recent_1, recent1 ?: "")
                setTextViewText(R.id.large_recent_2, recent2 ?: "")
                setTextViewText(R.id.large_recent_3, recent3 ?: "")
                setViewVisibility(R.id.large_recent_1, if (recent1.isNullOrEmpty()) View.GONE else View.VISIBLE)
                setViewVisibility(R.id.large_recent_2, if (recent2.isNullOrEmpty()) View.GONE else View.VISIBLE)
                setViewVisibility(R.id.large_recent_3, if (recent3.isNullOrEmpty()) View.GONE else View.VISIBLE)

                val startIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("fitforge://start-workout")
                )
                setOnClickPendingIntent(R.id.large_start_btn, startIntent)

                val historyIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("fitforge://history")
                )
                setOnClickPendingIntent(R.id.large_history_btn, historyIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
