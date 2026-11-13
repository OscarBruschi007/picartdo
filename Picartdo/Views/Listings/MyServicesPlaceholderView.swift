import PhotosUI
import SwiftUI

struct MyServicesRoute: Hashable {}

/// Offer a service when there is no studio. My Studio once one is published.
struct MyServicesPlaceholderView: View {
    @State private var store = StudioStore.shared

    var body: some View {
        Group {
            if store.hasStudio {
                MyStudioDashboard()
            } else {
                StudioSetupView()
            }
        }
        .background(Color.picardoBackground.ignoresSafeArea())
    }
}

private struct StudioSetupView: View {
    @State private var store = StudioStore.shared
    @State private var step = 1
    @State private var name = ""
    @State private var city = ""
    @State private var bio = ""
    @State private var coverData: Data?
    @State private var avatarData: Data?
    @State private var coverItem: PhotosPickerItem?
    @State private var avatarItem: PhotosPickerItem?
    @State private var serviceTitle = ""
    @State private var serviceType = "Commission"
    @State private var price = ""
    @State private var delivery = ""
    @State private var summary = ""
    @State private var serviceCover: Data?
    @State private var serviceItem: PhotosPickerItem?

    private let types = ["Commission", "In person studio", "Class", "Workshop"]
    private let coverAsset = "art_12"
    private let avatarAsset = "avatar_01"
    private let serviceAsset = "art_04"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Step \(step) of 3")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.picardoTextSecondary)
                if step == 1 { stepOne }
                if step == 2 { stepTwo }
                if step == 3 { stepThree }
            }
            .padding(16)
            .padding(.bottom, 120)
        }
        .navigationTitle(step == 3 ? "Preview" : "Offer a service")
        .navigationBarTitleDisplayMode(.inline)
        .picardoPushedScreen()
        .onChange(of: coverItem) { _, item in load(item, into: { coverData = $0 }) }
        .onChange(of: avatarItem) { _, item in load(item, into: { avatarData = $0 }) }
        .onChange(of: serviceItem) { _, item in load(item, into: { serviceCover = $0 }) }
    }

    private var stepOne: some View {
        VStack(alignment: .leading, spacing: 12) {
            field("Studio name", text: $name)
            field("City", text: $city)
            TextField("Bio", text: $bio, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
                .padding(12)
                .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            photoRow("Cover", item: $coverItem, data: coverData, asset: coverAsset)
            photoRow("Avatar", item: $avatarItem, data: avatarData, asset: avatarAsset)
            nextButton(enabled: !name.trimmingCharacters(in: .whitespaces).isEmpty && !city.trimmingCharacters(in: .whitespaces).isEmpty && !bio.trimmingCharacters(in: .whitespaces).isEmpty) {
                step = 2
            }
        }
    }

    private var stepTwo: some View {
        VStack(alignment: .leading, spacing: 12) {
            field("Service title", text: $serviceTitle)
            Picker("Type", selection: $serviceType) {
                ForEach(types, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.segmented)
            field("Price", text: $price)
                .keyboardType(.numberPad)
            field("Delivery time", text: $delivery)
            TextField("Short description", text: $summary)
                .padding(12)
                .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            photoRow("Cover image", item: $serviceItem, data: serviceCover, asset: serviceAsset)
            nextButton(enabled: !serviceTitle.trimmingCharacters(in: .whitespaces).isEmpty && Int(price) != nil && !delivery.trimmingCharacters(in: .whitespaces).isEmpty) {
                step = 3
            }
        }
    }

    private var stepThree: some View {
        VStack(alignment: .leading, spacing: 14) {
            StudioStill(jpeg: coverData, asset: coverAsset)
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            Text(name)
                .font(.system(size: 22, weight: .bold, design: .serif))
            Text(city)
                .foregroundStyle(Color.picardoTextSecondary)
            Text(bio)
                .foregroundStyle(Color.picardoTextSecondary)
                .lineLimit(2)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(serviceTitle).font(.headline)
                    Text(serviceType).font(.subheadline).foregroundStyle(Color.picardoTextSecondary)
                    Text(delivery).font(.subheadline).foregroundStyle(Color.picardoTextSecondary)
                }
                Spacer()
                Text("From $\(price)")
                    .font(.headline)
                    .foregroundStyle(Color.picardoNeonRed)
            }
            Button {
                publish()
            } label: {
                Text("Publish")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.picardoNeonRed, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .padding(12)
            .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func photoRow(_ title: String, item: Binding<PhotosPickerItem?>, data: Data?, asset: String) -> some View {
        HStack(spacing: 12) {
            StudioStill(jpeg: data, asset: asset)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            PhotosPicker(selection: item, matching: .images) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            Spacer()
        }
    }

    private func nextButton(enabled: Bool, action: @escaping () -> Void) -> some View {
        Button("Continue", action: action)
            .font(.headline)
            .foregroundStyle(enabled ? Color.picardoText : Color.picardoTextSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .disabled(!enabled)
            .padding(.top, 8)
    }

    private func load(_ item: PhotosPickerItem?, into set: @escaping (Data?) -> Void) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                set(StudioStore.jpeg(image))
            }
        }
    }

    private func publish() {
        Haptics.success()
        let service = OwnedService(
            id: UUID(),
            title: serviceTitle.trimmingCharacters(in: .whitespaces),
            summary: summary.trimmingCharacters(in: .whitespaces),
            type: serviceType,
            priceAmount: Int(price) ?? 0,
            delivery: delivery.trimmingCharacters(in: .whitespaces),
            coverJPEG: serviceCover,
            coverAsset: serviceAsset,
            isActive: true
        )
        store.publish(OwnedStudio(
            name: name.trimmingCharacters(in: .whitespaces),
            city: city.trimmingCharacters(in: .whitespaces),
            bio: bio.trimmingCharacters(in: .whitespaces),
            coverJPEG: coverData,
            avatarJPEG: avatarData,
            coverAsset: coverAsset,
            avatarAsset: avatarAsset,
            services: [service]
        ))
    }
}

