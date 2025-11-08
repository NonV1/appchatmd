package com.example.chatmd_v1

import android.os.Bundle
import android.text.method.LinkMovementMethod
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

/**
 * Minimal native screen that Health Connect can open when the user taps the
 * privacy-policy link inside its permission UI. Update the copy/URL to match
 * the real privacy policy before releasing the app.
 */
class PrivacyPolicyActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_privacy_policy)

        supportActionBar?.title = getString(R.string.privacy_policy_title)

        // Allow the embedded link to be clickable.
        findViewById<TextView>(R.id.privacy_policy_body).movementMethod =
            LinkMovementMethod.getInstance()
    }

    @Suppress("UNUSED_PARAMETER")
    fun onCloseClicked(view: android.view.View) {
        finish()
    }
}
