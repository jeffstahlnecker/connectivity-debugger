package com.example.connectivity_debugger

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.os.Bundle
import android.content.Context
import android.telephony.SubscriptionInfo
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import android.Manifest
import android.content.pm.PackageManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.connectivity_debugger/sim_info"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "getSimInfo") {
                if (ActivityCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED) {
                    result.error("PERMISSION_DENIED", "READ_PHONE_STATE permission not granted", null)
                    return@setMethodCallHandler
                }
                val simInfo = getSimInfo()
                result.success(simInfo)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getSimInfo(): Map<String, Any?> {
        val simInfo = mutableMapOf<String, Any?>()
        val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        val subscriptionManager = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager

        val activeSims = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            subscriptionManager.activeSubscriptionInfoList
        } else {
            null
        }

        if (activeSims != null && activeSims.isNotEmpty()) {
            val sim = activeSims[0]
            simInfo["carrierName"] = sim.carrierName?.toString()
            simInfo["countryCode"] = sim.countryIso?.toString()
            simInfo["iccid"] = sim.iccId
            simInfo["isDataRoaming"] = sim.dataRoaming == 1
            simInfo["isSimInserted"] = true
            simInfo["slotIndex"] = sim.simSlotIndex
            simInfo["number"] = sim.number
        } else {
            simInfo["isSimInserted"] = false
        }

        // Add more fields as needed
        return simInfo
    }
}
