import SwiftUI

/// The Services tab's "Art Exhibitions" page body: everything here is about real
/// exhibitions and events, in the same clean layout as the full guide. Search, the
/// user's tickets, the guide (Exhibitions | Events), and how to visit.
struct ExhibitionsServiceSection: View {
    @State private var store = EventTicketStore.shared
    @State private var query = ""
    @State private var shownTicket: EventTicket?

    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespaces) }

    private var results: [ArtEventItem] {
        let q = trimmedQuery.lowercased()
        return ArtEventItem.samples
            .filter {
                $0.title.lowercased().contains(q)
                || $0.summary.lowercased().contains(q)
                || $0.type.lowercased().contains(q)
            }
            .sorted { ($0.startDate ?? .distantPast) < ($1.startDate ?? .distantPast) }
    }

    /// Tickets for things that haven't happened yet, soonest first.
    private var upcomingTickets: [EventTicket] {
        let today = Calendar.current.startOfDay(for: Date())
        return store.tickets
            .filter { $0.visitDate >= today }
            .sorted { $0.visitDate < $1.visitDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            searchField
                .padding(.bottom, 24)

            if !trimmedQuery.isEmpty {
                if results.isEmpty {
                    Text("Nothing matches \u{201C}\(trimmedQuery)\u{201D} yet.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.picardoTextSecondary)
                        .padding(.horizontal, 24)
                } else {
                    EventListSection(
                        title: "\(results.count) result\(results.count == 1 ? "" : "s")",
                        items: results
                    ) { event in
                        if event.isExhibition {
                            ExhibitionListRow(event: event)
                        } else {
                            EventCalendarRow(event: event)
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 30) {
                    if !upcomingTickets.isEmpty { ticketsRow }
                    EventsGuideContent()
                    planYourVisit
                }
            }
        }
        .fullScreenCover(item: $shownTicket) { ticket in
            EventTicketView(ticket: ticket)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search exhibitions, talks, workshops", text: $query)
                .font(.system(size: 15))
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(Color(.systemBackground), in: Capsule())
        .shadow(color: .black.opacity(0.10), radius: 6, y: 2)
        .padding(.horizontal, 20)
    }

    /// Same heading style as the guide's list sections.
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .bold, design: .serif))
            .foregroundStyle(Color.picardoText)
            .padding(.horizontal, 24)
    }

    // MARK: - Your tickets

    private var ticketsRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Your tickets")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(upcomingTickets) { ticket in
                        Button { shownTicket = ticket } label: { ticketChip(ticket) }
                            .buttonStyle(PicardoPressStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func ticketChip(_ ticket: EventTicket) -> some View {
        HStack(spacing: 12) {
            Color.clear
                .frame(width: 52, height: 52)
                .overlay { ArtworkImage(imageName: ticket.imageName, contentMode: .fill, maxDimension: 200).allowsHitTesting(false) }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(ticket.eventTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.picardoText)
                    .lineLimit(1)
                Text("\(ticket.visitDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())) · Admit \(ticket.quantity)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.picardoTextSecondary)
            }
            .frame(width: 170, alignment: .leading)
            Image(systemName: "qrcode")
                .font(.system(size: 22))
                .foregroundStyle(Color.picardoText)
        }
        .padding(10)
        .padding(.trailing, 4)
        .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.black.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Plan your visit (from ago.ca/visit)

    private var planYourVisit: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Plan your visit")

            VStack(alignment: .leading, spacing: 16) {
                visitRow(icon: "mappin.and.ellipse", title: "317 Dundas Street West, Toronto",
                         detail: "Three blocks west of University Ave · St Patrick subway station")
                visitRow(icon: "clock", title: "Tue, Thu 10:30 am – 5 pm · Wed, Fri until 9 pm",
                         detail: "Sat & Sun 10:30 am – 5:30 pm · Closed Mondays")
                visitRow(icon: "ticket", title: "Adults CA$30 · Youth (10–17) CA$15",
                         detail: "Free for kids under 10, Indigenous Peoples, and Ontarians under 25 · Free first Wednesday nights, 6–9 pm")

                if let maps = URL(string: "https://maps.apple.com/?q=Art%20Gallery%20of%20Ontario&address=317%20Dundas%20St%20W,%20Toronto,%20ON") {
                    Link(destination: maps) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            Text("Get directions")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color.black, in: Capsule())
                    }
                }
            }
            .padding(16)
            .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.black.opacity(0.06), lineWidth: 1))
            .padding(.horizontal, 20)
        }
    }

    private func visitRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.picardoText)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(Color.picardoText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.picardoTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}
