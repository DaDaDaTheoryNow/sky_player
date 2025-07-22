package com.dadadadev.sky_player.player_view

import android.content.Context
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import com.dadadadev.sky_player.view_model.SkyPlayerViewModel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

@OptIn(UnstableApi::class)
class NativeViewFactory(
    private val viewModel: SkyPlayerViewModel
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return NativeView(context, viewModel)
    }
}