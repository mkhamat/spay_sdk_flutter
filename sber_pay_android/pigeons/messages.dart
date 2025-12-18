import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut: 'android/src/main/kotlin/plugin/sdk/Messages.g.kt',
  ),
)

/// Тип инициализации сервисов Сбербанка
enum SberPayApiEnv {
  /// Продуктовый режим.
  ///
  /// Для авторизации пользователя происходит редирект в приложение Сбербанка.
  prod,

  /// Режим песочницы.
  ///
  /// Позволяет протестировать оплату как в [prod], но с тестовыми данными.
  sandboxRealBankApp,

  /// Режим песочницы без перехода в банк.
  ///
  /// При авторизации пользователя не осуществляется переход в приложение
  /// Сбербанка.
  sandboxWithoutBankApp
}

/// Статусы оплаты
enum SberPayApiPaymentStatus {
  /// Успешный результат
  success,

  /// Необходимо проверить статус оплаты
  processing,

  /// Пользователь отменил оплату
  cancel,

  /// Неизвестный тип
  unknown;
}

/// Тип оплаты (сценарий)
enum PaymentMethod {
  invoice,
  autoPayment,
}

/// Конфигурация инициализации
class InitConfig {
  const InitConfig({
    required this.apiKey,
    required this.merchantLogin,
    required this.env,
    required this.enableBnpl,
  });

  /// Ключ, выдаваемый по договору, либо создаваемый в личном кабинете
  final String apiKey;

  /// Логин, выдаваемый по договору, либо создаваемый в личном кабинете
  final String merchantLogin;

  /// Среда запуска
  final SberPayApiEnv env;

  /// Использование функционала оплаты частями
  final bool? enableBnpl;
}

/// Конфигурация оплаты
class PaymentRequest {
  const PaymentRequest({
    this.apiKey,
    this.merchantLogin,
    required this.bankInvoiceId,
    required this.redirectUri,
    required this.orderNumber,
    required this.paymentMethod,
  });

  /// Ключ, выдаваемый по договору, либо создаваемый в личном кабинете
  final String? apiKey;

  /// Логин, выдаваемый по договору, либо создаваемый в личном кабинете
  final String? merchantLogin;

  /// Уникальный идентификатор заказа, сгенерированный Банком
  final String bankInvoiceId;

  /// Диплинк для перехода обратно в приложение после открытия Сбербанка
  final String redirectUri;

  /// Номер заказа
  final String orderNumber;

  /// Метод оплаты
  final PaymentMethod paymentMethod;
}

@HostApi()
abstract class SberPayApi {
  @async
  bool initSberPay(InitConfig config);

  bool isReadyForSPaySdk();

  @async
  SberPayApiPaymentStatus pay(PaymentRequest request);
}