package com.gg.zmoney

import android.content.Context
import android.view.View
import io.flutter.plugin.platform.PlatformView

class NativeView(context: Context, viewId: Int, args: Map<String?, Any?>?) : PlatformView {
    private val nativeView: View

    init {
        // Initialize your native view here
        nativeView = View(context)
    }

    override fun getView(): View {
        return nativeView
    }

    override fun dispose() {
        // Dispose of resources if needed
    }
}
