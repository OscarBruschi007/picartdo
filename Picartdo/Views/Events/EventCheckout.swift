import SwiftUI
import LocalAuthentication
import CoreImage.CIFilterBuiltins

// MARK: - Apple Pay–style checkout

/// A checkout sheet modelled on Apple Pay: review, confirm with Face ID, done.
/// Demo only. No card is charged; a successful Face ID check issues the ticket.
struct ApplePayCheckoutSheet: View {
    let event: ArtEventItem
    let onComplete: (EventTicket) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // Fixed colours like the real Apple Pay button; partial-height glass sheets would tint .primary grey.
    private var payInk: Color { colorScheme == .dark ? .white : .black }
    private var payLabel: Color { colorScheme == .dark ? .black : .white }

    private enum Phase { case review, scanning, done }

    @State private var phase: Phase = .review
    @State private var quantity = 1
    @State private var selectedDay: Date?
    @State private var errorText: String?

    init(event: ArtEventItem, onComplete: @escaping (EventTicket) -> Void) {
        self.event = event
        self.onComplete = onComplete
        // Pick the first available day up front so the pay button is ready on first draw.
        _selectedDay = State(initialValue: event.bookableDays().first)
    }

    private var days: [Date] { event.bookableDays() }
    private var total: Double { event.price * Double(quantity) }
    private var totalLabel: String {
        total == 0 ? "Free" : total.formatted(.currency(code: "CAD"))
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    summaryRow
                    divider
                    dateSection
                    divider
                    quantityRow
                    divider
                    if !event.isFree {
                        paymentRow
                        divider
                    }
                    totalRow
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Text("Demo checkout · no payment is taken")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.top, 10)
            }
            .disabled(phase != .review)

            confirmArea
        }
        .background(Color(.systemGroupedBackground))
        .interactiveDismissDisabled(phase != .review)
    }

    // MARK: Pieces

    private var header: some View {
        HStack {
            HStack(spacing: 2) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 22, weight: .semibold))
                    .offset(y: -1)
                Text("Pay")
                    .font(.system(size: 24, weight: .semibold))
            }
            .foregroundStyle(.primary)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(Color(.tertiarySystemFill), in: Circle())
            }
            .disabled(phase != .review)
            .accessibilityLabel("Cancel")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private var divider: some View {
        Divider().padding(.leading, 16)
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            Color.clear
                .frame(width: 52, height: 52)
                .overlay { ArtworkImage(imageName: event.imageName, contentMode: .fill, maxDimension: 200) }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(2)
                Text("\(event.venue) · \(event.type)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
    }

    @ViewBuilder
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DATE")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            if event.isExhibition {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(days, id: \.self) { day in
                            let on = selectedDay == day
                            Button {
                                Haptics.select()
                                selectedDay = day
                            } label: {
                                VStack(spacing: 2) {
                                    Text(day.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                                        .font(.system(size: 10, weight: .semibold))
                                    Text(day.formatted(.dateTime.day()))
                                        .font(.system(size: 18, weight: .bold))
                                    Text(day.formatted(.dateTime.month(.abbreviated)))
                                        .font(.system(size: 10))
                                }
                                .foregroundStyle(on ? Color.white : Color.primary)
                                .frame(width: 52, height: 64)
                                .background(on ? Color.accentColor : Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Text(selectedDay.map { event.timeLabel(on: $0) } ?? event.timeLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            } else {
                Text("\(event.dateLabel) · \(event.timeLabel)")
                    .font(.system(size: 15, weight: .medium))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
    }

    private var quantityRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("TICKETS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(event.isFree ? event.priceNote : "\(event.priceLabel) · \(event.priceNote)")
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer()
            HStack(spacing: 0) {
                stepButton("minus", enabled: quantity > 1) { quantity -= 1 }
                Text("\(quantity)")
                    .font(.system(size: 17, weight: .semibold))
                    .monospacedDigit()
                    .frame(width: 34)
                stepButton("plus", enabled: quantity < 8) { quantity += 1 }
            }
        }
        .padding(14)
    }

    private func stepButton(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.select()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .frame(width: 32, height: 32)
                .background(Color(.tertiarySystemFill), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
    }

    private var paymentRow: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.12, green: 0.12, blue: 0.14), Color(red: 0.32, green: 0.32, blue: 0.36)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 46, height: 30)
                .overlay(alignment: .bottomTrailing) {
                    Text("DEMO")
                        .font(.system(size: 6.5, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(3)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text("Demo Card")
                    .font(.system(size: 15, weight: .semibold))
                Text("No real payment")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
    }

    private var totalRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(event.isFree ? "REGISTER WITH \(event.venue.uppercased())" : "PAY \(event.venue.uppercased())")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Spacer()
            Text(totalLabel)
                .font(.system(size: 22, weight: .bold))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy, value: quantity)
        }
        .padding(14)
    }

    @ViewBuilder
    private var confirmArea: some View {
        VStack(spacing: 12) {
            switch phase {
            case .review:
                if let errorText {
                    Text(errorText)
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                }
                Button(action: confirm) {
                    HStack(spacing: 8) {
                        Image(systemName: "faceid")
                            .font(.system(size: 19, weight: .medium))
                        Text(event.isFree ? "Register with Face ID" : "Pay with Face ID")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(payLabel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(payInk, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(PicardoPressStyle())
                .disabled(selectedDay == nil)
            case .scanning:
                VStack(spacing: 10) {
                    Image(systemName: "faceid")
                        .font(.system(size: 54, weight: .light))
                        .foregroundStyle(Color.accentColor)
                        .symbolEffect(.pulse, options: .repeating)
                    Text("Face ID")
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(height: 96)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            case .done:
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 54, weight: .light))
                        .foregroundStyle(Color.accentColor)
                        .symbolEffect(.bounce, value: phase == .done)
                    Text("Done")
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(height: 96)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.snappy, value: phase)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    // MARK: Face ID

    private func confirm() {
        guard let day = selectedDay else { return }
        errorText = nil
        Haptics.tap()
        phase = .scanning

        Task { @MainActor in
            let approved = await authenticate()
            guard approved else {
                phase = .review
                errorText = "Face ID didn't go through. Try again."
                return
            }
            phase = .done
            Haptics.success()
            let ticket = EventTicketStore.shared.issue(for: event, on: day, quantity: quantity)
            try? await Task.sleep(for: .milliseconds(900))
            onComplete(ticket)
        }
    }

    /// Real Face ID when the device has it set up. If the device has no biometrics
    /// enrolled (common in the Simulator), the scan is played as an animation and approved.
    private func authenticate() async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        var error: NSError?
        let reason = event.isFree ? "Register for \(event.title)" : "Pay \(totalLabel) to \(event.venue)"
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            try? await Task.sleep(for: .milliseconds(1300))
            return true
        }
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch {
            return false
        }
    }
}

// MARK: - Ticket

/// The ticket after paying or registering: QR code to scan at the door, plus the basics.
struct EventTicketView: View {
    let ticket: EventTicket
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.08).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack {
                        Text(ticket.isFree ? "You're registered" : "You're going")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Button("Done") { dismiss() }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                    ticketCard
                        .padding(.horizontal, 18)

                    Text("Show this QR code at the entrance. Your ticket is also saved on the event page.")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 18)
                        .padding(.bottom, 30)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { Haptics.success() }
    }

    private var ticketCard: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: 150)
                .overlay { ArtworkImage(imageName: ticket.imageName, contentMode: .fill, maxDimension: 900) }
                .overlay(alignment: .bottomLeading) {
                    Text(ticket.eventType.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.black.opacity(0.55), in: Capsule())
                        .padding(12)
                }
                .clipped()

            VStack(alignment: .leading, spacing: 16) {
                Text(ticket.eventTitle)
                    .font(.system(size: 22, weight: .black, design: .serif))
                    .foregroundStyle(.black)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .top, spacing: 18) {
                    field("DATE", ticket.visitDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year()))
                    field("ADMIT", "\(ticket.quantity)")
                }
                field("TIME", ticket.timeLabel)
                field("VENUE", "\(ticket.venue)\n\(ticket.address)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)

            perforation

            VStack(spacing: 12) {
                QRCodeImage(payload: ticket.qrPayload)
                    .frame(width: 190, height: 190)
                    .accessibilityLabel("Ticket QR code")
                Text(ticket.confirmation)
                    .font(.system(size: 17, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(.black)
                Text(ticket.isFree ? "Free registration" : "Paid \(ticket.total.formatted(.currency(code: "CAD"))) · Demo")
                    .font(.system(size: 12))
                    .foregroundStyle(.black.opacity(0.5))
            }
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 24, y: 12)
    }

    private func field(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(.black.opacity(0.45))
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The torn-ticket line: two notches and a dashed rule.
    private var perforation: some View {
        ZStack {
            Line()
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                .foregroundStyle(.black.opacity(0.18))
                .frame(height: 1)
                .padding(.horizontal, 22)
            HStack {
                Circle().fill(Color(red: 0.07, green: 0.07, blue: 0.08)).frame(width: 26, height: 26).offset(x: -13)
                Spacer()
                Circle().fill(Color(red: 0.07, green: 0.07, blue: 0.08)).frame(width: 26, height: 26).offset(x: 13)
            }
        }
        .frame(height: 26)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: CGPoint(x: rect.minX, y: rect.midY))
                p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            }
        }
    }
}

/// A crisp QR code for a string, drawn with Core Image.
struct QRCodeImage: View {
    let payload: String

    var body: some View {
        if let image = Self.render(payload) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "qrcode")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.black)
        }
    }

    private static func render(_ text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
              let cgImage = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

#Preview("Checkout") {
    ApplePayCheckoutSheet(event: ArtEventItem.events[0]) { _ in }
}
