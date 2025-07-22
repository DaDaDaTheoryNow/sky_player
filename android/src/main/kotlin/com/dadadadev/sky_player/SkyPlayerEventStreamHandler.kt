package com.dadadadev.sky_player

import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import com.dadadadev.sky_player.view_model.SkyPlayerViewModel
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

@OptIn(UnstableApi::class)
class SkyPlayerEventStreamHandler(
    private val viewModel: SkyPlayerViewModel
) : EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null
    private var job: Job? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events

        job = CoroutineScope(Dispatchers.Main).launch {
            viewModel.state.collectLatest { state ->
                Log.i("SkyPlayer", state.toString())

                val eventData = mapOf(
                    "isPlaying" to state.isPlaying,
                    "position" to state.position,
                    "duration" to state.duration,
                    "buffering" to state.buffering,
                    "isLoading" to state.isLoading,
                    "isNativeControlsEnabled" to state.isNativeControlsEnabled,
                    "selectedResolutionId" to state.selectedResolutionId,
                    "availableResolutions" to Json.encodeToString(state.availableVideoResolutions),
                )
                
                eventSink?.success(eventData)
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        if (job?.isActive == true) {
            job?.cancel()
        }

        job = null
        eventSink = null
    }
}
