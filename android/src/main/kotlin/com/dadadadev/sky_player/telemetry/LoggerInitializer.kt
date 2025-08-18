package com.dadadadev.sky_player.telemetry

import android.content.Context
import android.app.Application
import timber.log.Timber

object LoggerInitializer {
    @Volatile
    private var initialized = false

    /**
     * Initialize logging for plugin. Safe to call multiple times; initialization happens once.
     *
     * @param ctx any Context (will use applicationContext for file tree)
     * @param debug true -> plant DebugTree; false -> plant ReleaseTree + optional file tree
     * @param enableFileLogging if true, plants FileLoggingTree (writes logs to filesDir)
     */
    fun init(ctx: Context, debug: Boolean, enableFileLogging: Boolean = false) {
        if (initialized) return

        synchronized(this) {
            if (initialized) return

            // If other code already planted trees (rare), avoid double-planting.
            // We can't reliably introspect Timber forest count (implementation detail), so we use our flag.
            if (debug) {
                Timber.plant(Timber.DebugTree())
            } else {
                Timber.plant(ReleaseTree())
                if (enableFileLogging) {
                    val app = ctx.applicationContext as? Application
                    val filesDir = app?.filesDir ?: ctx.filesDir
                    Timber.plant(FileLoggingTree(filesDir))
                }
            }

            // optional: init Sentry here if desired
            // Sentry.init(ctx) { options -> ... }

            initialized = true
        }
    }

    /** Optional runtime control to enable/disable file logging (simple approach). */
    fun enableFileLogging(ctx: Context, enable: Boolean) {
        // naive: set flag, re-init if necessary. For production, implement add/remove tree.
        if (enable) init(ctx, debug = false, enableFileLogging = true)
    }
}
