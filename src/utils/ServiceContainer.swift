import Foundation

/// Dependency Injection container for managing service lifetimes and dependencies
/// Supports singleton (shared instance) and factory (new instance) patterns
class ServiceContainer {

    // MARK: - Singleton

    static let shared = ServiceContainer()

    private init() {
        Logger.info("ServiceContainer initialized", category: .general)
        registerDefaultServices()
    }

    // MARK: - Service Storage

    private var singletons: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    // NSRecursiveLock prevents deadlock when lazy singleton factory calls back into container
    private let lock = NSRecursiveLock()

    // MARK: - Registration

    func registerSingleton<T>(_ type: T.Type, instance: T) {
        lock.lock()
        defer { lock.unlock() }
        let key = String(describing: type)
        singletons[key] = instance
        Logger.debug("Registered singleton: \(key)", category: .general)
    }

    func registerFactory<T>(_ type: T.Type, factory: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }
        let key = String(describing: type)
        factories[key] = factory
        Logger.debug("Registered factory: \(key)", category: .general)
    }

    func registerLazySingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }
        let key = String(describing: type)
        factories[key] = { [weak self] in
            guard let self = self else { return factory() }
            let instance = factory()
            // NSRecursiveLock allows re-entry here from same thread
            self.lock.lock()
            self.singletons[key] = instance
            self.factories.removeValue(forKey: key)
            self.lock.unlock()
            return instance
        }
        Logger.debug("Registered lazy singleton: \(key)", category: .general)
    }

    // MARK: - Resolution

    func resolve<T>(_ type: T.Type) -> T? {
        lock.lock()
        defer { lock.unlock() }
        let key = String(describing: type)
        if let singleton = singletons[key] as? T { return singleton }
        if let factory = factories[key] {
            let instance = factory()
            return instance as? T
        }
        Logger.warning("Failed to resolve service: \(key)", category: .general)
        return nil
    }

    func resolveRequired<T>(_ type: T.Type) throws -> T {
        guard let service = resolve(type) else {
            throw ServiceContainerError.serviceNotRegistered(String(describing: type))
        }
        return service
    }

    // MARK: - Unregistration

    func unregister<T>(_ type: T.Type) {
        lock.lock()
        defer { lock.unlock() }
        let key = String(describing: type)
        singletons.removeValue(forKey: key)
        factories.removeValue(forKey: key)
        Logger.debug("Unregistered service: \(key)", category: .general)
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        singletons.removeAll()
        factories.removeAll()
        Logger.info("ServiceContainer reset - all services removed", category: .general)
        registerDefaultServices()
    }

    // MARK: - Default Services

    private func registerDefaultServices() {
        registerLazySingleton(FormatDetector.self) { FormatDetector() }
        registerLazySingleton(ExportValidator.self) { ExportValidator() }
        // TextToSpeech as singleton — AVSpeechSynthesizer is expensive to instantiate
        registerLazySingleton(TextToSpeech.self) { TextToSpeech() }
        registerFactory(AudioController.self) { AudioController() }
        registerFactory(KDPConverter.self) { KDPConverter() }
        registerFactory(GoogleConverter.self) { GoogleConverter() }
        registerFactory(FormattingEngine.self) { FormattingEngine() }
        registerFactory(EbookParser.self) { EbookParser() }
        Logger.info("Default services registered", category: .general)
    }

    // MARK: - Debugging

    func registeredServices() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        var services: [String] = []
        services.append(contentsOf: singletons.keys.map { "\($0) (singleton)" })
        services.append(contentsOf: factories.keys.map { "\($0) (factory)" })
        return services.sorted()
    }
}

// MARK: - Errors

enum ServiceContainerError: Error, CustomStringConvertible {
    case serviceNotRegistered(String)
    case serviceTypeMismatch(String)

    var description: String {
        switch self {
        case .serviceNotRegistered(let type): return "Service not registered: \(type)"
        case .serviceTypeMismatch(let type): return "Service type mismatch: \(type)"
        }
    }
}

// MARK: - Convenience Extensions

extension ServiceContainer {
    var textToSpeech: TextToSpeech {
        return resolve(TextToSpeech.self) ?? TextToSpeech()
    }
    var audioController: AudioController {
        return resolve(AudioController.self) ?? AudioController()
    }
    var formatDetector: FormatDetector {
        return resolve(FormatDetector.self) ?? FormatDetector()
    }
    var exportValidator: ExportValidator {
        return resolve(ExportValidator.self) ?? ExportValidator()
    }
    var kdpConverter: KDPConverter {
        return resolve(KDPConverter.self) ?? KDPConverter()
    }
    var googleConverter: GoogleConverter {
        return resolve(GoogleConverter.self) ?? GoogleConverter()
    }
}

// MARK: - Protocol for Injectable Services

protocol Injectable {
    func didInject()
}

extension Injectable {
    func didInject() {}
}
