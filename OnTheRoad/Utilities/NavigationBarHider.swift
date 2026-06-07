import SwiftUI
import UIKit

/// Forces the parent UINavigationController to hide its bar.
/// Use as .background(NavigationBarHider()) when SwiftUI's toolbar modifiers
/// don't reliably suppress the navigation bar on pushed views.
struct NavigationBarHider: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        uiViewController.navigationController?.setNavigationBarHidden(true, animated: false)
    }
}
