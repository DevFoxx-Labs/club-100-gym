package com.club100gym.club_100_gym_app

import android.app.Application
import android.os.Looper
import android.util.Log

/**
 * Some native plugins (e.g. flutter_contacts, when the device's default account
 * for new contacts is a cloud account) can throw from a background coroutine
 * thread. Such exceptions bypass Flutter's MethodChannel result callback
 * entirely and reach the JVM's default uncaught-exception handler, which kills
 * the whole process even though the failure is isolated to that one background
 * task and Dart-side try/catch around the plugin call never runs. Contact sync
 * is already treated as best-effort everywhere it's used (see
 * ContactSyncService), so background-thread crashes are logged instead of
 * taking the app down; the main thread keeps the default (fatal) behavior.
 */
class App : Application() {
    override fun onCreate() {
        super.onCreate()
        val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            if (thread == Looper.getMainLooper().thread) {
                defaultHandler?.uncaughtException(thread, throwable)
            } else {
                Log.e("ClubGymApp", "Ignored uncaught exception on background thread '${thread.name}'", throwable)
            }
        }
    }
}
