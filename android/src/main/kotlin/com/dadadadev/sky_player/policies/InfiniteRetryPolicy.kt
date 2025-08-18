package com.dadadadev.sky_player.policies

import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.upstream.LoadErrorHandlingPolicy

@UnstableApi
class InfiniteRetryPolicy : LoadErrorHandlingPolicy {
    override fun getFallbackSelectionFor(
        fallbackOptions: LoadErrorHandlingPolicy.FallbackOptions,
        loadErrorInfo: LoadErrorHandlingPolicy.LoadErrorInfo
    ): LoadErrorHandlingPolicy.FallbackSelection? {
        return null
    }

    override fun getRetryDelayMsFor(
        loadErrorInfo: LoadErrorHandlingPolicy.LoadErrorInfo
    ): Long {
        return 1000
    }

    override fun getMinimumLoadableRetryCount(dataType: Int): Int {
        return Int.MAX_VALUE
    }
}