package vn.mttt.sportshub

import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Base64
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        printKeyHash()
    }

    private fun printKeyHash() {
        try {
            val info = packageManager.getPackageInfo(
                packageName,
                PackageManager.GET_SIGNATURES
            )
            for (signature in info.signatures ?: emptyArray()) {
                val md = MessageDigest.getInstance("SHA")
                md.update(signature.toByteArray())
                val keyHash = Base64.encodeToString(md.digest(), Base64.DEFAULT)
                Log.d("KeyHash", "KeyHash: $keyHash")
            }
        } catch (e: Exception) {
            Log.e("KeyHash", "Error getting key hash", e)
        }
    }
}
