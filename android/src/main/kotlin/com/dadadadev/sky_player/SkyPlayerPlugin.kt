package com.dadadadev.sky_player

import android.content.Context
import androidx.media3.common.util.UnstableApi
import com.dadadadev.sky_player.telemetry.LoggerInitializer
import com.dadadadev.sky_player.view_model.SkyPlayerViewModel
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.view.TextureRegistry

/** SkyPlayerPlugin */
@UnstableApi
class SkyPlayerPlugin : FlutterPlugin, MethodCallHandler {
  // Channels
  private lateinit var methodChannel: MethodChannel
  private lateinit var eventChannel: EventChannel

  // Dependencies
  private lateinit var context: Context
  private var textureRegistry: TextureRegistry? = null

  // Player management
  private var viewModel: SkyPlayerViewModel? = null
  private var eventStreamHandler: SkyPlayerEventStreamHandler? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    textureRegistry = binding.textureRegistry

    setupChannels(binding)
  }

  private fun setupChannels(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel = MethodChannel(binding.binaryMessenger, SKY_PLAYER_CHANNEL).apply {
      setMethodCallHandler(this@SkyPlayerPlugin)
    }

    eventChannel = EventChannel(binding.binaryMessenger, EVENTS_CHANNEL).apply {
      eventStreamHandler = SkyPlayerEventStreamHandler().also {
        setStreamHandler(it)
      }
    }
  }

  private fun initializePlayer() {
    viewModel?.release()
    viewModel = SkyPlayerViewModel(context, textureRegistry).also {
      eventStreamHandler?.bindViewModel(it)
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    try {
      when (call.method) {
        // Player lifecycle methods
        INIT_PLAYER_WITH_NETWORK_METHOD -> handleInitPlayer(call, result)
        RELEASE_PLAYER_METHOD -> handleReleasePlayer(result)

        // Playback control methods
        PLAY_METHOD -> handlePlay(result)
        PAUSE_METHOD -> handlePause(result)
        SEEK_TO_METHOD -> handleSeekTo(call, result)

        // Track selection methods
        SET_RESOLUTION_METHOD -> handleSetResolution(call, result)
        SET_AUDIO_TRACK_METHOD -> handleSetAudioTrack(call, result)
        SET_SUBTITLE_TRACK_METHOD -> handleSetSubtitleTrack(call, result)

        // Texture methods
        CREATE_TEXTURE_METHOD -> handleCreateTexture(result)
        SET_SURFACE_SIZE_METHOD -> handleSetSurfaceSize(call, result)

        // Logger configuration
        INIT_LOGGER_METHOD -> handleInitLogger(call, result)

        else -> result.notImplemented()
      }
    } catch (e: Exception) {
      result.error("PLAYER_ERROR", e.message, null)
    }
  }

  // region Player Lifecycle Handlers
  private fun handleInitPlayer(call: MethodCall, result: Result) {
    val url = call.argument<String>("url") ?: run {
      result.error("INVALID_URL", "URL must be provided", null)
      return
    }

    initializePlayer()
    viewModel?.initPlayerWithNetwork(url)

    result.success(null)
  }

  private fun handleReleasePlayer(result: Result) {
    viewModel?.release()
    result.success(null)
  }

  // region Playback Control Handlers
  private fun handlePlay(result: Result) {
    viewModel?.play()
    result.success(null)
  }

  private fun handlePause(result: Result) {
    viewModel?.pause()
    result.success(null)
  }

  private fun handleSeekTo(call: MethodCall, result: Result) {
    val position = call.argument<Int>("position")?.toLong() ?: run {
      result.error("INVALID_POSITION", "Position must be provided", null)
      return
    }

    viewModel?.seekTo(position)
    result.success(null)
  }
  // endregion

  // region Track Selection Handlers
  private fun handleSetResolution(call: MethodCall, result: Result) {
    val resolutionId = call.argument<String?>("resolutionId")
    viewModel?.setResolution(resolutionId)
    result.success(null)
  }

  private fun handleSetAudioTrack(call: MethodCall, result: Result) {
    val trackId = call.argument<String?>("trackId")
    viewModel?.setAudioTrack(trackId)
    result.success(null)
  }

  private fun handleSetSubtitleTrack(call: MethodCall, result: Result) {
    val trackId = call.argument<String?>("trackId")
    viewModel?.setSubtitleTrack(trackId)
    result.success(null)
  }
  // endregion

  // region Texture Handlers
  private fun handleCreateTexture(result: Result) {
    val textureId = viewModel?.createTextureForPlayer() ?: run {
      result.error("TEXTURE_ERROR", "Failed to create texture", null)
      return
    }

    result.success(textureId)
  }

  private fun handleSetSurfaceSize(call: MethodCall, result: Result) {
    val width = call.argument<Int>("width") ?: 0
    val height = call.argument<Int>("height") ?: 0
    viewModel?.setSurfaceSize(width, height)
    result.success(null)
  }
  // endregion

  // region Logger Configuration
  private fun handleInitLogger(call: MethodCall, result: Result) {
    val debug = call.argument<Boolean>("debug") ?: false
    val fileLogging = call.argument<Boolean>("fileLogging") ?: false

    LoggerInitializer.init(context, debug = debug, enableFileLogging = fileLogging)
    result.success(null)
  }
  // endregion

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    cleanupResources()
  }

  private fun cleanupResources() {
    methodChannel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)

    viewModel?.release()
    viewModel = null
    eventStreamHandler = null
  }

  companion object {
    // Channel names
    private const val SKY_PLAYER_CHANNEL = "sky_player_channel"
    private const val EVENTS_CHANNEL = "sky_player_channel/playerEvents"

    // Method names
    private const val INIT_LOGGER_METHOD = "initLogger"
    private const val INIT_PLAYER_WITH_NETWORK_METHOD = "initPlayerWithNetwork"
    private const val RELEASE_PLAYER_METHOD = "releasePlayer"
    private const val PLAY_METHOD = "play"
    private const val PAUSE_METHOD = "pause"
    private const val SEEK_TO_METHOD = "seekTo"
    private const val SET_RESOLUTION_METHOD = "setResolution"
    private const val SET_AUDIO_TRACK_METHOD = "setAudioTrack"
    private const val SET_SUBTITLE_TRACK_METHOD = "setSubtitleTrack"
    private const val CREATE_TEXTURE_METHOD = "createTexture"
    private const val SET_SURFACE_SIZE_METHOD = "setSurfaceSize"
  }
}