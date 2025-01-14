import EMLogger
import Foundation
import Vapor

/// An object that can mock the behavior of a network exchange.
/// It consists of 2 main methods:
///  - `configure(configuration:)` which instantiates the `Vapor` application and register the routes.
///  - `start()` which runs the `Vapor` instance.
public class MockServer {
  
  // MARK: Properties
  
  /// The `Vapor` `Application` instance.
  public private(set) var vaporApplication: Application?
  
  /// The amount of time (in seconds) the server has to wait before returning a response.
  internal private(set) var delay: TimeInterval = 0
  
  /// A dictionary to track the requests made to the server and how many was each made.
  internal private(set) var requestsTracker: [Request: Int] = [:]
  
  /// The host associated with the running instance's configuration.
  internal var host: String? {
    vaporApplication?.http.server.configuration.hostname
  }

  /// The port associated with the running instance's configuration.
  internal var port: Int? {
    vaporApplication?.http.server.configuration.port
  }
  
  /// The description of the address where the server will be running.
  ///
  /// If called before the server is configured, it will return nil.
  public var addressDescription: String? {
    guard let host = host, let port = port else {
      return nil
    }
    
    return "http://\(host):\(port)"
  }
  
  // MARK: Init
  
  public init() {}
  
  // MARK: Methods
  
  /// Configures the `MockServer` instance.
  ///
  /// This needs to be called before the `start()` method is called.
  /// - Parameter configuration: An object conforming to `ServerConfigurationProvider`, providing the necessary information.
  public func configure(using configuration: any ServerConfigurationProvider) throws {
    guard vaporApplication == nil else {
      throw Error.instanceAlreadyRunning
    }

    vaporApplication = Application(configuration.environment.vaporEnvironment)
    vaporApplication?.http.server.configuration.port = configuration.port
    vaporApplication?.http.server.configuration.hostname = configuration.hostname
    vaporApplication?.logger = Logger(
      label: "com.theinkedengineer.com",
      factory: { _ in EMLogger(logLevel: configuration.logLevel) }
    )
    vaporApplication?.http.server.configuration.logger = Logger(
      label: "com.theinkedengineer.com",
      factory: { _ in EMLogger(logLevel: configuration.logLevel) }
    )
    
    delay = configuration.delay

    registerRoutes(configuration.networkExchanges, to: vaporApplication!)
  }
  
  /// Runs the underlying `Vapor` instance of the `MockServer`.
  public func run() throws {
    guard let vaporApplication else {
      throw Error.serverNotConfigured
    }
    
    do {
      // https://www.kodeco.com/31498014-running-a-web-server-on-ios-with-vapor#toc-anchor-005
      try vaporApplication.server.start()
    } catch {
      // The most common error would be when we try to run the server on a PORT that is already used.
      throw Error.vapor(error: error)
    }
  }
  
  /// Shuts down the currently running instance of `Vapor`'s application, if any.
  public func stop() async throws {
    vaporApplication?.server.shutdown()
    try await vaporApplication?.server.onShutdown.get()
    vaporApplication = nil
  }
  
  /// Shuts down the currently running instance of `Application` if any,
  /// then starts a new `Application` instance using the passed configuration.
  /// - Parameter configuration: An object conforming to `ServerConfigurationProvider`.
  /// - Throws: `ServerError.instanceAlreadyRunning` or a wrapped `Vapor` error.
  public func restart(with configuration: ServerConfigurationProvider) async throws {
    try await stop()
    try configure(using: configuration)
    try run()
  }
  
  /// Registers the routes that the Mock server should be able to intercept and respond to.
  /// - Parameters:
  ///   - networkExchanges: An array of ``NetworkExchange`` to build the routes to intercept.
  ///   - application: The `Vapor` application instance to which we attach the routes.
  internal func registerRoutes(_ networkExchanges: [NetworkExchange], to application: Application) {
    networkExchanges.forEach { networkExchange in
      application
        .on(networkExchange.request.method, networkExchange.request.pathComponents) { [self, networkExchange] request async throws in
          await generateClientResponse(using: networkExchange, for: request)
      }
    }
  }
  
  /// Generates the `ClientResponse` given a `NetworkExchange` and `Vapor.Request`
  /// - Parameters:
  ///   - networkExchange: A `NetworkExchange` object used to fetched the information of the desired response.
  ///   - request: A `Vapor.Request` object used to collect data from a file.
  /// - Returns: A `ClientResponse` object.
  private func generateClientResponse(using networkExchange: NetworkExchange, for request: Vapor.Request) async -> ClientResponse {
    // The bytes to return with the response.
    let byteBuffer: ByteBuffer?
    
    // The number of times this request has been made
    let requestNumber = (requestsTracker[networkExchange.request] ?? 0)
    let responseIndex = min(requestNumber, networkExchange.response.count - 1)
    
    if #unavailable(macOS 13), #unavailable(iOS 16.0) {
      try? await Task.sleep(nanoseconds: UInt64((networkExchange.response[responseIndex].delay ?? delay) * 1_000_000_000))
    } else {
      try? await Task.sleep(for: .seconds(networkExchange.response[responseIndex].delay ?? delay))
    }
    
    switch networkExchange.response[responseIndex].kind {
      case .empty:
        byteBuffer = nil
        
      case let .string(value):
        byteBuffer = ByteBuffer(string: value)
        
      case let .data(value):
        byteBuffer = ByteBuffer(data: value)
        
      case let .json(value, encoder):
        guard let data = try? encoder.encode(value) else {
          // If we fail to encode the data, we just throw a server error.
          return ClientResponse(
            status: .internalServerError,
            headers: networkExchange.response[responseIndex].headers.removing(name: "Content-Type"),
            body: nil
          )
        }
        
        byteBuffer = ByteBuffer(data: data)
        
      case let .fileContent(pathToFile):
        // If we fail to find the file (most likely only reason for failure), we just throw a 404 error.
        guard let content = try? await request.fileio.collectFile(at: pathToFile).get() else {
          return ClientResponse(
            status: .notFound,
            headers: networkExchange.response[responseIndex].headers.removing(name: "Content-Type"),
            body: nil
          )
        }
        
        byteBuffer = content
    }
    
    let clientResponse = ClientResponse(
      status: networkExchange.response[responseIndex].status,
      headers: networkExchange.response[responseIndex].headers,
      body: byteBuffer
    )
    
    requestsTracker[networkExchange.request] = (requestsTracker[networkExchange.request] ?? 0) + 1
    
    return clientResponse
  }
}
