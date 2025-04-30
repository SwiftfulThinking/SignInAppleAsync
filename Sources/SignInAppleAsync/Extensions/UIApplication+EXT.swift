//
//  UIApplication+EXT.swift
//  SignInAppleAsync
//
//  Created by Nick Sarno on 9/29/24.
//

#if os(iOS)

import UIKit

extension UIApplication {

    static private func rootViewController() -> UIViewController? {
        var rootVC: UIViewController?
        if #available(iOS 15.0, *) {
            rootVC = UIApplication
                .shared
                .connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .last?
                .rootViewController
        } else {
            rootVC = UIApplication
                .shared
                .connectedScenes
                .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                .last { $0.isKeyWindow }?
                .rootViewController
        }

        return rootVC // ?? UIApplication.shared.keyWindow?.rootViewController
    }

    @MainActor
    static func topViewController(controller: UIViewController? = nil) -> UIViewController? {
        let controller = controller ?? rootViewController()

        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }

}

#endif
