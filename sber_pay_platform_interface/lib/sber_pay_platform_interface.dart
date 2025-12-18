import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sber_pay_platform_interface/types/types.dart';

export 'package:sber_pay_platform_interface/types/types.dart';

abstract class SberPayPlatform extends PlatformInterface {
  SberPayPlatform() : super(token: _token);

  static final Object _token = Object();

  static SberPayPlatform _instance = _PlaceholderImplementation();

  /// The instance of [SberPayPlatform] to use.
  ///
  /// Defaults to a placeholder that does not override any methods, and thus
  /// throws `UnimplementedError`.
  static SberPayPlatform get instance => _instance;

  /// Platform-specific plugins should override this with their own
  /// platform-specific class that extends [SberPayPlatform] when they
  /// register themselves.
  static set instance(SberPayPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Инициализация SberPay SDK.
  ///
  /// Необходимо выполнить для начала работы с библиотекой.
  ///
  /// Принимает конфигурацию инициализации [SberPayInitConfig].
  Future<bool> initSberPay(SberPayInitConfig config) {
    throw UnimplementedError('initSberPay() has not been implemented.');
  }

  /// Метод для проверки готовности к оплате.
  ///
  /// Зависит от переданного аргумента *env* при инициализации через метод
  /// [initSberPay] (см. комментарий к методу).
  ///
  /// Если у пользователя нет установленного сбера в режимах
  /// [SberPayEnv.sandboxRealBankApp], [SberPayEnv.prod] - вернет false.
  Future<bool> isReadyForSPaySdk() {
    throw UnimplementedError('isReadyForSPaySdk() has not been implemented.');
  }

  /// Метод оплаты через SberPay SDK.
  ///
  /// Принимает конфигурацию оплаты [SberPayPaymentRequest].
  /// Возвращает статус оплаты [SberPayPaymentStatus]
  Future<SberPayPaymentStatus> pay(
    SberPayPaymentRequest request,
  ) {
    throw UnimplementedError(
      'pay() has not been implemented.',
    );
  }
}

class _PlaceholderImplementation extends SberPayPlatform {}
