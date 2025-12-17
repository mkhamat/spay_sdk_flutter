import 'package:sber_pay_platform_interface/types/sber_pay_env.dart';

/// Конфигурация инициализации
class SberPayInitConfig {
  const SberPayInitConfig({
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
  final SberPayEnv env;

  /// Использование функционала оплаты частями
  final bool? enableBnpl;
}
