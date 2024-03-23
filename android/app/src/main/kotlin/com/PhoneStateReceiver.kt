package com.gg.zmoney

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.util.Log

class PhoneStateReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        val state = intent?.getStringExtra(TelephonyManager.EXTRA_STATE)
        when (state) {
            TelephonyManager.EXTRA_STATE_RINGING -> Log.d("PhoneStateReceiver", "CALL_STATE_RINGING")
            TelephonyManager.EXTRA_STATE_OFFHOOK -> Log.d("PhoneStateReceiver", "CALL_STATE_OFFHOOK")
            TelephonyManager.EXTRA_STATE_IDLE -> Log.d("PhoneStateReceiver", "CALL_STATE_IDLE")
            else -> Log.d("PhoneStateReceiver", "Unknown Phone State: $state")
        }
    }
}
