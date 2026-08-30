import Foundation

public enum RandomIndexGenerationError: Error, Equatable, Sendable {
    case invalidUpperBound(Int)
}

public protocol RandomIndexGenerating {
    /// Returns a uniformly distributed index in `0..<upperBound`.
    func randomIndex(upperBound: Int) throws -> Int
}

/// Uses Swift's system random number generator, which is cryptographically
/// secure on Apple platforms. `Int.random(in:using:)` performs uniform range
/// sampling rather than applying a modulo operation, avoiding modulo bias.
public struct SecureRandomIndexGenerator: RandomIndexGenerating, Sendable {
    public init() {}

    public func randomIndex(upperBound: Int) throws -> Int {
        guard upperBound > 0 else {
            throw RandomIndexGenerationError.invalidUpperBound(upperBound)
        }

        var generator = SystemRandomNumberGenerator()
        return Int.random(in: 0..<upperBound, using: &generator)
    }
}
