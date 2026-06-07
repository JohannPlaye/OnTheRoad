import SwiftUI
import UIKit

/// A zero-size UIView that walks the responder chain to find
/// the parent UINavigationController and hides its bar.
/// Use as .background(NavBarHider()) on pushed views.
struct NavBarHider: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isHidden = true
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        DispatchQueue.main.async {
            view.nearestNavigationController?.setNavigationBarHidden(true, animated: false)
        }
    }
}

private extension UIView {
    var nearestNavigationController: UINavigationController? {
        var responder: UIResponder? = self.next
        while let r = responder {
            if let nav = r as? UINavigationController { return nav }
            if let vc = r as? UIViewController { return vc.navigationController }
            responder = r.next
        }
        return nil
    }
}
