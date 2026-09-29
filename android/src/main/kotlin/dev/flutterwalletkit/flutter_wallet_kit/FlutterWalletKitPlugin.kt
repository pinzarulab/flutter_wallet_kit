package dev.flutterwalletkit.flutter_wallet_kit

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.view.LayoutInflater
import android.view.View
import com.google.android.gms.pay.Pay
import com.google.android.gms.pay.PayApiAvailabilityStatus
import com.google.android.gms.pay.PayClient
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class FlutterWalletKitPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    ActivityResultListener {
    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: Context
    private lateinit var payClient: PayClient
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingResult: Result? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        payClient = Pay.getClient(applicationContext)
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_wallet_kit")
        channel.setMethodCallHandler(this)
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "flutter_wallet_kit/google_wallet_button",
            GoogleWalletButtonFactory(flutterPluginBinding.binaryMessenger),
        )
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "isWalletSupported" -> isWalletSupported(result)
            "addPass" -> addPass(call, result)
            "getPassStatus" -> result.success("unsupported")
            else -> result.notImplemented()
        }
    }

    private fun isWalletSupported(result: Result) {
        payClient
            .getPayApiAvailabilityStatus(PayClient.RequestType.SAVE_PASSES)
            .addOnSuccessListener { status ->
                result.success(status == PayApiAvailabilityStatus.AVAILABLE)
            }
            .addOnFailureListener { result.success(false) }
    }

    private fun addPass(call: MethodCall, result: Result) {
        val jwt = call.argument<String>("androidJwt")?.trim()
        val json = call.argument<String>("androidPassJson")?.trim()
        val hasJwt = !jwt.isNullOrEmpty()
        val hasJson = !json.isNullOrEmpty()
        if (hasJwt == hasJson) {
            result.success("invalidPass")
            return
        }
        val currentActivity = activity
        if (currentActivity == null) {
            result.success("walletUnavailable")
            return
        }
        if (pendingResult != null) {
            result.success("operationInProgress")
            return
        }

        pendingResult = result
        try {
            if (hasJson) {
                // Android SDK signs metadata with the registered app certificate.
                payClient.savePasses(json!!, currentActivity, SAVE_PASS_REQUEST_CODE)
            } else {
                // Signed JWTs are reusable across Android, web, email, and SMS.
                payClient.savePassesJwt(jwt!!, currentActivity, SAVE_PASS_REQUEST_CODE)
            }
        } catch (_: Exception) {
            pendingResult = null
            result.success("internalError")
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != SAVE_PASS_REQUEST_CODE) return false
        val result = pendingResult ?: return false
        pendingResult = null
        val value = when (resultCode) {
            Activity.RESULT_OK -> "success"
            Activity.RESULT_CANCELED -> "cancelled"
            PayClient.SavePassesResult.API_UNAVAILABLE -> "walletUnavailable"
            PayClient.SavePassesResult.SAVE_ERROR -> "invalidPass"
            PayClient.SavePassesResult.INTERNAL_ERROR -> "internalError"
            else -> "internalError"
        }
        result.success(value)
        return true
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachActivity()
    }

    private fun detachActivity() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
        activity = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        pendingResult?.success("internalError")
        pendingResult = null
    }

    companion object {
        private const val SAVE_PASS_REQUEST_CODE = 0x574B
    }
}

private class GoogleWalletButtonFactory(
    private val messenger: io.flutter.plugin.common.BinaryMessenger,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return GoogleWalletButtonView(context, viewId, messenger)
    }
}

private class GoogleWalletButtonView(
    context: Context,
    viewId: Int,
    messenger: io.flutter.plugin.common.BinaryMessenger,
) : PlatformView {
    private val button: View = LayoutInflater.from(context).inflate(
        R.layout.add_to_googlewallet_button,
        null,
        false,
    )
    private val channel = MethodChannel(
        messenger,
        "flutter_wallet_kit/google_button_$viewId",
    )

    init {
        button.setOnClickListener { channel.invokeMethod("onPressed", null) }
    }

    override fun getView(): View = button

    override fun dispose() {
        button.setOnClickListener(null)
    }
}
