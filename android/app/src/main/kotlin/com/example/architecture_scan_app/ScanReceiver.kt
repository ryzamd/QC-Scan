package com.example.architecture_scan_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.content.SharedPreferences

class ScanReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) {
            Log.e("ScanReceiver", "Context or Intent is NULL")
            return
        }

        // Log tất cả thông tin về intent nhận được
        Log.d("ScanReceiver", "🚨 HARDWARE BUTTON PRESSED 🚨")
        Log.d("ScanReceiver", "Action: ${intent.action}")
        Log.d("ScanReceiver", "Category: ${intent.categories}")
        Log.d("ScanReceiver", "Data: ${intent.data}")
        
        // Log tất cả extras
        if (intent.extras != null) {
            Log.d("ScanReceiver", "Intent extras count: ${intent.extras?.size()}")
            intent.extras?.keySet()?.forEach { key ->
                val value = when (val v = intent.extras?.get(key)) {
                    is String -> v
                    is ByteArray -> "ByteArray(${v.size})"
                    else -> v?.toString() ?: "null"
                }
                Log.d("ScanReceiver", "👉 Extra: $key = $value")
            }
        } else {
            Log.d("ScanReceiver", "No extras in intent")
        }

        // Thử tất cả các key có thể
        val scanData = intent.getStringExtra("com.ubx.datawedge.data_string")
            ?: intent.getStringExtra("barcode_string")
            ?: intent.getStringExtra("urovo.rcv.message")
            ?: intent.getStringExtra("scannerdata")
            ?: intent.getStringExtra("data")
            ?: intent.getStringExtra("decode_data")
            ?: intent.getStringExtra("barcode")
            ?: intent.getStringExtra("data_string")
            ?: intent.getStringExtra("scan_result")  // Thêm key phổ biến cho UROVO
            ?: intent.getStringExtra("SCAN_BARCODE1")  // Thêm key phổ biến cho UROVO
            ?: intent.getByteArrayExtra("barcode_values")?.let { String(it) }  // Thử lấy dữ liệu dạng byte array
            ?: "No Scan Data Found"

        Log.d("ScanReceiver", "Final data extracted: $scanData")

        if (scanData == "No Scan Data Found") {
            Log.w("ScanReceiver", "❌ No scan data found in any known key")
            return
        }

        Log.d("ScanReceiver", "✅ Valid Scanned Data: $scanData")

        // Gửi dữ liệu đã quét đến MainActivity
        val scanIntent = Intent(context, MainActivity::class.java)
        scanIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        scanIntent.putExtra("scan_data", scanData)
        context.startActivity(scanIntent)

        Log.d("ScanReceiver", "📡 Intent Sent to MainActivity with data: $scanData")
    }
}