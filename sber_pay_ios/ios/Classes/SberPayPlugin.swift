import Flutter
import UIKit
import SPaySdk

// This extension of Error is required to do use FlutterError in any Swift code.
extension FlutterError: Error {}

/**
 * Плагин для оплаты с использованием SberPay. Для работы нужен установленный Сбербанк (либо Сбол).
 */
public class SberPayPlugin: NSObject, FlutterPlugin, SberPayApi{

    private var apiKey: String?
    private var merchantLogin: String?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger : FlutterBinaryMessenger = registrar.messenger()
        let instance = SberPayPlugin()
        SberPayApiSetup.setUp(binaryMessenger: messenger, api: instance)

        /// Создание [addApplicationDelegate] для перехода по диплинку обратно в приложение
        registrar.addApplicationDelegate(instance)
    }

    public func application(_ app: UIApplication,open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        /// Если при открытии приложения с диплинком если он содержит хост "spay", то такой диплинк
        /// попадает в нативный плагин. Таким образом работает возврат в приложение и получение данных нативным
        /// SDK от приложения Сбербанк онлайн/СБОЛ
        if  url.host == "spay" {
            SPay.getAuthURL(url)
        }

        return true
    }

    /**
     Метод инициализации, выполняется перед стартом приложения.
     - Parameter InitConfig конфигурация инициализации
     */
    func initSberPay(config: InitConfig, completion: @escaping (Result<Bool, Error>) -> Void) {
        self.apiKey = config.apiKey
        self.merchantLogin = config.merchantLogin

        let env = config.env
        let enableBnpl = config.enableBnpl ?? false

        let sPayStage: SEnvironment
        switch env {
        case SberPayApiEnv.sandboxRealBankApp:
            sPayStage = .sandboxRealBankApp
        case SberPayApiEnv.sandboxWithoutBankApp:
            sPayStage = .sandboxWithoutBankApp
        default:
            sPayStage = .prod
        }

        let helperConfig = SBHelperConfig(sbp: true, creditCard: true, debitCard: true)

        SPay.setup(bnplPlan: enableBnpl,
                   spasiboBonuses: false, // Default to false
                   resultViewNeeded: true,
                   helpers: true,
                   needLogs: true,
                   helperConfig: helperConfig,
                   environment: sPayStage) { error in
            if let error = error {
                //  Произошла ошибка на этапе инициализации SDK.
                print("SberPay Init Error: \(error.description)")
                print("SberPay Init Error Details: \(error)")
                completion(.failure(FlutterError(code: "INIT_ERROR", message: error.description, details: nil)))
            } else {
                // SDK инициализировалось без ошибок.
                print("SberPay Init Success")
                completion(.success(true))
            }
        }
    }

    /**
     Метод для проверки готовности к оплате.

     - Returns Если у пользователя нет установленного сбера в режимах SEnvironment.sandboxRealBankApp,
     SEnvironment.prod - вернет false.
     */
    func isReadyForSPaySdk() throws -> Bool {
        return SPay.isReadyForSPay
    }

    /**
     Метод для оплаты.
     - Parameter request конфигурация оплаты
     - Returns SberPayApiPaymentStatus статус оплаты
     */
    func pay(request: PaymentRequest, completion: @escaping (Result<SberPayApiPaymentStatus, Error>) -> Void) {
        if request.bankInvoiceId.count != 32 {
            completion(.failure(PigeonError(code: "-", message: "MerchantError", details: "Длина bankInvoiceId должна быть 32 символа")))
            return
        }

        guard let topController = getTopViewController() else {
            completion(.failure(PigeonError(code: "PluginError", message: "SberPay: Failed to implement controller", details: nil)))
            return
        }

        // Use credentials from request if available or fallback to cached ones
        let finalApiKey = request.apiKey?.isEmpty == false ? request.apiKey : self.apiKey
        let finalMerchantLogin = request.merchantLogin?.isEmpty == false ? request.merchantLogin : self.merchantLogin
        
        guard let apiKey = finalApiKey, !apiKey.isEmpty else {
             completion(.failure(PigeonError(code: "PluginError", message: "ApiKey is missing", details: nil)))
             return
        }
        
        guard let merchantLogin = finalMerchantLogin, !merchantLogin.isEmpty else {
             completion(.failure(PigeonError(code: "PluginError", message: "MerchantLogin is missing", details: nil)))
             return
        }

        let paymentRequest = SPaymentRequest(
            apiKey: apiKey,
            bankInvoiceId: request.bankInvoiceId,
            orderNumber: request.orderNumber,
            merchantLogin: merchantLogin,
            redirectUri: request.redirectUri,
            phoneNumber: nil)

        let method: SPayMethod
        switch request.paymentMethod {
        case .autoPayment:
            method = .default
        default:
            method = .default
        }

        SPay.pay(view: topController, method: method, request: paymentRequest) { state, bankInvoiceId, localSessionId, info in
             print("SberPay pay callback. State: \(state)")
             print("SberPay pay info: \(info)")
             print("SberPay pay localSessionId: \(localSessionId)")

             switch state {
             case .success:
                 completion(.success(SberPayApiPaymentStatus.success))
             case .waiting:
                 completion(.success(SberPayApiPaymentStatus.processing))
             case .cancel:
                 completion(.success(SberPayApiPaymentStatus.cancel))
             case .error:
                 let fullMessage = "Ошибка оплаты. Info: \(info). SessionId: \(localSessionId)"
                 completion(.failure(PigeonError(code: "PAY_ERROR", message: fullMessage, details: info)))
             @unknown default:
                 completion(.failure(PigeonError(code: "UNKNOWN_STATE", message: "Неопределенная ошибка (State: \(state)). Info: \(info)", details: info)))
             }
        }
    }

    private func getTopViewController() -> UIViewController? {
        var topController = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController

        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }

        return topController
    }
}
