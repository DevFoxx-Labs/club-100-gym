package com.club100gym.club_100_gym_app

import android.content.Context
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Lets phone fields pre-select the admin's country code. SIM/network
        // country ISO needs no permission (unlike location), and is more
        // reliable than locale, which is often en_US regardless of country.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "gymyardhq/device_region")
            .setMethodCallHandler { call, result ->
                if (call.method == "getCountryCode") {
                    result.success(deviceCountryCode())
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun deviceCountryCode(): String? {
        val tm = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
        val candidates = listOf(
            runCatching { tm?.simCountryIso }.getOrNull(),
            runCatching { tm?.networkCountryIso }.getOrNull(),
            Locale.getDefault().country,
        )
        return candidates.firstOrNull { !it.isNullOrBlank() && it.length == 2 }?.uppercase(Locale.ROOT)
    }
}
