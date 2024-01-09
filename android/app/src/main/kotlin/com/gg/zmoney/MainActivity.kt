package com.gg.zmoney

import android.os.Bundle
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.games.PlayGamesSdk
import com.google.android.gms.games.PlayGames
import com.google.android.gms.games.GamesSignInClient
import com.google.firebase.FirebaseApp
import com.google.firebase.crashlytics.FirebaseCrashlytics
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.AdView
import com.google.firebase.analytics.FirebaseAnalytics
import com.google.android.ump.ConsentInformation
import com.google.android.ump.ConsentRequestParameters
import com.google.android.ump.UserMessagingPlatform
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.gg.zmoney/play_games"
    private lateinit var consentInformation: ConsentInformation
    private val TAG = "MainActivity"
    private lateinit var firebaseAnalytics: FirebaseAnalytics
    lateinit var mAdView: AdView
    private lateinit var gamesSignInClient: GamesSignInClient

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize Play Games SDK
        PlayGamesSdk.initialize(this)
        
        // Initialize other services like Firebase, Mobile Ads
        FirebaseApp.initializeApp(this)
        MobileAds.initialize(this) {}
        FirebaseCrashlytics.getInstance().setCrashlyticsCollectionEnabled(true)
        FirebaseCrashlytics.getInstance().log("MainActivity Loaded Successfully")
        initializeUMP()

        // Initialize Google Play Games Sign-In Client
        gamesSignInClient = PlayGames.getGamesSignInClient(this)

        // Check player authentication
        checkPlayerAuthentication()

        // MethodChannel setup
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAuthenticated" -> isAuthenticated(result)
                "signIn" -> signIn(result)
                "requestConsent" -> {
                    initializeUMP()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isAuthenticated(result: MethodChannel.Result) {
        gamesSignInClient.isAuthenticated().addOnCompleteListener { task ->
            val isAuthenticated = task.isSuccessful && task.result?.isAuthenticated == true
            result.success(isAuthenticated)
        }
    }

    private fun signIn(result: MethodChannel.Result) {
        gamesSignInClient.signIn().addOnCompleteListener { task ->
            val wasSuccessful = task.isSuccessful
            result.success(wasSuccessful)
            // Additional logic based on sign-in success or failure
        }
    }

    private fun showPlayerInfo() {
    PlayGames.getPlayersClient(this).currentPlayer.addOnCompleteListener { task ->
        if (task.isSuccessful) {
            val player = task.result
            val displayName = player?.displayName // Player's display name
            // Update UI with player information
            Log.d(TAG, "Player Display Name: $displayName")
        } else {
            // Handle failure
            Log.e(TAG, "Failed to retrieve player information")
        }
    }
}

   private fun checkPlayerAuthentication() {
    gamesSignInClient.isAuthenticated().addOnCompleteListener { task ->
        if (task.isSuccessful && task.result?.isAuthenticated == true) {
            // User is signed in, show player info
            showPlayerInfo()
        } else {
            // User is not signed in, handle accordingly
        }
    }
}

     private fun getPlayerId() {
        PlayGames.getPlayersClient(this).currentPlayer.addOnCompleteListener { task ->
            if (task.isSuccessful) {
                val playerId = task.result?.playerId
                Log.d(TAG, "Player ID: $playerId")
                // Use Player ID as needed
            } else {
                // Handle failure to retrieve player ID
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
