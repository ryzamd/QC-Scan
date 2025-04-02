package com.example.architecture_scan_app

import android.content.Context
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.Log

class MainActivity : FlutterActivity() {
    private val EVENT_CHANNEL = "com.example.architecture_scan_app/scanner"
    private val BACK_BUTTON_CHANNEL = "com.example.architecture_scan_app/back_button"
    private val METHOD_CHANNEL = "com.example.architecture_scan_app"

    private var eventSink: EventChannel.EventSink? = null
    private var backButtonEventSink: EventChannel.EventSink? = null
    private val handler = Handler(Looper.getMainLooper())
    
    // Broadcast receiver for scanner events
    private val scannerReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            Log.d("MainActivity", "Direct BroadcastReceiver triggered in MainActivity with action: ${intent?.action}")
            if (intent == null) return
            
            // Log all extras in detail
            intent.extras?.let { bundle ->
                Log.d("MainActivity", "Bundle contains ${bundle.size()} items")
                bundle.keySet()?.forEach { key ->
                    when {
                        bundle.getString(key) != null -> Log.d("MainActivity", "String: $key = ${bundle.getString(key)}")
                        bundle.getByteArray(key) != null -> Log.d("MainActivity", "ByteArray: $key = ${String(bundle.getByteArray(key)!!)}")
                        else -> Log.d("MainActivity", "Other: $key = ${bundle.getString(key)}")
                    }
                }
            }
            
            // Try to get scan data from various sources
            val scanData = when {
                // Check for byte array data first
                intent.hasExtra("barcode_values") -> {
                    intent.getByteArrayExtra("barcode_values")?.let { String(it) }
                }
                // Check for bundle data
                intent.hasExtra("data_bundle") -> {
                    intent.getBundleExtra("data_bundle")?.getString("barcode_data")
                }
                // Check for common string extras
                else -> {
                    intent.getStringExtra("scan_data")
                        ?: intent.getStringExtra("barcode_string")
                        ?: intent.getStringExtra("urovo.rcv.message")
                        ?: intent.getStringExtra("scannerdata")
                        ?: intent.getStringExtra("data")
                        ?: intent.getStringExtra("decode_data")
                        ?: intent.getStringExtra("barcode")
                        ?: intent.getStringExtra("data_string")
                        ?: intent.getStringExtra("scan_result")
                        ?: intent.getStringExtra("SCAN_BARCODE1")
                        //?: intent.getStringExtra("com.ubx.datawedge.data_string")
                }
            }
                
            if (scanData != null) {
                Log.d("MainActivity", "📱 Scan data found: $scanData")
                sendScanDataToFlutter(scanData)
            } else {
                Log.e("MainActivity", "❌ No scan data found in intent")
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Register the broadcast receiver
        val intentFilter = IntentFilter().apply {
            addAction("android.intent.action.DECODE_DATA")
            addAction("scanner.action")
            addAction("android.intent.ACTION_DECODE_DATA")
            addAction("com.android.server.scannerservice.broadcast")
            addAction("urovo.rcv.message.ACTION")
            // Add more actions as needed for different scanner devices
        }
        registerReceiver(scannerReceiver, intentFilter)
        
        Log.d("MainActivity", "🚀 MainActivity created and receiver registered")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(scannerReceiver)
        } catch (e: Exception) {
            Log.e("MainActivity", "Error unregistering receiver: ${e.message}")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up EventChannel for streaming scan data
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    Log.d("MainActivity", "📡 EventChannel Listener Started")
                    
                    // Send test data to verify channel is working
                    // handler.postDelayed({
                    //     sendScanDataToFlutter("TEST_CHANNEL_DATA")
                    // }, 3000)
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    Log.d("MainActivity", "📡 EventChannel Listener Stopped")
                }
            })
            
        // Set up MethodChannel for handling method calls from Flutter
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "testScanEvent" -> {
                        Log.d("MainActivity", "testScanEvent method called from Flutter")
                        // sendScanDataToFlutter("TEST_METHOD_CHANNEL")
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        
        // Thiết lập EventChannel cho back button
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, BACK_BUTTON_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    backButtonEventSink = events
                    Log.d("MainActivity", "🔙 Back Button EventChannel Listener Started")
                }

                override fun onCancel(arguments: Any?) {
                    backButtonEventSink = null
                    Log.d("MainActivity", "🔙 Back Button EventChannel Listener Stopped")
                }
            })
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d("MainActivity", "🔄 onNewIntent Called with action: ${intent.action}")
        
        // Log all extras
        if (intent.extras != null) {
            intent.extras?.keySet()?.forEach { key ->
                Log.d("MainActivity", "👉 Extra in onNewIntent: $key = ${intent.getStringExtra(key)}")
            }
        } else {
            Log.d("MainActivity", "No extras in onNewIntent")
        }
        
        val scanData = intent.getStringExtra("scan_data")
        if (scanData != null) {
            Log.d("MainActivity", "📥 Received scan_data: $scanData")
            sendScanDataToFlutter(scanData)
        } else {
            Log.e("MainActivity", "❌ No scan_data in Intent from onNewIntent")
        }
    }

    fun sendScanDataToFlutter(scanData: String) {
        if (eventSink == null) {
            Log.e("MainActivity", "❌ EventSink is NULL, cannot send data!")
            return
        }

        handler.post {
            try {
                Log.d("MainActivity", "⏳ Attempting to send data: $scanData")
                eventSink?.success(scanData)
                Log.d("MainActivity", "✅ Data successfully sent to Flutter: $scanData")
            } catch (e: Exception) {
                Log.e("MainActivity", "❌ Error sending data to Flutter: ${e.message}")
                e.printStackTrace()
            }
        }
    }

    @Override
    public override fun onBackPressed() {
        if (backButtonEventSink != null) {
            handler.post {
                try {
                    Log.d("MainActivity", "🔙 Back button pressed, sending event to Flutter")
                    backButtonEventSink?.success("BACK_PRESSED")
                } catch (e: Exception) {
                    Log.e("MainActivity", "Error sending back button event: ${e.message}")
                    super.onBackPressed()
                }
            }
        } else {
            Log.d("MainActivity", "🔙 Back button pressed, but no event sink available")
            super.onBackPressed()
        }
    }
}