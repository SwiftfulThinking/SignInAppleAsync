//
//  SignInWithAppleResult.swift
//  SignInAppleAsync
//
//  Created by Nick Sarno on 9/29/24.
//
import Foundation
import AuthenticationServices

public struct SignInWithAppleResult: Sendable {
    public let token: String
    public let nonce: String
    public let email: String?
    public let firstName: String?
    public let lastName: String?
    public let nickName: String?

    public var fullName: String? {
        if let firstName, let lastName {
            return firstName + " " + lastName
        } else if let firstName {
            return firstName
        } else if let lastName {
            return lastName
        }
        return nil
    }

    public var displayName: String? {
        fullName ?? nickName
    }

    init?(authorization: ASAuthorization, nonce: String) {
        guard
            let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let appleIDToken = appleIDCredential.identityToken
        else {
            return nil
        }
        let token = String(decoding: appleIDToken, as: UTF8.self)

        self.token = token
        self.nonce = nonce
        self.email = appleIDCredential.email
        self.firstName = appleIDCredential.fullName?.givenName
        self.lastName = appleIDCredential.fullName?.familyName
        self.nickName = appleIDCredential.fullName?.nickname
    }
}
