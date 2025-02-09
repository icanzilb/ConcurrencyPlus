import Foundation

public enum CancellingContinuationError: Error {
    case cancelledOnDeinit
}

/// A continuation that will automaticlaly throw if deallocated without being resumed
public final class CancellingContinuation<T> {
    // I realize this is not thread-safe
    private var resumed: Bool
    private let continuation: CheckedContinuation<T, Error>

    init(_ continuation: CheckedContinuation<T, Error>) {
        self.continuation = continuation
        self.resumed = false
    }

    deinit {
        if resumed == false {
            continuation.resume(throwing: CancellingContinuationError.cancelledOnDeinit)
            return
        }
    }

    public func resume(returning value: T) {
        precondition(resumed == false)
        self.resumed = true
        continuation.resume(returning: value)
    }

    public func resume(throwing error: Error) {
        precondition(resumed == false)
        self.resumed = true
        continuation.resume(throwing: error)
    }
}

extension CancellingContinuation where T == () {
    public func resume() {
        continuation.resume()
        self.resumed = true
    }
}

/// Behaves just like withCheckedThrowingContinuation, but will resume with an error if the
/// closure is never invoked. Useful for situations where you cannot guarantee that a closure
/// will be called.
public func withCancellingContinutation<T>(function: String = #function, _ body: (CancellingContinuation<T>) -> Void) async throws -> T {
    return try await withCheckedThrowingContinuation(function: function, { (continuation: CheckedContinuation<T, Error>) in
        let continuation = CancellingContinuation(continuation)

        body(continuation)
    })
}

