package com.gg.zmoney

import android.os.Bundle
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.ads.RequestConfiguration
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize the Mobile Ads SDK.
        MobileAds.initialize(this) {}

        // Set test device IDs
        val requestConfiguration = RequestConfiguration.Builder()
            .setTestDeviceIds(listOf("635AF7DDDAF79ECCB8336279257A89F1")) // Replace with your actual device ID for testing
            .build()
        MobileAds.setRequestConfiguration(requestConfiguration)

        // Rest of your onCreate method...
    }
}
