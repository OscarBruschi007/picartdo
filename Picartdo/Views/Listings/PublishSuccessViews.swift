import SwiftUI
import UIKit

// MARK: - "Your work is live"

/// The artist's peak moment: the piece hangs on a wall, framed, the moment it goes live.
/// Ends with the two things an artist wants next: show it off, and see it in the studio.
struct ListingLiveView: View {
    enum Kind { case listing, post }

    let kind: Kind
    let image: UIImage?
    let title: String
    let priceLabel: String?
    let caption: String
    var onViewStudio: (() -> Void)?
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hung = false
    @State private var textIn = false

    private var headline: String {
        switch kind {
        case .listing: return "Your work is live."
        case .post: return "Shared with your muses."
        }
    }

    private var shareText: String {
        let name = title.isEmpty ? "my new piece" : "\u{201C}\(title)\u{201D}"
        return "Every piece of art tells a story. Here\u{2019}s mine: \(name), now on Picartdo."
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            Text(kind == .listing ? "NOW ON PICARTDO" : "NEW POST")
                .font(PicardoType.meta(10))
                .kerning(1.2)
                .foregroundStyle(Color.picardoTextSecondary)
                .opacity(textIn ? 1 : 0)

            Text(headline)
                .font(.system(size: 30, weight: .black, design: .serif))
                .foregroundStyle(Color.picardoText)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 24)
                .opacity(textIn ? 1 : 0)

            wall
                .padding(.top, 28)

            VStack(spacing: 4) {
                if !title.isEmpty {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundStyle(Color.picardoText)
                        .multilineTextAlignment(.center)
                }
                if let priceLabel {
                    Text(priceLabel)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.picardoNeonRed)
                }
                Text(kind == .listing
                     ? "Collectors can now discover it on Picartdo."
                     : "It\u{2019}s on your profile and in your muses\u{2019} feeds.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.picardoTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(.top, 22)
            .padding(.horizontal, 32)
            .opacity(textIn ? 1 : 0)

            Spacer(minLength: 24)

            actions
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
                .opacity(textIn ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.picardoBackground.ignoresSafeArea())
        .onAppear {
            // The form's keyboard has no place on a celebration screen.
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            Haptics.success()
            if reduceMotion {
                hung = true
                textIn = true
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.72).delay(0.1)) { hung = true }
                withAnimation(.easeOut(duration: 0.45).delay(0.35)) { textIn = true }
            }
            UIAccessibility.post(notification: .announcement, argument: headline)
        }
    }

    // The piece, framed and hung: same black frame and mat as "Picked for your wall".
    @ViewBuilder
    private var wall: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 230, maxHeight: 280)
                .padding(10)
                .background(Color.picardoPolaroidMat)
                .overlay(Rectangle().stroke(Color.black, lineWidth: 5))
                .shadow(color: .black.opacity(0.22), radius: 14, y: 10)
                .offset(y: hung ? 0 : -40)
                .opacity(hung ? 1 : 0)
                .accessibilityLabel(title.isEmpty ? "Your piece" : title)
        } else {
            // A text post: the words, set like a wall label.
            Text(caption.isEmpty ? "Your post" : "\u{201C}\(caption)\u{201D}")
                .font(.system(size: 17, design: .serif).italic())
                .foregroundStyle(Color.picardoText)
                .multilineTextAlignment(.center)
                .lineLimit(6)
                .padding(24)
                .frame(maxWidth: 280)
                .background(Color.picardoPolaroidMat)
                .overlay(Rectangle().stroke(Color.black, lineWidth: 5))
                .shadow(color: .black.opacity(0.22), radius: 14, y: 10)
                .offset(y: hung ? 0 : -40)
                .opacity(hung ? 1 : 0)
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            shareButton

            if let onViewStudio {
                Button {
                    Haptics.tap()
                    onViewStudio()
                } label: {
                    Text("View in your studio")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.picardoText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.picardoCard, in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.picardoBorder, lineWidth: 1))
                }
                .buttonStyle(PicardoPressStyle())
            }

            Button("Done") {
                Haptics.tap()
                onDone()
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Color.picardoTextSecondary)
            .frame(minHeight: 44)
        }
    }

    @ViewBuilder
    private var shareButton: some View {
        let label = HStack(spacing: 8) {
            Image(systemName: "square.and.arrow.up")
            Text(kind == .listing ? "Share your work" : "Share your post")
        }
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color.picardoNeonRed, in: Capsule())

        if let image {
            let picture = Image(uiImage: image)
            ShareLink(
                item: picture,
                message: Text(shareText),
                preview: SharePreview(title.isEmpty ? "Picartdo" : title, image: picture)
            ) { label }
            .buttonStyle(PicardoPressStyle())
        } else {
            ShareLink(item: shareText) { label }
                .buttonStyle(PicardoPressStyle())
        }
    }
}

// MARK: - "Request sent"

/// After a commission request: who has it, when they'll answer, and what happens next.
struct CommissionSentView: View {
    let artist: Artist
    let summary: [String]
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var firstName: String {
        artist.name.split(separator: " ").first.map(String.init) ?? artist.name
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            ZStack(alignment: .bottomTrailing) {
                ArtworkImage(imageName: artist.avatarImage, contentMode: .fill, maxDimension: 400)
                    .frame(width: 112, height: 112)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color.picardoPolaroidMat, lineWidth: 4))
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 6)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white, Color.picardoSupport)
                    .background(Circle().fill(Color.picardoBackground).padding(2))
                    .scaleEffect(appeared ? 1 : 0.4)
                    .opacity(appeared ? 1 : 0)
            }
            .accessibilityHidden(true)

            Text("Request sent to \(firstName).")
                .font(.system(size: 28, weight: .black, design: .serif))
                .foregroundStyle(Color.picardoText)
                .multilineTextAlignment(.center)
                .padding(.top, 22)
                .padding(.horizontal, 24)

            Text("\(firstName) will review it and reply within 48 hours.")
                .font(.system(size: 15))
                .foregroundStyle(Color.picardoTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 32)

            if !summary.isEmpty {
                Text(summary.joined(separator: " · "))
                    .font(PicardoType.meta(10))
                    .foregroundStyle(Color.picardoTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.picardoCard, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.picardoBorder, lineWidth: 0.5))
                    .padding(.top, 16)
                    .padding(.horizontal, 24)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("What happens next")
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .foregroundStyle(Color.picardoText)
                step(1, "\(firstName) reads your idea and references.")
                step(2, "They reply in Messages with questions or a quote.")
                step(3, "You decide whether to go ahead.")
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.picardoBorder, lineWidth: 0.5))
            .padding(.horizontal, 24)
            .padding(.top, 28)

            Spacer(minLength: 24)

            Button {
                Haptics.tap()
                onDone()
            } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.picardoBackground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.picardoText, in: Capsule())
            }
            .buttonStyle(PicardoPressStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.picardoBackground.ignoresSafeArea())
        .onAppear {
            // The form's keyboard has no place on a celebration screen.
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            Haptics.success()
            if reduceMotion { appeared = true }
            else { withAnimation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.15)) { appeared = true } }
            UIAccessibility.post(notification: .announcement, argument: "Request sent to \(firstName)")
        }
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(n)")
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundStyle(Color.picardoBackground)
                .frame(width: 24, height: 24)
                .background(Color.picardoText, in: Circle())
            Text(text)
                .font(.system(size: 14.5))
                .foregroundStyle(Color.picardoText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
