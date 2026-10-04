import UIKit
import UniformTypeIdentifiers

/// Share extension for Safari and other apps: takes the shared web address and opens
/// FavoriteRecipes' web import with it. The extension has no screen of its own.
@objc(ShareViewController)
final class ShareViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task { await handOverSharedLink() }
    }

    // MARK: - Hand over

    private func handOverSharedLink() async {
        guard let address = await sharedAddress(), let link = importLink(forAddress: address) else {
            extensionContext?.cancelRequest(withError: CocoaError(.userCancelled))
            return
        }
        openInApp(link)
        extensionContext?.completeRequest(returningItems: nil)
    }

    /// `favoriterecipes://import?url=<address>`, the same link the app handles itself.
    private func importLink(forAddress address: String) -> URL? {
        var components = URLComponents()
        components.scheme = "favoriterecipes"
        components.host = "import"
        components.queryItems = [URLQueryItem(name: "url", value: address)]
        return components.url
    }

    // MARK: - Reading what was shared

    /// The shared page address: a URL item, or the first web address inside shared text.
    private func sharedAddress() async -> String? {
        let items = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
        let providers = items.flatMap { $0.attachments ?? [] }

        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            if let item = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier),
               let url = item as? URL, url.scheme?.hasPrefix("http") == true {
                return url.absoluteString
            }
        }
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            if let item = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier),
               let text = item as? String, let address = firstWebAddress(in: text) {
                return address
            }
        }
        return nil
    }

    private func firstWebAddress(in text: String) -> String? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..., in: text)
        let url = detector?.matches(in: text, range: range).compactMap(\.url).first { $0.scheme?.hasPrefix("http") == true }
        return url?.absoluteString
    }

    // MARK: - Opening the app

    /// Extensions may not use `UIApplication.open` directly, so this finds the host application
    /// in the responder chain and calls it through the Objective-C runtime.
    private func openInApp(_ url: URL) {
        typealias OpenFunction = @convention(c) (
            AnyObject, Selector, URL, [UIApplication.OpenExternalURLOptionsKey: Any], ((Bool) -> Void)?
        ) -> Void
        let selector = NSSelectorFromString("openURL:options:completionHandler:")

        var responder: UIResponder? = self
        while let current = responder {
            if current is UIApplication, current.responds(to: selector) {
                let implementation = unsafeBitCast(current.method(for: selector), to: OpenFunction.self)
                implementation(current, selector, url, [:], nil)
                return
            }
            responder = current.next
        }
    }
}
