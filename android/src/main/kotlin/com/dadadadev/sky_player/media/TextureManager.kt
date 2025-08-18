package com.dadadadev.sky_player.media

import android.graphics.SurfaceTexture
import android.view.Surface
import io.flutter.view.TextureRegistry
import timber.log.Timber

private const val TAG = "SkyPlayer: TextureManager"

/**
 * Handles SurfaceTextureEntry lifecycle and safe interactions with Surface.
 * Public operations should be executed on the main thread because TextureRegistry is main-thread bound.
 */
class TextureManager(
    private val textureRegistry: TextureRegistry?
) {
    @Volatile
    private var surfaceEntry: TextureRegistry.SurfaceTextureEntry? = null

    @Volatile
    private var surfaceRef: Surface? = null

    /** Returns current texture id or null if none created. */
    fun currentTextureId(): Long? = surfaceEntry?.id()

    /**
     * Create and attach texture; returns the texture id or null on failure.
     * Must be called on main thread because TextureRegistry is main-thread bound.
     */
    @Synchronized
    fun createSurface(): Long? {
        if (textureRegistry == null) {
            Timber.tag(TAG).w("createSurface: textureRegistry is null, cannot create SurfaceTexture")
            return null
        }

        // If already created, return existing id
        surfaceEntry?.let {
            Timber.tag(TAG).d("createSurface: already created textureId=${it.id()}")
            return it.id()
        }

        return try {
            val entry = textureRegistry.createSurfaceTexture()
            surfaceEntry = entry
            val st: SurfaceTexture = entry.surfaceTexture()
            surfaceRef = Surface(st)
            val id = entry.id()
            Timber.tag(TAG).i("createSurface: created textureId=$id")
            id
        } catch (t: Throwable) {
            Timber.tag(TAG).e(t, "createSurface: failed to create SurfaceTexture")
            // ensure consistent state on failure
            try { surfaceRef?.release() } catch (_: Throwable) {}
            surfaceRef = null
            try { surfaceEntry?.release() } catch (_: Throwable) {}
            surfaceEntry = null
            null
        }
    }

    /**
     * Apply default buffer size (called from UI thread after layout changes).
     */
    @Synchronized
    fun setDefaultBufferSize(widthPx: Int, heightPx: Int) {
        try {
            surfaceEntry?.surfaceTexture()?.setDefaultBufferSize(widthPx, heightPx)
            Timber.tag(TAG).d("setDefaultBufferSize: width=%d height=%d", widthPx, heightPx)
        } catch (t: Throwable) {
            Timber.tag(TAG).e(t, "setDefaultBufferSize: failed to set buffer size")
        }
    }

    /**
     * Release surface and entry. Safe to call multiple times.
     */
    @Synchronized
    fun release() {
        Timber.tag(TAG).d("release: releasing texture resources")
        try {
            surfaceRef?.release()
            Timber.tag(TAG).d("release: surface released")
        } catch (t: Throwable) {
            Timber.tag(TAG).w(t, "release: surface.release() failed")
        } finally {
            surfaceRef = null
        }

        try {
            surfaceEntry?.release()
            Timber.tag(TAG).d("release: surfaceEntry released")
        } catch (t: Throwable) {
            Timber.tag(TAG).w(t, "release: surfaceEntry.release() failed")
        } finally {
            surfaceEntry = null
        }
    }

    /** Returns the Surface instance (nullable) — used by PlayerController to attach. */
    @Synchronized
    fun getSurface(): Surface? = surfaceRef
}
