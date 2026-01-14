import Foundation

/// Dependency Injection container for managing service lifetimes and dependencies
/// Supports singleton (shared instance) and factory (new instance) patterns
class ServiceContainer {

    // MARK: - Singleton

    /// Shared service container instance
    static let shared = ServiceContainer()

    private init() {
        Logger.info("ServiceContainer initialized", category: .general)
        registerDefaultServices()
    }

    // MARK: - Service Storage

    private var singletons: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    private let lock = NSLock()

    // MARK: - Registration

    /// Registers a service as a singleton (created once, shared across app)
    /// - Parameters:
    ///   - type: The service type
    ///   - instance: The singleton instance
    func registerSingleton<T>(_ type: T.Type, instance: T) {
        lock.lock()
        defer { lock.unlock() }

        let key = String(describing: type)
        singletons[key] = instance
        Logger.debug("Registered singleton: \(key)", category: .general)
    }

    /// Registers a service factory (creates new instance on each resolve)
    /// - Parameters:
    ///   - type: The service type
    ///   - factory: Closure that creates a new instance
    func registerFactory<T>(_ type: T.Type, factory: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }

        let key = String(describing: type)
        factories[key] = factory
        Logger.debug("Registered factory: \(key)", category: .general)
    }

    /// Registers a service with lazy singleton pattern (created on first use)
    /// - Parameters:
    ///   - type: The service type
    ///   - factory: Closure that creates the singleton instance
    func registerLazySingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }

        let key = String(describing: type)
        // Store factory, but will convert to singleton on first resolve
        factories[key] = {
            let instance = factory()
            self.lock.lock()
            self.singletons[key] = instance
            self.factories.removeValue(forKey: key)
            self.lock.unlock()
            return instance
        }
        Logger.debug("Registered lazy singleton: \(key)", category: .general)
    }

    // MARK: - Resolution

    /// Resolves a service by type
    /// - Parameter type: The service type to resolve
    /// - Returns: The service instance, or nil if not registered
    func resolve<T>(_ type: T.Type) -> T? {
        lock.lock()
        defer { lock.unlock() }

        let key = String(describing: type)

        // Check singletons first
        if let singleton = singletons[key] as? T {
            return singleton
        }

        // Check factories
        if let factory = factories[key] {
            let instance = factory()
            return instance as? T
        }

        Logger.warning("Failed to resolve service: \(key)", category: .general)
        return nil
    }

    /// Resolves a service by type, throwing an error if not found
    /// - Parameter type: The service type to resolve
    /// - Returns: The service instance
    /// - Throws: ServiceContainerError.serviceNotRegistered
    func resolveRequired<T>(_ type: T.Type) throws -> T {
        guard let service = resolve(type) else {
            throw ServiceContainerError.serviceNotRegistered(String(describing: type))
        }
        return service
    }

    // MARK: - Unregistration

    /// Removes a service from the container
    /// - Parameter type: The service type to remove
    func unregister<T>(_ type: T.Type) {
        lock.lock()
        defer { lock.unlock() }

        let key = String(describing: type)
        singletons.removeValue(forKey: key)
        factories.removeValue(forKey: key)
        Logger.debug("Unregistered service: \(key)", category: .general)
    }

    /// Removes all services from the container
    func reset() {
        lock.lock()
        defer { lock.unlock() }

        singletons.removeAll()
        factories.removeAll()
        Logger.info("ServiceContainer reset - all services removed", category: .general)

        // Re-register default services
        registerDefaultServices()
    }

    // MARK: - Default Services

    private func registerDefaultServices() {
        // Register commonly used services with appropriate lifetimes

        // Singleton services (shared instances)
        registerLazySingleton(FormatDetector.self) {
            FormatDetector()
        }

        registerLazySingleton(ExportValidator.self) {
            ExportValidator()
        }

        // Factory services (new instance each time)
        registerFactory(TextToSpeech.self) {
            TextToSpeech()
        }

        registerFactory(AudioController.self) {
            AudioController()
        }

        registerFactory(KDPConverter.self) {
            KDPConverter()
        }

        registerFactory(GoogleConverter.self) {
            GoogleConverter()
        }

        registerFactory(FormattingEngine.self) {
            FormattingEngine()
        }

        registerFactory(EbookParser.self) {
            EbookParser()
        }

        Logger.info("Default services registered", category: .general)
    }

    // MARK: - Debugging

    /// Returns a list of all registered services
    func registeredServices() -> [String] {
        lock.lock()
        defer { lock.unlock() }

        var services: [String] = []
        services.append(contentsOf: singletons.keys.map { "\($0) (singleton)" })
        services.append(contentsOf: factories.keys.map { "\($0) (factory)" })
        return services.sorted()
    }

    /// Prints all registered services to console
    func debugPrint() {
        let services = registeredServices()
        Logger.debug("ServiceContainer has \(services.count) registered services:", category: .general)
        for service in services {
            Logger.debug("  - \(service)", category: .general)
        }
    }
}

// MARK: - Errors

enum ServiceContainerError: Error, CustomStringConvertible {
    case serviceNotRegistered(String)
    case serviceTypeMismatch(String)

    var description: String {
        switch self {
        case .serviceNotRegistered(let type):
            return "Service not registered: \(type)"
        case .serviceTypeMismatch(let type):
            return "Service type mismatch: \(type)"
        }
    }
}

// MARK: - Convenience Extensions

extension ServiceContainer {
    /// Resolves or creates a TextToSpeech instance
    var textToSpeech: TextToSpeech {
        return resolve(TextToSpeech.self) ?? TextToSpeech()
    }

    /// Resolves or creates an AudioController instance
    var audioController: AudioController {
        return resolve(AudioController.self) ?? AudioController()
    }

    /// Resolves or creates a FormatDetector instance
    var formatDetector: FormatDetector {
        return resolve(FormatDetector.self) ?? FormatDetector()
    }

    /// Resolves or creates an ExportValidator instance
    var exportValidator: ExportValidator {
        return resolve(ExportValidator.self) ?? ExportValidator()
    }

    /// Resolves or creates a KDPConverter instance
    var kdpConverter: KDPConverter {
        return resolve(KDPConverter.self) ?? KDPConverter()
    }

    /// Resolves or creates a GoogleConverter instance
    var googleConverter: GoogleConverter {
        return resolve(GoogleConverter.self) ?? GoogleConverter()
    }
}

// MARK: - Protocol for Injectable Services

/// Protocol that services can conform to for dependency injection
protocol Injectable {
    /// Called after all dependencies have been injected
    func didInject()
}

extension Injectable {
    func didInject() {
        // Default empty implementation
    }
}
