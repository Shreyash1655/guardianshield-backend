package com.example.safenest_frontend

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var methodChannel: MethodChannel? = null
    private var initialUrl: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initialUrl = if (intent?.action == Intent.ACTION_VIEW) intent?.dataString else null
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "safenest/link_guard")
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialLink" -> {
                    result.success(initialUrl)
                    initialUrl = null
                }
                "openInBrowser" -> result.success(openInBrowser(call.arguments as? String))
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.action == Intent.ACTION_VIEW) {
            val url = intent.dataString
            if (url != null) methodChannel?.invokeMethod("incomingLink", url)
        }
    }

    private fun openInBrowser(url: String?): Boolean {
        if (url == null) return false
        val probe = Intent(Intent.ACTION_VIEW, Uri.parse("https://example.com"))
        val candidates = packageManager.queryIntentActivities(probe, 0)
            .map { it.activityInfo.packageName }
            .filter { it != packageName }
        val target = candidates.firstOrNull { it == "com.android.chrome" }
            ?: candidates.firstOrNull() ?: return false
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        intent.setPackage(target)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        return true
    }
}