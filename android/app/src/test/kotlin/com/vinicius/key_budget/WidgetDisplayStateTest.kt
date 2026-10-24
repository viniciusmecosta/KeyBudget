package com.vinicius.key_budget

import org.junit.Assert.assertEquals
import org.junit.Test

class WidgetDisplayStateTest {
    private fun state(uid: String? = "u", snapshotUid: String? = "u",
                      date: String? = "2026-12-31", active: Boolean = true,
                      expiry: Long = 2000) = WidgetDisplayState.resolve(
        uid, snapshotUid, date, "2026-12-31", active, expiry, 1000)

    @Test fun valuesRequireAnActiveMatchingSessionAndFreshDate() {
        assertEquals(WidgetDisplayState.VISIBLE, state())
        assertEquals(WidgetDisplayState.SIGNED_OUT, state(uid = ""))
        assertEquals(WidgetDisplayState.SIGNED_OUT, state(active = false))
        assertEquals(WidgetDisplayState.STALE, state(snapshotUid = "another-user"))
        assertEquals(WidgetDisplayState.STALE, state(date = "2026-12-30"))
        assertEquals(WidgetDisplayState.STALE, state(date = "2027-01-01"))
        assertEquals(WidgetDisplayState.STALE, state(snapshotUid = null, date = null))
    }

    @Test fun expiredRevealMasksAtTheExactDeadline() {
        assertEquals(WidgetDisplayState.HIDDEN, state(expiry = 0))
        assertEquals(WidgetDisplayState.HIDDEN, state(expiry = 999))
        assertEquals(WidgetDisplayState.HIDDEN, state(expiry = 1000))
        assertEquals(WidgetDisplayState.VISIBLE, state(expiry = 1001))
    }
}
