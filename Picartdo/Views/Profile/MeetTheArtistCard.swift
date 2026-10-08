import SwiftUI

struct MeetTheArtistCard: View {
    let sold: String
    let collectors: String
    let years: String
    let bio: String

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Meet the artist")
                .font(.system(.title3, design: .serif).weight(.semibold))
                .foregroundStyle(Color.picardoText)

            HStack(spacing: 0) {
                fact(sold, "Works sold")
                Rectangle().fill(Color.picardoDivider).frame(width: 1, height: 36)
                fact(collectors, "Collectors")
                Rectangle().fill(Color.picardoDivider).frame(width: 1, height: 36)
                fact(years, "Years creating")
            }

            Text(bio)
                .font(.system(.title3, design: .serif))
                .foregroundStyle(Color.picardoText.opacity(0.9))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: DesignTokens.radiusLarge, style: .continuous))
        .cardShadow()
        .padding(.horizontal, 20)
        .accessibilityElement(children: .contain)
    }

    private func fact(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title2, design: .serif).weight(.bold))
                .foregroundStyle(Color.picardoText)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.picardoTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}
