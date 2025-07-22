package com.dadadadev.sky_player.player_view

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import androidx.media3.common.util.UnstableApi
import com.dadadadev.sky_player.databinding.ActivityPlayerBinding
import com.dadadadev.sky_player.view_model.SkyPlayerViewModel
import io.flutter.plugin.platform.PlatformView


@UnstableApi
class NativeView(
    context: Context,
    private val viewModel: SkyPlayerViewModel
) : PlatformView {
    private val binding = ActivityPlayerBinding.inflate(LayoutInflater.from(context))
    private val player = viewModel.player

    override fun getView(): View = binding.root
    override fun dispose() {}

    init {
        binding.playerView.player = player

        viewModel.attachPlayerView(binding.playerView)
        viewModel.setNativeControlsEnabled(
            viewModel.state.value.isNativeControlsEnabled
        )
    }

    override fun onFlutterViewDetached() {
        viewModel.detachPlayerView()
        super.onFlutterViewDetached()
    }
}


//// TODO: Create view model
//@UnstableApi
//internal class NativeView(
//    private val context: Context,
//    id: Int
//) : PlatformView {
//    private val trackSelector = DefaultTrackSelector(context)
//    private val player = ExoPlayer.Builder(context).setTrackSelector(trackSelector).build()
//    private val binding = ActivityPlayerBinding.inflate(LayoutInflater.from(context))
//
//    companion object {
//        private const val TAG = "SkyPlayer"
//    }
//
//    override fun getView(): View {
//        return binding.root
//    }
//
//    override fun dispose() {
//        Log.i(TAG, "Disposing SkyPlayer resources")
//        player.release()
//    }
//
//    init {
//        val mediaItem = MediaItem.Builder()
//            .setUri("https://playertest.longtailvideo.com/adaptive/elephants_dream_v4/index.m3u8")
//            .build()
//
//        player.setMediaItem(mediaItem)
//        player.prepare()
//        player.playWhenReady = true
//
////        binding.playerView.useController = false
//        binding.playerView.setShowSubtitleButton(true)
//
//        binding.playerView.player = player
////        binding.qualityButton.setOnClickListener {
//////            player.playWhenReady = !player.playWhenReady
//////            showQualityMenu()
////        }
//    }
//
//
//
//    private fun showQualityMenu() {
//        val mapped = trackSelector.currentMappedTrackInfo ?: return
//        val menu = PopupMenu(binding.root.context, binding.qualityButton)
//
//        val videoTracks = mutableListOf<TrackInfo>()
//        for (ri in 0 until mapped.rendererCount) {
//            if (mapped.getRendererType(ri) != C.TRACK_TYPE_VIDEO) continue
//            val groups = mapped.getTrackGroups(ri)
//            for (gi in 0 until groups.length) {
//                val group = groups[gi]
//                for (ti in 0 until group.length) {
//                    if (mapped.getTrackSupport(ri, gi, ti) == C.FORMAT_HANDLED) {
//                        val f = group.getFormat(ti)
//                        videoTracks += TrackInfo(
//                            title = "${f.width}×${f.height} ~${"%.1f".format(f.bitrate / 1_000_000.0)} Мбит/с",
//                            group = group,
//                            trackIndex = ti
//                        )
//                    }
//                }
//            }
//        }
//
//        videoTracks.forEachIndexed { idx, info ->
//            menu.menu.add(0, idx, 0, info.title)
//        }
//
//        menu.setOnMenuItemClickListener { item ->
//            val info = videoTracks[item.itemId]
//            val params = trackSelector.buildUponParameters()
//                .setOverrideForType(
//                    TrackSelectionOverride(info.group, listOf(info.trackIndex))
//                )
//                .build()
//            trackSelector.setParameters(params)
//
//            player.prepare()
//            true
//        }
//        menu.show()
//    }
//
//    private data class TrackInfo(
//        val title: String,
//        val group: TrackGroup,
//        val trackIndex: Int
//    )
//}
//

