package com.example.architecture_scan_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.content.SharedPreferences

class ScanReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) {
            Log.e("ScanReceiver", "❌ Context or Intent is NULL")
            return
        }

        Log.d("ScanReceiver", "📟 Scanner Event Received")
        Log.d("ScanReceiver", "Action: ${intent.action}")
        
        // Xử lý dữ liệu từ Intent
        val scanData = extractScanData(intent)
        
        if (scanData != null) {
            sendToMainActivity(context, scanData)
        } else {
            Log.w("ScanReceiver", "❌ No valid scan data found")
        }
    }

    private fun extractScanData(intent: Intent): String? {
        // Log chi tiết về Bundle
        intent.extras?.let { bundle ->
            Log.d("ScanReceiver", "📦 Bundle contains ${bundle.size()} items")
            bundle.keySet()?.forEach { key ->
                when (val value = bundle.getString(key)) {
                    is String -> Log.d("ScanReceiver", "String: $key = $value")
                    else -> Log.d("ScanReceiver", "Other: $key = $value")
                }
            }
        }

        // Thử lấy dữ liệu theo thứ tự ưu tiên
        return when {
            // Kiểm tra ByteArray trước
            intent.hasExtra("barcode_values") -> {
                intent.getByteArrayExtra("barcode_values")?.let { 
                    String(it).also { data ->
                        Log.d("ScanReceiver", "📤 Found barcode_values: $data")
                    }
                }
            }
            // Kiểm tra Bundle data
            intent.hasExtra("data_bundle") -> {
                intent.getBundleExtra("data_bundle")?.getString("barcode_data")?.also { data ->
                    Log.d("ScanReceiver", "📤 Found in data_bundle: $data")
                }
            }
            // Kiểm tra các String extras phổ biến
            else -> {
                val commonKeys = listOf(
                    "barcode_string",
                    "urovo.rcv.message",
                    "scannerdata",
                    "data",
                    "decode_data",
                    "barcode",
                    "data_string",
                    "scan_result",
                    "SCAN_BARCODE1"
                )

                commonKeys.firstOrNull { key ->
                    intent.getStringExtra(key) != null
                }?.let { key ->
                    intent.getStringExtra(key)?.also { data ->
                        Log.d("ScanReceiver", "📤 Found data in $key: $data")
                    }
                }
            }
        }
    }

    private fun sendToMainActivity(context: Context, scanData: String) {
        try {
            val mainIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("scan_data", scanData)
            }
            context.startActivity(mainIntent)
            Log.d("ScanReceiver", "✅ Data sent to MainActivity: $scanData")
        } catch (e: Exception) {
            Log.e("ScanReceiver", "❌ Error sending to MainActivity: ${e.message}")
        }
    }
}