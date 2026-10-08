import SwiftUI

struct ReviewsStrip: View {
    let reviews: [ProfileReview]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reviews")
                .font(.system(.title3, design: .serif).weight(.semibold))
                .foregroundStyle(Color.picardoText)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(reviews) { review in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Text(review.initial)
                                    .font(.headline)
                                    .foregroundStyle(Color.picardoText)
                                    .frame(width: 40, height: 40)
                                    .background(Color.picardoAccent.opacity(0.12), in: Circle())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(review.buyerName)
                                        .font(.subheadline.weight(.semibold))
                                    HStack(spacing: 2) {
                                        ForEach(0..<5, id: \.self) { i in
                                            Image(systemName: i < review.rating ? "star.fill" : "star")
                                                .font(.system(size: 10))
                                                .foregroundStyle(i < review.rating ? Color.brand : Color.picardoDivider)
                                        }
                                    }
                                    .accessibilityLabel("\(review.rating) out of 5 stars")
                                }
                                Spacer()
                            }
                            Text("“\(review.quote)”")
                                .font(.body)
                                .foregroundStyle(Color.picardoText.opacity(0.9))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(review.date)
                                .font(.caption)
                                .foregroundStyle(Color.picardoTextSecondary)
                        }
                        .padding(18)
                        .frame(width: 280, alignment: .leading)
                        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: DesignTokens.radiusLarge, style: .continuous))
                        .cardShadow()
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        }
    }
}
