package dev.flutterwalletkit.flutter_wallet_kit

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test

internal class FlutterWalletKitPluginTest {
    @Test
    fun getPassStatus_reportsUnsupportedOnAndroid() {
        val plugin = FlutterWalletKitPlugin()
        val call = MethodCall("getPassStatus", mapOf("iosPassData" to byteArrayOf(1)))
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)
        Mockito.verify(mockResult).success("unsupported")
    }
}
