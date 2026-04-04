package com.example.expense_tracker_flutter

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.ArrayList
import java.util.HashMap

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.expense_tracker_flutter/sms"
    private val SMS_PERMISSION_CODE = 101
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSms" -> {
                    val start = call.argument<Long>("start")
                    val end = call.argument<Long>("end")
                    if (start != null && end != null) {
                        if (checkPermission()) {
                            val messages = getSms(start, end)
                            result.success(messages)
                        } else {
                            result.error("PERMISSION_DENIED", "SMS permission not granted", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "Start and end timestamps are required", null)
                    }
                }
                "requestPermission" -> {
                    if (checkPermission()) {
                        result.success(true)
                    } else {
                        pendingResult = result
                        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.READ_SMS), SMS_PERMISSION_CODE)
                    }
                }
                "checkPermission" -> {
                    result.success(checkPermission())
                }
                "saveUid" -> {
                    val uid = call.argument<String>("uid")
                    if (uid != null) {
                        val prefs = getSharedPreferences("AppPrefs", Context.MODE_PRIVATE)
                        prefs.edit().putString("uid", uid).apply()
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENTS", "UID is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun checkPermission(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == SMS_PERMISSION_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                pendingResult?.success(true)
            } else {
                pendingResult?.success(false)
            }
            pendingResult = null
        }
    }

    private fun getSms(start: Long, end: Long): List<Map<String, Any>> {
        val messages = ArrayList<Map<String, Any>>()
        val uri = Uri.parse("content://sms/inbox")
        val projection = arrayOf("_id", "address", "body", "date")
        val selection = "date >= ? AND date <= ?"
        val selectionArgs = arrayOf(start.toString(), end.toString())
        val sortOrder = "date DESC"

        val cursor: Cursor? = contentResolver.query(uri, projection, selection, selectionArgs, sortOrder)

        cursor?.use {
            val addressIndex = it.getColumnIndex("address")
            val bodyIndex = it.getColumnIndex("body")
            val dateIndex = it.getColumnIndex("date")

            while (it.moveToNext()) {
                val message = HashMap<String, Any>()
                message["address"] = it.getString(addressIndex) ?: ""
                message["body"] = it.getString(bodyIndex) ?: ""
                message["date"] = it.getLong(dateIndex)
                messages.add(message)
            }
        }
        return messages
    }
}
