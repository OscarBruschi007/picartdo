import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// Shared small components used across the app.
//
// These used to be an Off-White™ / Virgil Abloh tribute: all-caps stencil
// type, quotation marks around every label, arrow annotations, zip-tie tag
// borders. That fought with the calmer editorial system in Typography.swift
// and DesignSystem.swift, and made the app feel like two different products.
// Same names and call sites everywhere they're used, simpler look: sentence
// case, one weight, no borders or arrows. Typography carries the brand now,
// not decoration.
// ─────────────────────────────────────────────────────────────────────────────

// MARK: – Section header (title + small eyebrow above it)

struct OWQuoteHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.picardoTextSecondary)
            }
            Text(title)
                .font(PicardoType.section())
                .foregroundStyle(Color.picardoText)
        }
    }
}

// MARK: – Small inline tag

struct OWArrowTag: View {
    let label: String
    var opacity: Double = 0.40

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.picardoTextSecondary.opacity(max(opacity, 0.7)))
    }
}

// MARK: – Small badge

struct OWTagBadge: View {
    let text: String
    var line2: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.picardoText)
            if let line2 {
                Text(line2)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.picardoTextSecondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: – Divider, optionally with a small centered label

struct OWRuleDivider: View {
    var label: String? = nil

    var body: some View {
        if let label {
            HStack(spacing: 10) {
                Rectangle().frame(height: 1).foregroundStyle(Color.picardoDivider.opacity(0.6))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.picardoTextSecondary)
                    .fixedSize()
                Rectangle().frame(height: 1).foregroundStyle(Color.picardoDivider.opacity(0.6))
            }
        } else {
            Rectangle().frame(height: 1).foregroundStyle(Color.picardoDivider.opacity(0.6))
        }
    }
}

// MARK: – Brand credit line

struct OWCreditLine: View {
    var brand: String = "Picartdo"
    var tagline: String = "Art marketplace"

    var body: some View {
        HStack(spacing: 5) {
            Text(brand)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.picardoText)
            Text(tagline)
                .font(.system(size: 12))
                .foregroundStyle(Color.picardoTextSecondary)
        }
    }
}

// MARK: – Percentage label

struct OWPercentLabel: View {
    let value: String    // e.g. "100"
    var unit: String = "%"

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text(value)
                .font(.system(size: 13, weight: .semibold))
            Text(unit)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(Color.picardoTextSecondary)
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 24) {
        OWQuoteHeader(title: "Browse", subtitle: "By category")
        OWArrowTag(label: "Original artwork")
        OWTagBadge(text: "Tattoo art", line2: "Book an artist")
        OWRuleDivider(label: "Popular")
        OWCreditLine()
        OWPercentLabel(value: "3")
    }
    .padding(32)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(Color(.systemBackground))
}
