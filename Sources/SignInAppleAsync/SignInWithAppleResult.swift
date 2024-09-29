//
//  SignInWithAppleResult.swift
//  SignInAppleAsync
//
//  Created by Nick Sarno on 9/29/24.
//
import Foundation
import AuthenticationServices

public struct SignInWithAppleResult: Sendable {
    let token: String
    let nonce: String
    let email: String?
    let firstName: String?
    let lastName: String?
    let nickName: String?

    var fullName: String? {
        if let firstName, let lastName {
            return firstName + " " + lastName
        } else if let firstName {
            return firstName
        } else if let lastName {
            return lastName
        }
        return nil
    }

    var displayName: String? {
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
