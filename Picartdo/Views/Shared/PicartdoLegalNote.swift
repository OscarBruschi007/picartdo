import SwiftUI

/// The small line above a commitment ("By continuing, you agree to…"). It tells people
/// someone stands behind the app, and both documents open in place.
struct PicartdoLegalNote: View {
    /// Starts the sentence, e.g. "By continuing" or "By paying".
    var lead: String = "By continuing"
    var alignment: TextAlignment = .center

    private enum Doc: String, Identifiable {
        case terms, privacy
        var id: String { rawValue }
    }

    @State private var shown: Doc?

    private var text: AttributedString {
        var s = AttributedString("\(lead), you agree to Picartdo\u{2019}s ")
        var terms = AttributedString("Terms of Use")
        terms.link = URL(string: "picartdo-legal://terms")
        terms.underlineStyle = .single
        var and = AttributedString(" and ")
        var privacy = AttributedString("Privacy Policy")
        privacy.link = URL(string: "picartdo-legal://privacy")
        privacy.underlineStyle = .single
        let end = AttributedString(".")
        and.underlineStyle = nil
        s.append(terms); s.append(and); s.append(privacy); s.append(end)
        return s
    }

    var body: some View {
        Text(text)
            .font(.system(size: 11.5))
            .foregroundStyle(Color.picardoTextSecondary)
            .tint(Color.picardoTextSecondary)
            .multilineTextAlignment(alignment)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.openURL, OpenURLAction { url in
                switch url.host {
                case "terms": shown = .terms
                case "privacy": shown = .privacy
                default: return .systemAction
                }
                return .handled
            })
            .sheet(item: $shown) { doc in
                switch doc {
                case .terms: LegalSettingsView(title: "Terms of use", copy: LegalCopy.terms)
                case .privacy: LegalSettingsView(title: "Privacy policy", copy: LegalCopy.privacy)
                }
            }
    }
}
