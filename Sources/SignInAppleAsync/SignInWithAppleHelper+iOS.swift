#if os(iOS)

import Foundation
import CryptoKit
import AuthenticationServices
import UIKit

@MainActor
public final class SignInWithAppleHelper: NSObject {

    private var completionHandler: ((Result<SignInWithAppleResult, Error>) -> Void)?
    private var currentNonce: String?
    
    /// Start Sign In With Apple and present OS modal.
    ///
    /// - Parameter viewController: ViewController to present OS modal on. If nil, function will attempt to find the top-most ViewController. Throws an error if no ViewController is found.
    public func signIn(viewController: UIViewController? = nil) async throws -> SignInWithAppleResult {
        for try await response in startSignInWithAppleFlow() {
            return response
        }
        
        throw SignInWithAppleError.failedToStartFlow
    }

    private func startSignInWithAppleFlow(viewController: UIViewController? = nil) -> AsyncThrowingStream<SignInWithAppleResult, Error> {
        AsyncThrowingStream { continuation in
            startSignInWithAppleFlow { result in
                switch result {
                case .success(let signInWithAppleResult):
                    continuation.yield(signInWithAppleResult)
                    continuation.finish()
                    return
                case .failure(let error):
                    continuation.finish(throwing: error)
                    return
                }
            }
        }
    }

    private func startSignInWithAppleFlow(viewController: UIViewController? = nil, completion: @escaping (Result<SignInWithAppleResult, Error>) -> Void) {
        guard let topVC = viewController ?? UIApplication.topViewController() else {
            completion(.failure(SignInWithAppleError.noViewController))
            return
        }

        let nonce = randomNonceString()
        currentNonce = nonce
        completionHandler = completion
        showOSPrompt(nonce: nonce, on: topVC)
    }

}

// MARK: PRIVATE
private extension SignInWithAppleHelper {

    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError(
                        "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                    )
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }

    private func showOSPrompt(nonce: String, on viewController: UIViewController) {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = viewController

        authorizationController.performRequests()
    }

    private enum SignInWithAppleError: LocalizedError {
        case noViewController
        case invalidCredential
        case badResponse
        case unableToFindNonce
        case failedToStartFlow

        var errorDescription: String? {
            switch self {
            case .noViewController:
                return "Could not find top view controller."
            case .invalidCredential:
                return "Invalid sign in credential."
            case .badResponse:
                return "Apple Sign In had a bad response."
            case .unableToFindNonce:
                return "Apple Sign In token expired."
            case .failedToStartFlow:
                return "Apple SIgn In failed."
            }
        }
    }

}

extension SignInWithAppleHelper: ASAuthorizationControllerDelegate {
    nonisolated public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            do {
                guard let currentNonce else {
                    throw SignInWithAppleError.unableToFindNonce
                }

                guard let result = SignInWithAppleResult(authorization: authorization, nonce: currentNonce) else {
                    throw SignInWithAppleError.badResponse
                }

                completionHandler?(.success(result))
            } catch {
                completionHandler?(.failure(error))
                return
            }
        }
    }
    nonisolated public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            completionHandler?(.failure(error))
            return
        }
    }
}

extension UIViewController: @retroactive ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
 }

#endif
