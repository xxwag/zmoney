package com.gg.zmoney

import android.content.Intent
import android.os.Bundle
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.common.ConnectionResult

import com.android.billingclient.api.*

import com.google.android.gms.tasks.Task
import com.google.android.gms.games.PlayGamesSdk
import com.google.android.gms.games.PlayGames
import com.google.android.gms.games.GamesSignInClient
import com.google.firebase.FirebaseApp
import com.google.firebase.crashlytics.FirebaseCrashlytics
import com.google.firebase.analytics.FirebaseAnalytics
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.GoogleAuthProvider
import com.google.android.gms.ads.MobileAds
import com.google.android.ump.ConsentInformation
import com.google.android.ump.ConsentRequestParameters
import com.google.android.ump.UserMessagingPlatform
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity : FlutterActivity() {
   
    private val CHANNEL = "com.gg.zmoney/game_services"
    private val authChannel = "com.gg.zmoney/auth"
    private lateinit var billingClient: BillingClient
    private lateinit var consentInformation: ConsentInformation
    private val TAG = "MainActivity"
    private lateinit var firebaseAnalytics: FirebaseAnalytics
    private lateinit var gamesSignInClient: GamesSignInClient
    
    private lateinit var auth: FirebaseAuth

    override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    
    firebaseAnalytics = FirebaseAnalytics.getInstance(this)

    // Initialize Play Games SDK
    PlayGamesSdk.initialize(this)
    Log.d(TAG, "Play Games SDK initialized")

    // Initialize other services like Firebase, Mobile Ads
    FirebaseApp.initializeApp(this)
    auth = FirebaseAuth.getInstance()

    
    MobileAds.initialize(this) {}
    FirebaseCrashlytics.getInstance().setCrashlyticsCollectionEnabled(true)
    FirebaseCrashlytics.getInstance().log("MainActivity Loaded Successfully")
    initializeUMP()

      // Initialize BillingClient
        billingClient = BillingClient.newBuilder(this)
            .setListener { billingResult, purchases -> 
                // Handle purchases, if needed
            }
            .enablePendingPurchases() // Required if your app supports purchases for unpurchased products
            .build()
        
        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(billingResult: BillingResult) {
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    // The BillingClient setup is complete, and you can query purchases here.
                }
            }

            override fun onBillingServiceDisconnected() {
                // Try to restart the connection on the next request to Google Play by calling the startConnection() method.
            }
        })

    
    // Correctly initialize Google Play Games Sign-In Client
    gamesSignInClient = PlayGames.getGamesSignInClient(this)
    Log.d(TAG, "Google Play Games Sign-In Client initialized")

  
   

    // Check player authentication
    checkPlayerAuthentication()

    // MethodChannel setup for Flutter communication
    MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
        when (call.method) {
            "signInWithGooglePlayGames" -> signInWithGooglePlayGames()
            "isAuthenticated" -> isAuthenticated(result)
            "signIn" -> signIn(result)
            "requestConsent" -> {
                initializeUMP()
                result.success(null)
            }
            "unlockAchievement" -> {
            val achievementId = call.argument<String>("achievementId")
            if (achievementId != null) {
                unlockAchievement(achievementId)
                result.success(true)
            } else {
                result.error("INVALID_ARGUMENT", "Achievement ID is required", null)
            }
        }

          "retrievePurchasedQuantity" -> {
                    val productId = call.argument<String>("productId")
                    if (productId != null) {
                        retrievePurchasedQuantity(billingClient, productId) { quantity ->
                            result.success(quantity)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Product ID is required", null)
                    }
                }
            else -> result.notImplemented()
        }
    }
 // New authentication channel setup
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, authChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "signUp" -> {
                    val email = call.argument<String>("email")
                    val password = call.argument<String>("password")
                    signUp(email!!, password!!, result)
                }
                "signIn" -> {
                    val email = call.argument<String>("email")
                    val password = call.argument<String>("password")
                    signIn(email!!, password!!, result)
                }
                "signOut" -> {
                    signOut(result)
                }
                else -> result.notImplemented()
            }
        }
    }

  private fun unlockAchievement(achievementId: String) {
    PlayGames.getAchievementsClient(this).unlock(achievementId)
    Log.d(TAG, "Achievement unlocked: $achievementId")
}

  private fun retrievePurchasedQuantity(billingClient: BillingClient, productId: String, callback: (Int) -> Unit) {
        billingClient.queryPurchasesAsync(BillingClient.SkuType.INAPP) { billingResult, purchasesList ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK && purchasesList != null) {
                val purchasedQuantity = purchasesList.count { it.skus.contains(productId) }
                callback(purchasedQuantity)
            } else {
                callback(0)
            }
        }
    }

    

     private fun signUp(email: String, password: String, result: MethodChannel.Result) {
        auth.createUserWithEmailAndPassword(email, password)
            .addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    result.success(true)
                } else {
                    result.error("AUTH_ERROR", task.exception?.message, null)
                }
            }
    }

   private fun signIn(email: String, password: String, result: MethodChannel.Result) {
    auth.signInWithEmailAndPassword(email, password)
        .addOnCompleteListener { task ->
            if (task.isSuccessful) {
                // Once sign-in is successful, get the ID token
                auth.currentUser?.getIdToken(true)?.addOnCompleteListener { idTask ->
                    if (idTask.isSuccessful) {
                        val idToken = idTask.result?.token
                        // Additionally, get the Firebase user ID to use as an accessToken or equivalent
                        val firebaseUserId = auth.currentUser?.uid
                        
                        // Prepare the authentication details including the Firebase user ID
                        val authDetails = hashMapOf(
                            "email" to email,
                            "idToken" to idToken,
                            "accessToken" to firebaseUserId // Using Firebase UID as accessToken
                        )
                        result.success(authDetails)
                    } else {
                        // Handle failure to get ID token
                        result.error("TOKEN_ERROR", "Failed to obtain ID token", null)
                    }
                }
            } else {
                // Handle sign-in failure
                result.error("AUTH_ERROR", task.exception?.message, null)
            }
        }
}


    private fun signOut(result: MethodChannel.Result) {
        auth.signOut()
        result.success(true)
    }

     private fun signIn(result: MethodChannel.Result) {
        gamesSignInClient.signIn().addOnCompleteListener { task ->
            val wasSuccessful = task.isSuccessful
            Log.d(TAG, "signIn: ${task.isSuccessful}")
            result.success(wasSuccessful)

            logLoginEvent()

            if (wasSuccessful) {
                // Retrieve player ID from Google Play Games
                getPlayerId()

                // Initiate Google Sign-In to get the email
                signInWithGoogle()
            } else {
                // Handle sign-in failure
                Log.e(TAG, "Sign-in failed")
            }
        }
    }

     private fun handleSignInResult(completedTask: Task<GoogleSignInAccount>) {
        try {
            val account = completedTask.getResult(ApiException::class.java)
            // Google Sign-In was successful, retrieve the email
            val email = account?.email ?: ""

            // You can now use the email along with the player ID
            Log.d(TAG, "Google Sign-In email: $email")
            // Send this info back to Flutter if needed
        } catch (e: ApiException) {
            Log.e(TAG, "Google Sign-In failed", e)
        }
    }



