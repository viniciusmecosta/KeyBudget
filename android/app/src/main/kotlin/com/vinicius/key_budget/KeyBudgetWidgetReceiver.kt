package com.vinicius.key_budget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class KeyBudgetWidgetReceiver : HomeWidgetProvider() {

    companion object {
        const val ACTION_TOGGLE_VISIBILITY = "com.vinicius.key_budget.TOGGLE_VISIBILITY"
        const val ACTION_HIDE_VALUE = "com.vinicius.key_budget.HIDE_VALUE"
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action == ACTION_TOGGLE_VISIBILITY) {
            updateVisibility(context, true)

            val hideIntent = Intent(context, KeyBudgetWidgetReceiver::class.java).apply {
                action = ACTION_HIDE_VALUE
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, 0, hideIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.setExact(
                AlarmManager.RTC,
                System.currentTimeMillis() + 10000,
                pendingIntent
            )
        } else if (intent.action == ACTION_HIDE_VALUE) {
            updateVisibility(context, false)
        }
    }

    private fun updateVisibility(context: Context, isVisible: Boolean) {
        val prefs = context.getSharedPreferences("widget_prefs", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("is_visible", isVisible).apply()

        val appWidgetManager = AppWidgetManager.getInstance(context)
        val componentName = ComponentName(context, KeyBudgetWidgetReceiver::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

        val flutterPrefs =
            context.getSharedPreferences("group.com.vinicius.keybudget", Context.MODE_PRIVATE)

        onUpdate(context, appWidgetManager, appWidgetIds, flutterPrefs)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        val localPrefs = context.getSharedPreferences("widget_prefs", Context.MODE_PRIVATE)
        val isVisible = localPrefs.getBoolean("is_visible", false)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            val monthlySpent = widgetData.getString("monthly_spent", "R$ 0,00")

            if (isVisible) {
                views.setTextViewText(R.id.tv_monthly_spent, monthlySpent)
                views.setImageViewResource(R.id.iv_visibility, R.drawable.ic_visibility_off)
            } else {
                views.setTextViewText(R.id.tv_monthly_spent, "R$ •••••")
                views.setImageViewResource(R.id.iv_visibility, R.drawable.ic_visibility)
            }

            val toggleIntent = Intent(context, KeyBudgetWidgetReceiver::class.java).apply {
                action = ACTION_TOGGLE_VISIBILITY
            }
            val togglePendingIntent = PendingIntent.getBroadcast(
                context, 1, toggleIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.iv_visibility, togglePendingIntent)

            val pendingIntentWithData = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("keybudget://addexpense")
            )
            views.setOnClickPendingIntent(R.id.btn_add_expense, pendingIntentWithData)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}