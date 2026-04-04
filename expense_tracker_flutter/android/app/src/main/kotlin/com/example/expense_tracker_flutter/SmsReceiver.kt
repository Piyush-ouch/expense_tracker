package com.example.expense_tracker_flutter

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FirebaseFirestore
import java.util.Date

import kotlin.math.roundToInt
import kotlin.text.RegexOption

class SmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val pendingResult = goAsync()
            
            try {
                val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
                val prefs = context.getSharedPreferences("AppPrefs", Context.MODE_PRIVATE)
                val uid = prefs.getString("uid", null)

                if (uid == null) {
                    Log.d("SmsReceiver", "No UID found, skipping")
                    pendingResult.finish()
                    return
                }

                val db = FirebaseFirestore.getInstance()
                var saveStarted = false

                for (sms in messages) {
                    val body = sms.messageBody.lowercase()
                    val sender = sms.originatingAddress ?: ""
                    val date = Date(sms.timestampMillis)

                    if (isBankingSms(body, sender)) {
                        val amount = extractAmount(body)
                        if (amount != null && amount > 0) {
                            val type = getTransactionType(body)
                            if (type != null) {
                                val merchant = extractMerchant(body)
                                val category = autoCategorize(merchant, body)
                                
                                saveTransaction(db, uid, amount, type, merchant, category, date, pendingResult)
                                saveStarted = true
                                // Only process one transaction per broadcast to avoid race conditions with pendingResult
                                break 
                            }
                        }
                    }
                }

                if (!saveStarted) {
                    pendingResult.finish()
                }
            } catch (e: Exception) {
                Log.e("SmsReceiver", "Error processing SMS", e)
                pendingResult.finish()
            }
        }
    }

    private fun saveTransaction(
        db: FirebaseFirestore, 
        uid: String, 
        amount: Double, 
        type: String, 
        merchant: String, 
        category: String, 
        date: Date,
        pendingResult: BroadcastReceiver.PendingResult
    ) {
        val amountCents = (amount * 100).roundToInt()
        
        val data = hashMapOf(
            "amount" to amountCents,
            "base_amount" to amountCents,
            "original_currency" to "INR",
            "date" to Timestamp(date),
            "created_at" to com.google.firebase.firestore.FieldValue.serverTimestamp()
        )

        val collection = if (type == "debit") "expenses" else "incomes"
        
        if (type == "debit") {
            data["category"] = category
            data["description"] = merchant
        } else {
            data["source"] = merchant
        }

        db.collection("users").document(uid).collection(collection)
            .add(data)
            .addOnSuccessListener { 
                Log.d("SmsReceiver", "Transaction saved successfully") 
                pendingResult.finish()
            }
            .addOnFailureListener { e -> 
                Log.e("SmsReceiver", "Error saving transaction", e) 
                pendingResult.finish()
            }
    }

    // --- Parsing Logic ---

    // --- Parsing Logic ---

    private fun isBankingSms(body: String, sender: String): Boolean {
        // 1. Check for Promotional Content (Immediate Rejection)
        if (isPromotional(body)) return false

        // 2. User's Debit Keywords
        val debitKeywords = listOf(
            "debited","Dr","paid", "sent", "deducted", "withdrawn",
            "purchased", "spent", "upi payment", "transfer",
            "imps", "neft", "pos", "autopay", "mandate", "charge"
        )
        // 3. User's Credit Keywords
        val creditKeywords = listOf(
            "credited","Cr","received", "deposited", "refund", "cashback",
            "interest", "neft", "imps", "reward", "reversal"
        )
        
        // 4. Banking Senders
        val bankingSenders = listOf(
            "paytm", "phonepe", "gpay", "bhim", "sbi", "hdfc",
            "icici", "axis", "kotak", "pnb", "bob", "canara"
        )

        // Check keywords with word boundaries to avoid partial matches (e.g. "Recharge" matching "charge")
        if (containsWord(body, debitKeywords)) return true
        if (containsWord(body, creditKeywords)) return true
        if (bankingSenders.any { sender.lowercase().contains(it) }) return true
        
        return false
    }

    private fun isPromotional(body: String): Boolean {
        val promoKeywords = listOf(
            "recharge now", "plan", "offer", "benefits", "validity", 
            "data", "quota", "expired", "click", "link", "http", "www",
            "otp", "code", "verification", "login", "win", "lucky"
        )
        return promoKeywords.any { body.contains(it) }
    }

    private fun containsWord(text: String, words: List<String>): Boolean {
        for (word in words) {
            // Regex for word boundary: \bWORD\b
            // Using raw string for regex pattern
            if (Regex("""\b$word\b""", RegexOption.IGNORE_CASE).containsMatchIn(text)) {
                return true
            }
        }
        return false
    }

    private fun getTransactionType(body: String): String? {
        val debitKeywords = listOf(
            "debited", "paid", "sent", "deducted", "withdrawn",
            "purchased", "spent", "upi payment", "transfer",
            "imps", "neft", "pos", "autopay", "mandate", "charge"
        )
        val creditKeywords = listOf(
            "credited", "received", "deposited", "refund", "cashback",
            "interest", "neft", "imps", "reward", "reversal"
        )

        val isDebit = containsWord(body, debitKeywords)
        val isCredit = containsWord(body, creditKeywords)

        if (isDebit && !isCredit) return "debit"
        if (isCredit && !isDebit) return "credit"
        if (isDebit && isCredit) return "credit" // Fallback priority to credit

        return null
    }

    private fun extractAmount(body: String): Double? {
        val patterns = listOf(
            Regex("""rs\.?\s*([\d,]+\.?\d*)""", RegexOption.IGNORE_CASE),
            Regex("""inr\.?\s*([\d,]+\.?\d*)""", RegexOption.IGNORE_CASE),
            Regex("""₹\s*([\d,]+\.?\d*)""", RegexOption.IGNORE_CASE),
            Regex("""amount\s*[:=]?\s*(?:r \.?|inr|₹)?\s*([\d,]+\.?\d*)""", RegexOption.IGNORE_CASE),
            Regex("""sum\s*([\d,]+\.?\d*)""", RegexOption.IGNORE_CASE),
            Regex("""paid\s*([\d,]+\.?\d*)""", RegexOption.IGNORE_CASE)
        )

        for (pattern in patterns) {
            val matchResult = pattern.find(body)
            if (matchResult != null) {
                val amountStr = matchResult.groupValues[1].replace(",", "")
                return amountStr.toDoubleOrNull()
            }
        }
        return null
    }

    private fun extractMerchant(body: String): String {
        val patterns = listOf(
            Regex("""to vpa ([\w@._-]+)""", RegexOption.IGNORE_CASE),
            Regex("""by ([a-zA-Z0-9@._-]+)""", RegexOption.IGNORE_CASE),
            Regex("""at ([a-zA-Z\s&]+)""", RegexOption.IGNORE_CASE),
            Regex("""to ([a-zA-Z\s&]+)""", RegexOption.IGNORE_CASE)
        )

        for (pattern in patterns) {
            val matchResult = pattern.find(body)
            if (matchResult != null) {
                var merchant = matchResult.groupValues[1]
                merchant = merchant.trim()
                
                // Clean up UPI IDs if captured
                if (merchant.contains("@")) {
                    merchant = merchant.split("@")[0]
                }
                
                return if (merchant.isNotEmpty()) merchant else "Unknown"
            }
        }
        return "Unknown"
    }

    private fun autoCategorize(merchant: String, body: String): String {
        val m = merchant.lowercase()
        val b = body.lowercase()

        // User's Category Mapping
        val map = mapOf(
            "zomato" to "Food & Drinks",
            "swiggy" to "Food & Drinks",
            "dominos" to "Food & Drinks",
            "kfc" to "Food & Drinks",
            "mcd" to "Food & Drinks",
            "restaurant" to "Food & Drinks",
            
            "amazon" to "Shopping",
            "flipkart" to "Shopping",
            "myntra" to "Shopping",
            "meesho" to "Shopping",
            "ajio" to "Shopping",
            
            "uber" to "Transport",
            "ola" to "Transport",
            "rapido" to "Transport",
            "irctc" to "Transport",
            "makemytrip" to "Transport",
            
            "netflix" to "Entertainment",
            "youtube" to "Entertainment",
            "spotify" to "Entertainment",
            "bookmyshow" to "Entertainment",
            
            "jio" to "Bills",
            "airtel" to "Bills",
            "vi" to "Bills",
            "bsnl" to "Bills",
            "electricity" to "Bills",
            "gas" to "Bills",
            "broadband" to "Bills"
        )

        for ((key, value) in map) {
            if (m.contains(key) || b.contains(key)) {
                return value
            }
        }

        return "Other"
    }

    private fun containsAny(text: String, keywords: List<String>): Boolean {
        return keywords.any { text.contains(it) }
    }
}
