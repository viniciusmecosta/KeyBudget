package com.vinicius.key_budget

import java.time.LocalDate

/** Only daily aggregates cross the Flutter/native boundary, never expense details. */
internal data class WidgetDay(val date: LocalDate, val spent: Long, val income: Long, val count: Int)
internal data class WidgetTotals(val spent: Long, val income: Long, val upcoming: Long, val count: Int)

internal object WidgetLedger {
    fun totals(days: List<WidgetDay>, today: LocalDate): WidgetTotals {
        var spent = 0L
        var income = 0L
        var upcoming = 0L
        var count = 0
        val month = today.withDayOfMonth(1)
        val end = today.plusDays(7)
        for (day in days) {
            if (!day.date.isBefore(month) && !day.date.isAfter(today)) {
                spent = Math.addExact(spent, day.spent)
                income = Math.addExact(income, day.income)
            }
            if (day.date.isAfter(today) && !day.date.isAfter(end)) {
                upcoming = Math.addExact(upcoming, day.spent)
                count = Math.addExact(count, day.count)
            }
        }
        return WidgetTotals(spent, income, upcoming, count)
    }
}
