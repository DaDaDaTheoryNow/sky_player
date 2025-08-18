package com.dadadadev.sky_player.telemetry

import android.annotation.SuppressLint
import android.util.Log
import timber.log.Timber
import java.io.File
import java.io.FileWriter
import java.io.PrintWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class FileLoggingTree(private val dir: File) : Timber.Tree() {
    private val dateFmt = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US)
    private val lock = Any()
    private val logFile = File(dir, "skyplayer.log")
    private val maxSize = 1024 * 1024L // 1MB

    @SuppressLint("LogNotTimber")
    override fun log(priority: Int, tag: String?, message: String, t: Throwable?) {
        // keep only INFO+ to reduce noise
        if (priority < Log.INFO) return

        val ts = dateFmt.format(Date())
        val thread = Thread.currentThread().name
        val line = "$ts [$thread] ${tag ?: "SkyPlayer"} ${priorityToChar(priority)}: $message\n"

        synchronized(lock) {
            try {
                // ensure parent exists (safe null checks)
                val parent = logFile.parentFile
                if (parent != null && !parent.exists()) parent.mkdirs()

                // rotate if needed
                if (logFile.exists() && logFile.length() > maxSize) rotate()

                // Write line + optional stacktrace. Use PrintWriter to be able to call printStackTrace
                PrintWriter(FileWriter(logFile, true)).use { pw ->
                    pw.append(line)
                    if (t != null) {
                        // printStackTrace(PrintWriter) is available
                        t.printStackTrace(pw)
                        pw.append("\n")
                    }
                    pw.flush()
                }
            } catch (e: Exception) {
                // Don't use Timber here (would re-enter this tree). Use Android Log instead.
                Log.w("FileLoggingTree", "Failed to write log", e)
            }
        }
    }

    @SuppressLint("LogNotTimber")
    private fun rotate() {
        val dst = File(dir, "skyplayer-${System.currentTimeMillis()}.log")
        try {
            logFile.renameTo(dst)
        } catch (e: Exception) {
            Log.w("FileLoggingTree", "rotate failed", e)
        }
    }

    private fun priorityToChar(p: Int) = when (p) {
        Log.VERBOSE -> 'V'
        Log.DEBUG -> 'D'
        Log.INFO -> 'I'
        Log.WARN -> 'W'
        Log.ERROR -> 'E'
        else -> '?'
    }
}
