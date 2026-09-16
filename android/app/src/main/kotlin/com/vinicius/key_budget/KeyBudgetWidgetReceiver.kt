package com.vinicius.key_budget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class KeyBudgetWidgetReceiver : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        val currentMonth = SimpleDateFormat("yyyy-MM", Locale.getDefault()).format(Date())

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            val userId = widgetData.getString("widget_user_id", "")
            val status = widgetData.getString("widget_status", "logged_out")
            val referenceMonth = widgetData.getString("widget_reference_month", "")
            val showValues = widgetData.getBoolean("widget_show_values", false)
            val monthlySpent = widgetData.getString("monthly_spent", "R$ •••••")

            val displayText = when {
                userId.isNullOrEmpty() || status == "logged_out" -> "Abra o KeyBudget"
                !referenceMonth.isNullOrEmpty() && referenceMonth != currentMonth -> "R$ •••••"
                !showValues -> "R$ •••••"
                else -> monthlySpent ?: "R$ 0,00"
            }

            views.setTextViewText(R.id.tv_monthly_spent, displayText)

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
