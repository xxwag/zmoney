package com.gg.zmoney

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.games.PlayGamesSdk
import com.google.android.ump.ConsentInformation
import com.google.android.ump.ConsentRequestParameters
import com.google.android.ump.UserMessagingPlatform
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import com.google.android.ump.ConsentDebugSettings
import android.util.Log


class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.gg.zmoney/play_games"
    private lateinit var consentInformation: ConsentInformation
    private val TAG = "MainActivity" // Define your TAG here


    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)

        MobileAds.initialize(this) {}
        PlayGamesSdk.initialize(this)

        initializeUMP()

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAuthenticated" -> {
                    val isAuthenticated = false // Implement actual authentication logic
                    result.success(isAuthenticated)
                }
                "requestConsent" -> {
                    initializeUMP()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

private fun initializeUMP() {
    val params = ConsentRequestParameters.Builder().build()

    consentInformation = UserMessagingPlatform.getConsentInformation(this)
    consentInformation.requestConsentInfoUpdate(
        this,
        params,
        { 
            if (consentInformation.consentStatus == ConsentInformation.ConsentStatus.REQUIRED) {
                UserMessagingPlatform.loadConsentForm(
                    this,
                    { consentForm -> 
                        consentForm.show(this) { /* Handle form dismiss */ }
                        Log.d(TAG, "Consent status is REQUIRED. Showing consent form.")
                    },
                    { formError -> 
                        /* Handle form error */
                        Log.e(TAG, "Error loading consent form: $formError")
                    }
                )
            } else {
                Log.d(TAG, "Consent status is not REQUIRED. No consent form shown.")
            }
        },
        { requestConsentError -> 
            /* Handle update error */
            Log.e(TAG, "Error requesting consent info update: $requestConsentError")
        }
    )
}
}


