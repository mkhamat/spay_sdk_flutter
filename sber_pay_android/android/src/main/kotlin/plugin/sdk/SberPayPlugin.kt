package plugin.sdk

import FlutterError
import InitConfig
import PaymentRequest
import SberPayApi
import SberPayApiEnv
import SberPayApiPaymentStatus
import android.app.Activity
import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import spay.sdk.SPaySdkApp
import spay.sdk.api.PaymentResult
import spay.sdk.api.SPayHelperConfig
import spay.sdk.api.SPayMethod
import spay.sdk.api.SPaySdkInitConfig
import spay.sdk.api.SPayStage
import spay.sdk.api.SdkReadyCheckResult
import spay.sdk.api.model.SPaymentRequest

/**
 * Плагин для оплаты с использованием SberPay. Для работы нужен установленный Сбербанк (либо Сбол).
 */
class SberPayPlugin : FlutterPlugin, ActivityAware, SberPayApi {

    private lateinit var activity: Activity
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        SberPayApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    /**
     * Метод инициализации, выполняется перед стартом приложения.
     *
     * @property InitConfig конфигурация инициализации
     */
    override fun initSberPay(config: InitConfig, callback: (Result<Boolean>) -> Unit) {
        val sPayStage = when (config.env) {
            SberPayApiEnv.SANDBOX_REAL_BANK_APP -> SPayStage.SandboxRealBankApp
            SberPayApiEnv.SANDBOX_WITHOUT_BANK_APP -> SPayStage.SandBoxWithoutBankApp // Or another enum if available
            else -> SPayStage.Prod
        }
        val enableBnpl = config.enableBnpl ?: false

        try {
            val sPaySdkInitConfig = SPaySdkInitConfig(
                enableBnpl = enableBnpl,
                stage = sPayStage,
                helperConfig = SPayHelperConfig(
                    isHelperEnabled = true,
                    disabledHelpers = emptyList()
                ),
                resultViewNeeded = true,
                enableLogging = true,
                spasiboBonuses = true,
                enableOutsideTouchCancelling = true,
            ) { initializationResult ->
                Log.i("Initialization_result_spay", "$initializationResult")
                callback(Result.success(true))
            }

            SPaySdkApp.getInstance().initialize(activity.application, sPaySdkInitConfig)
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("-", e.localizedMessage, e.message)))
        }
    }

    /**
     * Метод для проверки готовности к оплате.
     *
     * @return Если у пользователя нет установленного сбера в режимах
     * SPayStage.SandboxRealBankApp, SPayStage.prod - вернет false.
     */
    override fun isReadyForSPaySdk(callback: (Result<Boolean>) -> Unit) {
        SPaySdkApp.getInstance().isReadyForSPaySdk(context) { result ->
            callback(Result.success(result is SdkReadyCheckResult.Ready))
        }
    }

    /**
     * Метод для оплаты.
     *
     * @property PaymentRequest конфигурация оплаты
     * @return SberPayApiPaymentStatus статус оплаты
     */
    override fun pay(request: PaymentRequest, callback: (Result<SberPayApiPaymentStatus>) -> Unit) {
        try {
            SPaySdkApp.getInstance().pay(
                method = SPayMethod.WithBankInvoiceId,
                request = SPaymentRequest(
                    context = activity.application,
                    apiKey = request.apiKey ?: "",
                    merchantLogin = request.merchantLogin ?: "",
                    bankInvoiceId = request.bankInvoiceId,
                    orderNumber = request.orderNumber,
                    appPackage = request.applicationId ?: "",
                    phoneNumber = ""
                ) { response: PaymentResult ->
                    when (response) {
                        is PaymentResult.Processing -> callback(Result.success(SberPayApiPaymentStatus.PROCESSING))
                        is PaymentResult.Success -> callback(Result.success(SberPayApiPaymentStatus.SUCCESS))
                        is PaymentResult.Cancel -> callback(Result.success(SberPayApiPaymentStatus.CANCEL))
                        is PaymentResult.Error -> callback(Result.failure(FlutterError("-", "MerchantError", response.merchantError?.description ?: "Ошибка выполнения оплаты")))
                    }
                }
            )
        } catch (error: Exception) {
            callback(Result.failure(FlutterError("-", error.localizedMessage, error.message)))
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        SberPayApi.setUp(binding.binaryMessenger, null)
    }

    override fun onAttachedToActivity(activityBinding: ActivityPluginBinding) {
        activity = activityBinding.activity
    }

    override fun onReattachedToActivityForConfigChanges(activityBinding: ActivityPluginBinding) {
        activity = activityBinding.activity
    }

    override fun onDetachedFromActivity() {}

    override fun onDetachedFromActivityForConfigChanges() {}
}
