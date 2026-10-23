package com.vinicius.key_budget

/** Pure display policy shared by every size, including expired/offline snapshots. */
internal enum class WidgetDisplayState { SIGNED_OUT, STALE, HIDDEN, VISIBLE;
    companion object {
        fun resolve(sessionUid: String?, snapshotUid: String?, snapshotDate: String?,
                    today: String, active: Boolean, revealUntil: Long, now: Long): WidgetDisplayState = when {
            sessionUid.isNullOrEmpty() || !active -> SIGNED_OUT
            snapshotUid != sessionUid || snapshotDate != today -> STALE
            revealUntil <= now -> HIDDEN
            else -> VISIBLE
        }
    }
}
