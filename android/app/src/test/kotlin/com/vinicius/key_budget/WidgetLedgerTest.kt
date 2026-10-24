package com.vinicius.key_budget

import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Test

class WidgetLedgerTest {
    private fun day(date: String, spent: Long, income: Long = 0, count: Int = 1) =
        WidgetDay(LocalDate.parse(date), spent, income, count)

    @Test fun rollsIntoNextMonthWithoutOpeningFlutter() {
        val days = listOf(day("2026-12-31", 30, 500000), day("2027-01-01", 1250),
            day("2027-01-07", 500), day("2027-01-08", 800), day("2027-01-09", 999))
        assertEquals(WidgetTotals(30, 500000, 1750, 2),
            WidgetLedger.totals(days, LocalDate.parse("2026-12-31")))
        assertEquals(WidgetTotals(1250, 0, 1300, 2),
            WidgetLedger.totals(days, LocalDate.parse("2027-01-01")))
    }

    @Test fun usesExactCentsAndExcludesFutureIncomeFromBalance() {
        val days = listOf(day("2028-02-28", 10, 100), day("2028-02-29", 20),
            day("2028-03-01", 70, 9000), day("2028-03-07", 80), day("2028-03-08", 90))
        assertEquals(WidgetTotals(30, 100, 150, 2),
            WidgetLedger.totals(days, LocalDate.parse("2028-02-29")))
        assertEquals(WidgetTotals(0, 0, 0, 0),
            WidgetLedger.totals(days, LocalDate.parse("2029-01-01")))
        assertEquals(WidgetTotals(0, 0, 0, 0), WidgetLedger.totals(emptyList(), LocalDate.now()))
    }
}
