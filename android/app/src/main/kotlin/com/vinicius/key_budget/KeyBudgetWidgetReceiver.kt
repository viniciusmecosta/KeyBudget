package com.vinicius.key_budget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class KeyBudgetWidgetReceiver : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            val monthlySpent = widgetData.getString("monthly_spent", "R$ 0,00")
            views.setTextViewText(R.id.tv_monthly_spent, monthlySpent)

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