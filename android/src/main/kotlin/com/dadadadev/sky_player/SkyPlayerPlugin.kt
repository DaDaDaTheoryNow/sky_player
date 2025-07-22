package com.dadadadev.sky_player

import androidx.media3.common.util.UnstableApi
import com.dadadadev.sky_player.player_view.NativeViewFactory
import com.dadadadev.sky_player.view_model.SkyPlayerViewModel
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** SkyPlayerPlugin */
@UnstableApi
class SkyPlayerPlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var methodChannel : MethodChannel
  private lateinit var eventChannel: EventChannel
  private lateinit var viewModel: SkyPlayerViewModel

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    val context = binding.applicationContext
    viewModel = SkyPlayerViewModel(context)

    methodChannel = MethodChannel(binding.binaryMessenger, SKY_PLAYER_CHANNEL)
    methodChannel.setMethodCallHandler(this)

    eventChannel = EventChannel(binding.binaryMessenger, EVENTS_CHANNEL)
    eventChannel.setStreamHandler(SkyPlayerEventStreamHandler(viewModel))

    binding.platformViewRegistry.registerViewFactory(
      PLAYER_VIEW_ID,
      NativeViewFactory(viewModel)
    )
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      GET_PLATFORM_VERSION_METHOD -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      PLAY_METHOD -> {
        viewModel.play()
        result.success(null)
      }
      PAUSE_METHOD -> {
        viewModel.pause()
        result.success(null)
      }
      INIT_PLAYER_WITH_HLS_METHOD -> {
        val url = call.argument<String>("url")
        if (url.isNullOrBlank()) {
          result.error("INVALID_URL", "URL must be provided and non-empty", null)
          return
        }

        viewModel.initPlayerWithHls(url)
        result.success(null)
      }
      SET_NATIVE_CONTROLS_ENABLED_METHOD -> {
        val isEnabled = call.argument<Boolean>("isEnabled")
        if (isEnabled == null) {
          result.error("INVALID_ARGUMENT", "ARGUMENT must be provided and non-empty", null)
          return
        }

        viewModel.setNativeControlsEnabled(isEnabled)
        result.success(null)
      }
      SEEK_TO_METHOD -> {
        val position = call.argument<Int>("position")
        if (position == null) {
          result.error("INVALID_POSITION", "POSITION must be provided and non-empty", null)
          return
        }

        viewModel.seekTo(position.toLong())
        result.success(null)
      }
      SET_RESOLUTION_METHOD -> {
        val resolutionId = call.argument<String?>("resolutionId")

        viewModel.setResolution(resolutionId)
        result.success(null)
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
  }

  companion object {
    private const val SKY_PLAYER_CHANNEL = "sky_player_channel"
    private const val EVENTS_CHANNEL = "sky_player_channel/playerEvents"
    private const val PLAYER_VIEW_ID = "sky_player_view"

    // Method names
    private const val INIT_PLAYER_WITH_HLS_METHOD = "initPlayerWithHls"
    private const val PLAY_METHOD = "play"
    private const val PAUSE_METHOD = "pause"
    private const val GET_PLATFORM_VERSION_METHOD = "getPlatformVersion"
    private const val SET_NATIVE_CONTROLS_ENABLED_METHOD = "setNativeControlsEnabled"
    private const val SEEK_TO_METHOD = "seekTo"
    private const val SET_RESOLUTION_METHOD = "setResolution"
  }
}