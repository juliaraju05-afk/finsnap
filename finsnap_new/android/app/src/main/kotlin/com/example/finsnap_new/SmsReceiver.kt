package com.example.finsnap_new

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("SmsReceiver", "🔥 onReceive called! action=${intent.action}")

        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            Log.d("SmsReceiver", "📨 Messages count: ${messages?.size}")

            for (msg in messages) {
                val sender = msg.originatingAddress ?: ""
                val body = msg.messageBody ?: ""

                Log.d("SmsReceiver", "📩 FROM: $sender | BODY: $body")

                MainActivity.channel?.invokeMethod("onSmsReceived", mapOf(
                    "sender" to sender,
                    "body" to body
                ))
            }
        }
    }
}