private fun signInWithGooglePlayGames() {
    gamesSignInClient.signIn().addOnCompleteListener { task ->
        if (task.isSuccessful) {
            // Sign-in success, proceed with getting the player's information or any other operation
            Log.d(TAG, "Google Play Games sign-in successful")
        } else {
            // Sign-in failed, log the error
            Log.e(TAG, "Google Play Games sign-in failed", task.exception)
        }
    }
}


    




    private fun isAuthenticated(result: MethodChannel.Result) {
        Log.d(TAG, "Checking authentication status with Google Play Games")
        gamesSignInClient.isAuthenticated().addOnCompleteListener { task ->
            val isAuthenticated = task.isSuccessful && task.result?.isAuthenticated == true
            Log.d(TAG, "Authentication status: $isAuthenticated")
            result.success(isAuthenticated)
        }
    }


   

    private fun signInWithGoogle() {
        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestEmail()
            .build()

        val googleSignInClient = GoogleSignIn.getClient(this, gso)
        val signInIntent = googleSignInClient.signInIntent
        startActivityForResult(signInIntent, GOOGLE_SIGN_IN)
    }

    // Constant for Google Sign-In request code
    companion object {
        private const val GOOGLE_SIGN_IN = 1001
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == GOOGLE_SIGN_IN) {
            val task = GoogleSignIn.getSignedInAccountFromIntent(data)
            handleSignInResult(task)
        }
    }

   

    private fun getPlayerInfo() {
    val playersClient = PlayGames.getPlayersClient(this)

    playersClient.currentPlayer.addOnSuccessListener { player ->
        val playerId = player.playerId
        Log.d(TAG, "Player ID: $playerId")

        // Retrieve player email using a different approach
        val account = GoogleSignIn.getLastSignedInAccount(this)
        val playerEmail = account?.email // Email may be null if not consented

        if (playerEmail != null) {
            Log.d(TAG, "Player Email: $playerEmail")
        } else {
            Log.e(TAG, "Player Email is null")
        }
    }.addOnFailureListener { e ->
        Log.e(TAG, "Failed to get player info", e)
    }
}

    private fun logLoginEvent() {
        val bundle = Bundle()
        firebaseAnalytics.logEvent(FirebaseAnalytics.Event.LOGIN, bundle)
        Log.e(TAG, "Firebase log callback sent properly")
    }

    private fun checkPlayerAuthentication() {
        gamesSignInClient.isAuthenticated().addOnCompleteListener { task ->
            if (task.isSuccessful && task.result?.isAuthenticated == true) {
                // User is signed in, show player info
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
