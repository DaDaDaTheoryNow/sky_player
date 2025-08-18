package com.dadadadev.sky_player.telemetry

import android.util.Log
import timber.log.Timber

class ReleaseTree : Timber.Tree() {
    override fun isLoggable(tag: String?, priority: Int): Boolean {
        return priority >= Log.WARN
    }

    override fun log(priority: Int, tag: String?, message: String, t: Throwable?) {
        // forward to Android Logcat
        Log.println(priority, tag ?: "SkyPlayer", message)
        // optionally send t to Sentry here
    }
}
