package com.example.safenest_frontend

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

class SmsNotificationListener : NotificationListenerService() {
    private val tag = "SmsNotificationListener"
    private var lastKey = ""
    private var lastTime = 0L

    data class Verdict(val score: Int, val type: String, val reasons: List<String>)

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(tag, "SafeNest listener CONNECTED")
    }

    private fun channelOf(pkg: String): String? = when {
        pkg == "com.android.shell" -> "sms" // demo/testing only
        pkg.contains("whatsapp") -> "whatsapp"
        pkg.contains("telegram") -> "chat"
        pkg.contains("com.google.android.gm") || pkg.contains("outlook") ||
                pkg.contains("yahoo") || pkg.contains("mail") -> "email"
        pkg.contains("messaging") || pkg.contains("messages") ||
                pkg.contains("sms") || pkg.contains("mms") -> "sms"
        else -> null
    }

    private fun readText(n: Notification): String {
        val e = n.extras ?: return ""
        val parts = mutableListOf<String>()
        listOf(
            Notification.EXTRA_TITLE, Notification.EXTRA_TEXT, Notification.EXTRA_BIG_TEXT,
            Notification.EXTRA_SUB_TEXT, Notification.EXTRA_SUMMARY_TEXT
        ).forEach { k -> e.getCharSequence(k)?.toString()?.let { parts.add(it) } }
        e.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)?.forEach { parts.add(it.toString()) }
        return parts.filter { it.isNotBlank() }.distinct().joinToString("\n")
    }

    private fun assess(text: String): Verdict {
        val t = text.lowercase()
        var s = 0
        val why = mutableListOf<String>()
        fun hit(p: Int, reason: String, rx: String) {
            if (Regex(rx).containsMatchIn(t)) { s += p; why.add(reason) }
        }
        hit(30, "Asks for an OTP, PIN or CVV. Banks never do this.", """\botp\b|\bpin\b|\bcvv\b|verification code""")
        hit(25, "Claims your account is blocked or suspended.", """blocked|suspended|deactivated|frozen""")
        hit(20, "Asks you to verify KYC or identity.", """\bkyc\b|verify your (account|identity)|update (your )?(pan|aadhaar)""")
        hit(20, "Promises a prize or lottery win.", """lottery|you (have )?won|prize|reward|lucky""")
        hit(20, "Threatens arrest or legal action.", """arrest|police|\bcbi\b|legal action|warrant""")
        hit(20, "Asks for money or a fee.", """send money|transfer|gift card|processing fee|pay (rs|inr|₹)""")
        hit(20, "Offers easy money or guaranteed returns.", """work from home|earn \d+|guaranteed (profit|returns)|\binvest""")
        hit(15, "Creates false urgency.", """urgent|immediately|within \d+ (hours|minutes)|last chance|act now""")
        hit(15, "Contains a link.", """https?://|www\.|bit\.ly""")
        hit(10, "Link uses a hyphenated look-alike address.", """https?://[^\s]*-[^\s]*""")
        s = minOf(s, 100)

        val type = when {
            Regex("""\botp\b|\bpin\b|\bcvv\b""").containsMatchIn(t) -> "OTP"
            Regex("""arrest|police|\bcbi\b|warrant""").containsMatchIn(t) -> "Impersonation"
            Regex("""lottery|won|prize|reward""").containsMatchIn(t) -> "Lottery/Prize"
            Regex("""invest|work from home|earn \d+""").containsMatchIn(t) -> "Investment/Job"
            Regex("""parcel|courier|customs""").containsMatchIn(t) -> "Delivery"
            Regex("""kyc|bank|account|blocked|suspended""").containsMatchIn(t) -> "Bank/KYC"
            Regex("""https?://|www\.""").containsMatchIn(t) -> "Phishing link"
            else -> "Other"
        }
        return Verdict(s, type, why)
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        super.onNotificationPosted(sbn)
        if (sbn.packageName == packageName) return
        val channel = channelOf(sbn.packageName.lowercase()) ?: return
        val text = readText(sbn.notification)
        if (text.isBlank()) return

        val key = text.hashCode().toString()
        val now = System.currentTimeMillis()
        if (key == lastKey && now - lastTime < 60000) return
        lastKey = key; lastTime = now

        val t0 = System.nanoTime()
        val v = assess(text)
        val micros = (System.nanoTime() - t0) / 1000

        val flagged = v.score >= 40
        record(channel, text, v, micros, flagged)
        Log.d(tag, "scanned channel=$channel score=${v.score} type=${v.type} flagged=$flagged ${micros}us")
        if (flagged) showWarning(channel, v)
    }

    private fun record(channel: String, text: String, v: Verdict, micros: Long, flagged: Boolean) {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val ed = prefs.edit()
            ed.putLong("flutter.scan_count", prefs.getLong("flutter.scan_count", 0L) + 1)
            ed.putLong("flutter.latency_total_us", prefs.getLong("flutter.latency_total_us", 0L) + micros)
            if (flagged) {
                val old = JSONArray(prefs.getString("flutter.scam_log", "[]"))
                val o = JSONObject()
                o.put("channel", channel); o.put("type", v.type); o.put("content", text)
                o.put("score", v.score); o.put("reasons", JSONArray(v.reasons))
                o.put("seen", false)
                o.put("time", java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", java.util.Locale.US).format(java.util.Date()))
                val out = JSONArray(); out.put(o)
                for (i in 0 until minOf(old.length(), 199)) out.put(old.get(i))
                ed.putString("flutter.scam_log", out.toString())
            }
            ed.apply()
        } catch (e: Exception) { Log.e(tag, "save failed", e) }
    }

    private fun showWarning(channel: String, v: Verdict) {
        val channelId = "safenest_alert_v2"
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(channelId, "SafeNest Scam Alerts", NotificationManager.IMPORTANCE_HIGH)
            ch.enableVibration(true)
            ch.vibrationPattern = longArrayOf(0, 500, 200, 500)
            ch.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            manager.createNotificationChannel(ch)
        }
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pi = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val body = "${channel.uppercase()} scam (${v.type}), risk ${v.score}/100. Do not click links or share OTPs."
        val n = Notification.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("SafeNest ALERT: Possible scam!")
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setColor(0xFFC93426.toInt())
            .setContentIntent(pi)
            .setFullScreenIntent(pi, true)
            .setAutoCancel(true)
            .build()
        manager.notify((System.currentTimeMillis() % 100000).toInt(), n)
    }
}