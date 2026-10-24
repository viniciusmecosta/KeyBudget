package com.vinicius.key_budget

import java.math.BigDecimal
import java.text.NumberFormat
import java.time.LocalDate
import java.util.Locale
import org.json.JSONObject

internal object WidgetSnapshotData {
    fun forDate(saved: JSONObject, today: String): JSONObject {
        if (saved.optInt("version") != 2 || !saved.has("daily")) return saved
        return try {
            val daily = saved.getJSONObject("daily")
            val days = daily.keys().asSequence().map { date ->
                val values = daily.getJSONArray(date)
                require(values.length() == 3 && values.getInt(2) >= 0)
                WidgetDay(LocalDate.parse(date), values.getLong(0), values.getLong(1), values.getInt(2))
            }.toList()
            val totals = WidgetLedger.totals(days, LocalDate.parse(today))
            val currency = NumberFormat.getCurrencyInstance(Locale.forLanguageTag("pt-BR"))
            fun money(cents: Long) = currency.format(BigDecimal.valueOf(cents, 2))
            JSONObject(saved.toString()).apply {
                put("date", today)
                put("spent", money(totals.spent))
                put("income", money(totals.income))
                put("balance", money(Math.subtractExact(totals.income, totals.spent)))
                put("upcoming", money(totals.upcoming))
                put("upcoming_count", totals.count)
            }
        } catch (_: Exception) {
            // Old or incomplete data retains its date; display policy prevents
            // presenting it as a freshly calculated total.
            saved
        }
    }
}
