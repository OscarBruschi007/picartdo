import SwiftUI

// MARK: - Event / exhibition detail

/// One exhibition or event: the image, when and where, what it is,
/// and the button to get tickets (or show the ticket you already have).
struct CityEventDetailView: View {
    let event: ArtEventItem

    @State private var store = EventTicketStore.shared
    @State private var showCheckout = false
    @State private var shownTicket: EventTicket?

    private var existingTicket: EventTicket? { store.ticket(for: event) }

    var body: some View {
        ZStack(alignment: .bottom) {
            PicartdoBackground().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    hero

                    VStack(alignment: .leading, spacing: 0) {
                        Text(event.type.uppercased())
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(Color.picardoGold)

                        Text(event.title)
                            .font(.system(size: 28, weight: .black, design: .serif))
                            .foregroundStyle(Color.picardoText)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 14) {
                            infoRow(icon: "calendar", title: event.dateLabel, detail: nil)
                            infoRow(icon: "clock", title: event.timeLabel, detail: event.isExhibition ? "Closed Mondays" : nil)
                            infoRow(icon: "mappin.and.ellipse", title: event.venue, detail: event.address)
                            infoRow(icon: "ticket", title: event.priceLabel, detail: event.priceNote)
                        }
                        .padding(16)
                        .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                        )
                        .padding(.top, 18)

                        Text("About")
                            .font(.system(size: 20, weight: .black, design: .serif))
                            .foregroundStyle(Color.picardoText)
                            .padding(.top, 26)
                        Text(event.summary)
                            .font(.system(size: 17, design: .serif))
                            .foregroundStyle(Color.picardoText.opacity(0.85))
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 8)

                        Link(destination: event.sourceURL) {
                            HStack(spacing: 6) {
                                Text("More on ago.ca")
                                Image(systemName: "arrow.up.right")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.picardoGold)
                        }
                        .padding(.top, 14)
                    }
                    .padding(20)
                    .padding(.bottom, 200)
                }
            }
            .ignoresSafeArea(edges: .top)

            ticketBar
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showCheckout) {
            ApplePayCheckoutSheet(event: event) { ticket in
                showCheckout = false
                Task {
                    try? await Task.sleep(for: .milliseconds(450))
                    shownTicket = ticket
                }
            }
            // Sized to its content, like Apple Pay, instead of a full-height sheet.
            .presentationDetents([.height(event.isExhibition ? 720 : (event.isFree ? 580 : 660))])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(38)
        }
        .fullScreenCover(item: $shownTicket) { ticket in
            EventTicketView(ticket: ticket)
        }
    }

    private var hero: some View {
        Color.clear
            .frame(height: 380)
            .overlay {
                ArtworkImage(imageName: event.imageName, contentMode: .fill, maxDimension: 1200)
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .bottom) {
                LinearGradient(colors: [.clear, .black.opacity(0.35)], startPoint: .center, endPoint: .bottom)
            }
            .clipped()
    }

    private func infoRow(icon: String, title: String, detail: String?) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.picardoText)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.picardoText)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail {
                    Text(detail)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.picardoTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var ticketBar: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                if let existingTicket {
                    Text("You're going")
                        .font(.system(size: 16, weight: .bold))
                    Text("\(existingTicket.quantity) ticket\(existingTicket.quantity == 1 ? "" : "s") · \(existingTicket.visitDate.formatted(.dateTime.month(.abbreviated).day()))")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                } else {
                    Text(event.priceLabel)
                        .font(.system(size: 18, weight: .bold))
                    Text(event.isFree ? "Registration required" : "per person")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                Haptics.tap()
                if let existingTicket {
                    shownTicket = existingTicket
                } else {
                    showCheckout = true
                }
            } label: {
                Text(existingTicket != nil ? "View ticket" : (event.isFree ? "Register" : "Get tickets"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 26)
                    .frame(height: 50)
                    .background(Color.black, in: Capsule())
            }
            .buttonStyle(PicardoPressStyle())
        }
        .padding(.leading, 20)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.black.opacity(0.06), lineWidth: 1))
        .shadow(color: .black.opacity(0.15), radius: 16, y: 6)
        .padding(.horizontal, 16)
        // Float above the app's tab bar, which sits over every screen.
        .padding(.bottom, 96)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CityEventDetailView(event: ArtEventItem.samples[0])
    }
}
