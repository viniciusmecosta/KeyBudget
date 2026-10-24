package com.vinicius.key_budget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import org.json.JSONObject

open class KeyBudgetWidgetReceiver : HomeWidgetProvider() {

    protected open val kind = "monthly"

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        id: Int,
        options: Bundle,
    ) {
        updateWidget(context, id, HomeWidgetPlugin.getData(context))
    }

    override fun onDeleted(context: Context, ids: IntArray) {
        val preferences = HomeWidgetPlugin.getData(context).edit()
        ids.forEach { id ->
            cancelScheduledMask(context, id)
            preferences.remove(revealUntilKey(id))
        }
        preferences.apply()
        super.onDeleted(context, ids)
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            AppWidgetManager.ACTION_APPWIDGET_UPDATE -> {
                // AppWidgetProvider skips onUpdate for an empty ID list. Still
                // publish the chosen theme before the user adds their first widget.
                val ids = intent.getIntArrayExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS)
                if (ids == null || ids.isEmpty()) {
                    publishPreview(context, AppWidgetManager.getInstance(context), HomeWidgetPlugin.getData(context))
                }
            }
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
        publishPreview(context, appWidgetManager, widgetData)
    }

    private fun publishPreview(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetData: SharedPreferences,
    ) {
        if (Build.VERSION.SDK_INT >= 35) {
            val appearance = widgetData.getString("widget_appearance", "") ?: ""
            val previewKey = "widget_preview_appearance_$kind"
            if (widgetData.getString(previewKey, null) != appearance) {
                val preview = createViews(context, AppWidgetManager.INVALID_APPWIDGET_ID,
                    widgetData, 200, System.currentTimeMillis())
                try {
                    if (appWidgetManager.setWidgetPreview(ComponentName(context, javaClass),
                            android.appwidget.AppWidgetProviderInfo.WIDGET_CATEGORY_HOME_SCREEN, preview)) {
                        widgetData.edit().putString(previewKey, appearance).apply()
                    }
                } catch (error: RuntimeException) {
                    // A launcher preview must never prevent installed widgets from updating.
                    Log.w("KeyBudgetWidget", "Widget preview unavailable: ${error.javaClass.simpleName}")
                }
            }
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
        val now = System.currentTimeMillis()
        val options = appWidgetManager.getAppWidgetOptions(widgetId)
        val views = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            kind != "quick" && kind != "overview") {
            // Let the launcher choose for each actual size, including foldables.
            val layouts = linkedMapOf<SizeF, RemoteViews>()
            for (height in listOf(40, 60, 80, 140)) {
                layouts[SizeF(40f, height.toFloat())] =
                    createViews(context, widgetId, widgetData, height, now)
            }
            RemoteViews(layouts)
        } else {
            val isLandscape = context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
            val heightOption = if (isLandscape) AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT
                else AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT
            createViews(context, widgetId, widgetData, options.getInt(heightOption), now)
        }
        appWidgetManager.updateAppWidget(widgetId, views)
    }

    internal fun createViews(
        context: Context,
        widgetId: Int,
        widgetData: SharedPreferences,
        minHeight: Int,
        now: Long,
    ): RemoteViews {
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.ROOT).format(Date(now))
        val useCompact = kind == "compact" ||
            (kind in listOf("monthly", "upcoming") && minHeight in 1..139)
        val layout = when {
            useCompact -> R.layout.widget_compact
            kind == "upcoming" -> R.layout.widget_upcoming
            kind == "overview" -> R.layout.widget_overview
            kind == "quick" -> R.layout.widget_quick
            else -> R.layout.widget_layout
        }
        val views = RemoteViews(context.packageName, layout)
        applyAppearance(context, views, widgetData, useCompact)
        val savedData = try {
            JSONObject(widgetData.getString("widget_snapshot", "") ?: "")
        } catch (_: Exception) {
            JSONObject()
        }
        val data = WidgetSnapshotData.forDate(savedData, today)
        val savedDate = savedData.optString("date")
        val state = WidgetDisplayState.resolve(
            widgetData.getString("widget_user_id", ""),
            data.optString("uid"),
            data.optString("date"),
            today,
            widgetData.getString("widget_status", "logged_out") == "active",
            widgetData.getLong(revealUntilKey(widgetId), 0L),
            now,
        )
        val visible = state == WidgetDisplayState.VISIBLE
        fun amount(key: String): String = when (state) {
            WidgetDisplayState.SIGNED_OUT -> "Entre no app"
            WidgetDisplayState.STALE -> "Atualize no app"
            WidgetDisplayState.HIDDEN -> "R$ •••••"
            WidgetDisplayState.VISIBLE -> data.optString(key, "R$ 0,00")
        }
        val openApp = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("keybudget://dashboard"),
        )
        val addExpense = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("keybudget://addexpense"),
        )
        views.setOnClickPendingIntent(R.id.widget_root, openApp)
        views.setOnClickPendingIntent(R.id.btn_add_expense, addExpense)
        if (kind != "quick") {
            if (useCompact && minHeight in 1..79) {
                views.setViewVisibility(R.id.tv_subtitle, View.GONE)
                if (minHeight < 60) views.setViewVisibility(R.id.tv_title, View.GONE)
                val padding = (8 * context.resources.displayMetrics.density).toInt()
                views.setViewPadding(R.id.widget_root, padding, padding, padding, padding)
            }
            views.setTextViewText(R.id.tv_title, when (kind) {
                "overview" -> "Resumo do mês"
                "upcoming" -> "Próximos 7 dias"
                else -> "Gastos do mês"
            })
            views.setTextViewText(R.id.tv_monthly_spent, amount(if (kind == "upcoming") "upcoming" else "spent"))
            views.setTextViewText(R.id.tv_subtitle, when {
                state == WidgetDisplayState.SIGNED_OUT -> "Toque para entrar"
                state == WidgetDisplayState.STALE -> "Toque para atualizar"
                savedDate != today && data.optString("date") == today -> {
                    val displayDate = try {
                        java.time.LocalDate.parse(savedDate)
                            .format(java.time.format.DateTimeFormatter.ofPattern("dd/MM"))
                    } catch (_: Exception) { "—" }
                    "Dados do app · $displayDate"
                }
                kind == "upcoming" && visible -> {
                    val count = data.optInt("upcoming_count")
                    if (count == 1) "1 despesa cadastrada" else "$count despesas cadastradas"
                }
                kind == "upcoming" -> "Despesas cadastradas"
                else -> "Realizados até hoje"
            })
            views.setOnClickPendingIntent(R.id.btn_toggle_visibility,
                if (state == WidgetDisplayState.STALE || state == WidgetDisplayState.SIGNED_OUT) openApp
                else visibilityPendingIntent(context, widgetId,
                    if (visible) ACTION_MASK_VALUE else ACTION_REVEAL_VALUE))
            views.setImageViewResource(R.id.btn_toggle_visibility,
                if (visible) R.drawable.ic_visibility_off else R.drawable.ic_visibility)
            views.setContentDescription(
                R.id.btn_toggle_visibility,
                when (state) {
                    WidgetDisplayState.SIGNED_OUT -> "Entrar no KeyBudget"
                    WidgetDisplayState.STALE -> "Atualizar valores no aplicativo"
                    WidgetDisplayState.VISIBLE -> "Ocultar valores"
                    WidgetDisplayState.HIDDEN -> "Mostrar valores temporariamente"
                },
            )
            if (kind == "overview") {
                val incomeEnabled = data.optBoolean("show_income", false)
                views.setViewVisibility(R.id.widget_income_row, if (incomeEnabled) View.VISIBLE else View.GONE)
                views.setTextViewText(R.id.tv_income, amount("income"))
                views.setTextViewText(R.id.tv_balance, amount("balance"))
            }
        }

        return views
    }

    private fun applyAppearance(
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences,
        compact: Boolean,
    ) {
        val appearance = try {
            JSONObject(widgetData.getString("widget_appearance", "") ?: "")
        } catch (_: Exception) {
            JSONObject()
        }
        val systemDark = context.resources.configuration.uiMode and
            Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
        val dark = when (appearance.optString("mode")) {
            "dark" -> true
            "light" -> false
            else -> systemDark
        }
        fun color(key: String, fallback: Int, isDark: Boolean): Int =
            appearance.optJSONObject(if (isDark) "dark" else "light")
                ?.optLong(key, context.getColor(fallback).toLong())?.toInt()
                ?: context.getColor(fallback)
        fun apply(view: Int, method: String, key: String, fallback: Int) {
            if (Build.VERSION.SDK_INT >= 31 && appearance.optString("mode") == "system") {
                // Launcher reapplies the right palette when system brightness changes.
                views.setColorInt(view, method,
                    color(key, fallback, false), color(key, fallback, true))
            } else {
                views.setInt(view, method, color(key, fallback, dark))
            }
        }
        // Tintable shape images preserve rounded corners on older Android too.
        apply(R.id.widget_background_image, "setColorFilter", "background", R.color.widget_bg)
        if (!compact) {
            apply(R.id.widget_button_image, "setColorFilter", "button", R.color.widget_btn_bg)
            apply(R.id.btn_add_expense, "setTextColor", "on_button", R.color.widget_btn_text)
        }
        if (kind != "quick") {
            apply(R.id.tv_title, "setTextColor", "secondary", R.color.widget_text_secondary)
            apply(R.id.tv_subtitle, "setTextColor", "secondary", R.color.widget_text_secondary)
            apply(R.id.tv_monthly_spent, "setTextColor", "foreground", R.color.widget_text_primary)
            apply(R.id.btn_toggle_visibility, "setColorFilter", "secondary", R.color.widget_text_secondary)
        }
        if (kind == "overview") {
            apply(R.id.tv_income, "setTextColor", "foreground", R.color.widget_text_primary)
            apply(R.id.tv_balance, "setTextColor", "foreground", R.color.widget_text_primary)
            apply(R.id.tv_income_label, "setTextColor", "secondary", R.color.widget_text_secondary)
            apply(R.id.tv_balance_label, "setTextColor", "secondary", R.color.widget_text_secondary)
        }
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
        val intent = Intent(context, javaClass).apply {
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

class KeyBudgetCompactWidgetReceiver : KeyBudgetWidgetReceiver() {
    override val kind = "compact"
}
class KeyBudgetOverviewWidgetReceiver : KeyBudgetWidgetReceiver() {
    override val kind = "overview"
}
class KeyBudgetUpcomingWidgetReceiver : KeyBudgetWidgetReceiver() {
    override val kind = "upcoming"
}
class KeyBudgetQuickWidgetReceiver : KeyBudgetWidgetReceiver() {
    override val kind = "quick"
}
