package com.vinicius.key_budget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class KeyBudgetWidgetReceiver : HomeWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_REVEAL_VALUE -> {
                val widgetId = intent.getIntExtra(
                    AppWidgetManager.EXTRA_APPWIDGET_ID,
                    AppWidgetManager.INVALID_APPWIDGET_ID,
                )
                if (widgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                    val widgetData = HomeWidgetPlugin.getData(context)
                    widgetData.edit()
                        .putLong(revealUntilKey(widgetId), System.currentTimeMillis() + revealDurationMillis)
                        .apply()
                    updateWidget(context, widgetId, widgetData)
                    scheduleMask(context, widgetId)
                }
                return
            }
            ACTION_MASK_VALUE -> {
                val widgetId = intent.getIntExtra(
                    AppWidgetManager.EXTRA_APPWIDGET_ID,
                    AppWidgetManager.INVALID_APPWIDGET_ID,
                )
                if (widgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                    val widgetData = HomeWidgetPlugin.getData(context)
                    widgetData.edit().remove(revealUntilKey(widgetId)).apply()
                    cancelScheduledMask(context, widgetId)
                    updateWidget(context, widgetId, widgetData)
                }
                return
            }
        }
        super.onReceive(context, intent)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            renderWidget(context, appWidgetManager, widgetId, widgetData)
        }
    }

    private fun updateWidget(
        context: Context,
        widgetId: Int,
        widgetData: SharedPreferences,
    ) {
        renderWidget(
            context,
            AppWidgetManager.getInstance(context),
            widgetId,
            widgetData,
        )
    }

    private fun renderWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences,
    ) {
        val currentMonth = SimpleDateFormat("yyyy-MM", Locale.getDefault()).format(Date())
        val views = RemoteViews(context.packageName, R.layout.widget_layout)

        val userId = widgetData.getString("widget_user_id", "")
        val status = widgetData.getString("widget_status", "logged_out")
        val referenceMonth = widgetData.getString("widget_reference_month", "")
        val monthlySpent = widgetData.getString("monthly_spent", "R$ 0,00") ?: "R$ 0,00"
        val revealUntil = widgetData.getLong(revealUntilKey(widgetId), 0L)
        val isTemporarilyVisible = revealUntil > System.currentTimeMillis()

        val displayText = when {
            userId.isNullOrEmpty() || status == "logged_out" -> "Abra o KeyBudget"
            !referenceMonth.isNullOrEmpty() && referenceMonth != currentMonth -> "R$ •••••"
            isTemporarilyVisible -> monthlySpent
            else -> "R$ •••••"
        }

        views.setTextViewText(R.id.tv_monthly_spent, displayText)
        views.setOnClickPendingIntent(
            R.id.btn_toggle_visibility,
            visibilityPendingIntent(
                context,
                widgetId,
                if (isTemporarilyVisible) ACTION_MASK_VALUE else ACTION_REVEAL_VALUE,
            ),
        )
        views.setImageViewResource(
            R.id.btn_toggle_visibility,
            if (isTemporarilyVisible) R.drawable.ic_visibility_off
            else R.drawable.ic_visibility,
        )

        val addExpenseIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("keybudget://addexpense"),
        )
        views.setOnClickPendingIntent(R.id.btn_add_expense, addExpenseIntent)

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun scheduleMask(context: Context, widgetId: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val maskIntent = visibilityPendingIntent(context, widgetId, ACTION_MASK_VALUE)
        alarmManager.cancel(maskIntent)
        val triggerAt = System.currentTimeMillis() + revealDurationMillis
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            alarmManager.canScheduleExactAlarms()) {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, maskIntent)
        } else {
            alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAt, maskIntent)
        }
    }

    private fun cancelScheduledMask(context: Context, widgetId: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(visibilityPendingIntent(context, widgetId, ACTION_MASK_VALUE))
    }

    private fun visibilityPendingIntent(
        context: Context,
        widgetId: Int,
        action: String,
    ): PendingIntent {
        val intent = Intent(context, KeyBudgetWidgetReceiver::class.java).apply {
            this.action = action
            data = Uri.parse("keybudget://widget/$action/$widgetId")
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        }
        return PendingIntent.getBroadcast(
            context,
            widgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    companion object {
        private const val ACTION_REVEAL_VALUE =
            "com.vinicius.key_budget.action.REVEAL_WIDGET_VALUE"
        private const val ACTION_MASK_VALUE =
            "com.vinicius.key_budget.action.MASK_WIDGET_VALUE"
        private const val revealDurationMillis = 3_000L

        private fun revealUntilKey(widgetId: Int) = "widget_reveal_until_$widgetId"
    }
}
