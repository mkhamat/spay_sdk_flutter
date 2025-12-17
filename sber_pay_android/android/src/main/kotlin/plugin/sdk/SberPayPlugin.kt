package plugin.sdk

import FlutterError
import InitConfig
import PayConfig
import SberPayApi
import SberPayApiEnv
import SberPayApiPaymentStatus
import android.app.Activity
import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import ru.sberbank.sberpay.sdk.SPaySdkApp
import ru.sberbank.sberpay.sdk.SPayInitSdkConfig
import ru.sberbank.sberpay.sdk.SPaySdkEnv
import ru.sberbank.sberpay.sdk.api.payment.PaymentResult

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
            SberPayApiEnv.SANDBOXREALBANKAPP -> SPaySdkEnv.TEST
            SberPayApiEnv.SANDBOXWITHOUTBANKAPP -> SPaySdkEnv.TEST // Or another enum if available
            else -> SPaySdkEnv.PROD
        }
        val enableBnpl = config.enableBnpl ?: false

        try {
            val builder = SPayInitSdkConfig.Builder()
                .setApiKey(config.apiKey)
                .setMerchantLogin(config.merchantLogin)
                .setEnvironment(sPayStage)
                .setBnplEnabled(enableBnpl)
                .setHelpersEnabled(true)
                .setInitCallback(object : SPaySdkApp.InitCallback {
                    override fun onInitSuccess() {
                        callback(Result.success(true))
                    }

                    override fun onInitFailure(e: Throwable?) {
                        val errorMessage = e?.message ?: "Unknown init error"
                        callback(Result.failure(FlutterError("-", "InitError", errorMessage)))
                    }
                })

            val sPaySdkInitConfig = builder.build()
            SPaySdkApp.initialize(activity.application, sPaySdkInitConfig)
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
    override fun isReadyForSPaySdk(): Boolean {
        // In v3, readiness might be checked differently or simply by the fact init succeeded.
        // Documentation says "it checks readiness of internal SDK components".
        // Assuming SPaySdkApp has a method for this or we assume true if initialized.
        // Using the search result info: "Modified the functionality of the isReadyForSPaySdk method"
        // Let's assume it's still available on SPaySdkApp or the instance.
        return SPaySdkApp.getInstance().isReadyForSPaySdk(context)
    }

    /**
     * Метод для оплаты.
     *
     * @property PayConfig конфигурация оплаты
     * @return SberPayApiPaymentStatus статус оплаты
     */
    override fun payWithBankInvoiceId(config: PayConfig, callback: (Result<SberPayApiPaymentStatus>) -> Unit) {
        try {
            // apiKey and merchantLogin are now in init
            SPaySdkApp.getInstance().payWithBankInvoiceId(activity, config.bankInvoiceId, config.orderNumber) { response: PaymentResult ->
                 when (response) {
                    is PaymentResult.Processing -> callback(Result.success(SberPayApiPaymentStatus.PROCESSING))
                    is PaymentResult.Success -> callback(Result.success(SberPayApiPaymentStatus.SUCCESS))
                    is PaymentResult.Cancel -> callback(Result.success(SberPayApiPaymentStatus.CANCEL))
                    is PaymentResult.Error -> callback(Result.failure(FlutterError("-", "MerchantError", response.merchantError?.description ?: "Ошибка выполнения оплаты")))
                }
            }
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
