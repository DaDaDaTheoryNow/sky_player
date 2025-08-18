package com.dadadadev.sky_player

import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import com.dadadadev.sky_player.view_model.SkyPlayerState
import com.dadadadev.sky_player.view_model.SkyPlayerViewModel
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import timber.log.Timber

private const val TAG = "SkyPlayer: SkyPlayerEventStreamHandler"


@OptIn(UnstableApi::class)
class SkyPlayerEventStreamHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private var stateCollectorJob: Job? = null
    private var currentViewModel: SkyPlayerViewModel? = null
    private val json = Json { encodeDefaults = true }
    private val coroutineScope = CoroutineScope(Dispatchers.Main)

    fun bindViewModel(viewModel: SkyPlayerViewModel) {
        // Clean up previous view model if exists
        unbindViewModel()

        currentViewModel = viewModel
        startStateCollection()
    }

    private fun unbindViewModel() {
        stateCollectorJob?.cancel()
        stateCollectorJob = null
        currentViewModel = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        startStateCollection()
    }

    override fun onCancel(arguments: Any?) {
        cleanupResources()
    }

    private fun startStateCollection() {
        // Don't start if no sink or no view model
        if (eventSink == null || currentViewModel == null) return

        // Cancel previous collection if active
        stateCollectorJob?.cancel()

        stateCollectorJob = coroutineScope.launch {
            currentViewModel?.state?.collectLatest { state ->
                try {
                    val eventData = createEventData(state)
                    eventSink?.success(eventData)
                } catch (e: Exception) {
                    Timber.tag(TAG).e(e, "Error sending event data")
                }
            }
        }
    }

    private fun createEventData(state: SkyPlayerState): Map<String, Any?> {
        return mapOf(
            "isPlaying" to state.isPlaying,
            "position" to state.position,
            "duration" to state.duration,
            "buffering" to state.buffering,
            "isLoading" to state.isLoading,
            "videoAspectRatio" to state.videoAspectRatio,

            "selectedResolutionId" to state.selectedResolutionId,
            "availableResolutions" to json.encodeToString(state.availableVideoResolutions),

            "selectedAudioTrackId" to state.selectedAudioTrackId,
            "availableAudioTracks" to json.encodeToString(state.availableAudioTracks),

            "selectedSubtitleTrackId" to state.selectedSubtitleTrackId,
            "availableSubtitleTracks" to json.encodeToString(state.availableSubtitleTracks),

            "textureId" to state.textureId,
            "currentCues" to json.encodeToString(state.currentCues)
        )
    }

    private fun cleanupResources() {
        stateCollectorJob?.cancel()
        stateCollectorJob = null
        eventSink = null
    }
}
