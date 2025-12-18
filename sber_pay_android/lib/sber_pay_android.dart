import 'package:flutter/foundation.dart';
import 'package:sber_pay_android/src/messages.g.dart';
import 'package:sber_pay_platform_interface/sber_pay_platform_interface.dart';

class SberPayAndroid extends SberPayPlatform {
  /// Creates a new plugin implementation instance.
  SberPayAndroid({
    @visibleForTesting SberPayApi? api,
  }) : _api = api ?? SberPayApi();

  static void registerWith() {
    SberPayPlatform.instance = SberPayAndroid();
  }

  final SberPayApi _api;

  @override
  Future<bool> initSberPay(SberPayInitConfig config) async {
    final envConfig = switch (config.env) {
      SberPayEnv.sandboxRealBankApp => SberPayApiEnv.sandboxRealBankApp,
      SberPayEnv.sandboxWithoutBankApp => SberPayApiEnv.sandboxWithoutBankApp,
      _ => SberPayApiEnv.prod
    };
    final result = await _api.initSberPay(
      InitConfig(
        apiKey: config.apiKey,
        merchantLogin: config.merchantLogin,
        env: envConfig,
        enableBnpl: config.enableBnpl,
      ),
    );
    return result;
  }

  @override
  Future<bool> isReadyForSPaySdk() {
    return _api.isReadyForSPaySdk();
  }

  @override
  Future<SberPayPaymentStatus> pay(
    SberPayPaymentRequest request,
  ) async {
    final method = switch (request.paymentMethod) {
      SberPayPaymentMethod.autoPayment => PaymentMethod.autoPayment,
      _ => PaymentMethod.invoice
    };

    final result = await _api.pay(
      PaymentRequest(
        apiKey: request.apiKey,
        merchantLogin: request.merchantLogin,
        bankInvoiceId: request.bankInvoiceId,
        redirectUri: request.redirectUri,
        orderNumber: request.orderNumber,
        paymentMethod: method,
      ),
    );
    return switch (result) {
      SberPayApiPaymentStatus.success => SberPayPaymentStatus.success,
      SberPayApiPaymentStatus.processing => SberPayPaymentStatus.processing,
      SberPayApiPaymentStatus.cancel => SberPayPaymentStatus.cancel,
      _ => SberPayPaymentStatus.unknown
    };
  }
}