private struct MyStudioDashboard: View {
    @State private var store = StudioStore.shared
    @State private var editing: OwnedService?
    @State private var adding = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                if let studio = store.studio {
                    Text(studio.name)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                    NavigationLink(value: StudioDestination.mine) {
                        Text("View my Studio")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.picardoText)
                    }
                    .buttonStyle(.plain)

                    Text("Services")
                        .font(.headline)
                    ForEach(studio.services) { service in
                        serviceRow(service)
                    }
                    Button {
                        adding = true
                    } label: {
                        Text("Add service")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Text("Requests")
                        .font(.headline)
                    PicartdoEmptyState(icon: "tray", title: "No requests yet.")
                }
            }
            .padding(16)
            .padding(.bottom, 120)
        }
        .navigationTitle("My Studio")
        .navigationBarTitleDisplayMode(.inline)
        .picardoPushedScreen()
        .sheet(item: $editing) { service in
            ServiceEditor(service: service) { store.update($0) }
        }
        .sheet(isPresented: $adding) {
            ServiceEditor(service: nil) { store.addService($0) }
        }
    }

    private func serviceRow(_ service: OwnedService) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(service.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(service.priceLabel)
                    .foregroundStyle(Color.picardoNeonRed)
                    .font(.subheadline.weight(.semibold))
            }
            HStack {
                Text(service.isActive ? "Active" : "Paused")
                    .font(.subheadline)
                    .foregroundStyle(Color.picardoTextSecondary)
                Spacer()
                Toggle("Active", isOn: Binding(
                    get: { service.isActive },
                    set: { store.setActive(id: service.id, isActive: $0) }
                ))
                .labelsHidden()
                Button("Edit") { editing = service }
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(12)
        .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct ServiceEditor: View {
    let service: OwnedService?
    let onSave: (OwnedService) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var type = "Commission"
    @State private var price = ""
    @State private var delivery = ""
    @State private var summary = ""
    @State private var cover: Data?
    @State private var coverItem: PhotosPickerItem?
    private let types = ["Commission", "In person studio", "Class", "Workshop"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                Picker("Type", selection: $type) {
                    ForEach(types, id: \.self) { Text($0).tag($0) }
                }
                TextField("Price", text: $price)
                    .keyboardType(.numberPad)
                TextField("Delivery time", text: $delivery)
                TextField("Short description", text: $summary)
                PhotosPicker("Cover image", selection: $coverItem, matching: .images)
            }
            .navigationTitle(service == nil ? "Add service" : "Edit service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || Int(price) == nil)
                }
            }
            .onAppear {
                if let service {
                    title = service.title
                    type = service.type
                    price = "\(service.priceAmount)"
                    delivery = service.delivery
                    summary = service.summary
                    cover = service.coverJPEG
                }
            }
            .onChange(of: coverItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        cover = StudioStore.jpeg(image)
                    }
                }
            }
        }
    }

    private func save() {
        let next = OwnedService(
            id: service?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespaces),
            summary: summary.trimmingCharacters(in: .whitespaces),
            type: type,
            priceAmount: Int(price) ?? 0,
            delivery: delivery.trimmingCharacters(in: .whitespaces),
            coverJPEG: cover,
            coverAsset: service?.coverAsset ?? "art_04",
            isActive: service?.isActive ?? true
        )
        onSave(next)
        dismiss()
    }
}
