import 'package:sber_pay_platform_interface/sber_pay_platform_interface.dart';

/// Плагин для отображения нативной кнопки SberPay SDK
///
/// Все исключения (Exceptions) приходящие из методов этого класса должны
/// обрабатываться уровнем выше.
class SberPayPlugin {
  static SberPayPlatform get _platform => SberPayPlatform.instance;

  /// Инициализация SberPay SDK.
  ///
  /// Необходимо выполнить для начала работы с библиотекой.
  ///
  /// * [apiKey] - ключ, выдаваемый по договору
  /// * [merchantLogin] - логин, выдаваемый по договору
  /// * [env] - среда запуска, которая определяется через [SberPayEnv].
  /// * [enableBnpl] - функционал оплаты частями
  static Future<bool> initSberPay({
    required String apiKey,
    required String merchantLogin,
    required SberPayEnv env,
    bool? enableBnpl,
  }) async =>
      _platform.initSberPay(
        SberPayInitConfig(
          apiKey: apiKey,
          merchantLogin: merchantLogin,
          env: env,
          enableBnpl: enableBnpl,
        ),
      );

  /// Метод для проверки готовности к оплате.
  ///
  /// Зависит от переданного аргумента *env* при инициализации через метод
  /// [initSberPay] (см. комментарий к методу).
  ///
  /// Если у пользователя нет установленного сбера в режимах
  /// [SberPayEnv.sandboxRealBankApp], [SberPayEnv.prod] - вернет false.
  static Future<bool> isReadyForSPaySdk() async =>
      _platform.isReadyForSPaySdk();

  /// Метод оплаты через SberPay SDK.
  /// * [apiKey] - ключ, выдаваемый по договору (необязательно, если передан в init)
  /// * [merchantLogin] - логин, выдаваемый по договору (необязательно, если передан в init)
  /// * [bankInvoiceId] - параметр, который получаем после запроса для
  /// регистрации заказа в шлюзе Сбера.
  /// * [redirectUri] - диплинк для перехода обратно в приложение после открытия
  /// Сбербанка (только на iOS).
  /// * [orderNumber] - номер заказа при регистрации в шлюзе
  /// Сбербанка (только на iOS).
  ///
  /// Возвращает статус оплаты [SberPayPaymentStatus]
  static Future<SberPayPaymentStatus> payWithBankInvoiceId({
    required String bankInvoiceId,
    required String redirectUri,
    required String orderNumber,
    String? apiKey,
    String? merchantLogin,
  }) async =>
      _platform.pay(
        SberPayPaymentRequest(
          apiKey: apiKey,
          merchantLogin: merchantLogin,
          bankInvoiceId: bankInvoiceId,
          redirectUri: redirectUri,
          orderNumber: orderNumber,
        ),
      );
}
