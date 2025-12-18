/// Тип оплаты (сценарий)
enum SberPayPaymentMethod {
  /// Оплата по инвойсу (по умолчанию)
  invoice,

  /// Автоматическая оплата
  autoPayment,
}

/// Конфигурация оплаты (Request)
class SberPayPaymentRequest {
  const SberPayPaymentRequest({
    this.apiKey,
    this.merchantLogin,
    required this.bankInvoiceId,
    required this.redirectUri,
    required this.orderNumber,
    this.paymentMethod = SberPayPaymentMethod.invoice,
  });

  /// Ключ, выдаваемый по договору, либо создаваемый в личном кабинете
  final String? apiKey;

  /// Логин, выдаваемый по договору, либо создаваемый в личном кабинете
  final String? merchantLogin;

  /// Уникальный идентификатор заказа, сгенерированный Банком
  final String bankInvoiceId;

  /// Диплинк для перехода обратно в приложение после открытия Сбербанка (только на iOS)
  final String redirectUri;

  /// Номер заказа
  final String orderNumber;

  /// Метод оплаты (сценарий)
  final SberPayPaymentMethod paymentMethod;
}
