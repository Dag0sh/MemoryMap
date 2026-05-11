import SwiftUI

struct PinListView: View {
    @ObservedObject var viewModel: MapViewModel
    var onFindOnMap: ((MemoryPin) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedPin: MemoryPin?
    @State private var editPin: MemoryPin?

    private var filteredPins: [MemoryPin] {
        guard !searchText.isEmpty else { return viewModel.pins }
        return viewModel.pins.filter {
            ($0.title ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredPins, id: \.id) { pin in
                    PinListRow(pin: pin)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedPin = pin }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await viewModel.deletePin(pin) }
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }

                            Button { editPin = pin } label: {
                                Label("Изменить", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Поиск по названию")
            .navigationTitle("Воспоминания")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
            .overlay {
                if viewModel.pins.isEmpty {
                    ContentUnavailableView(
                        "Нет воспоминаний",
                        systemImage: "mappin.slash",
                        description: Text("Добавьте первое воспоминание на карте")
                    )
                } else if filteredPins.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .sheet(item: $selectedPin) { pin in
                PinDetailView(pin: pin) {
                    // "Найти на карте": закрываем детали, потом список, потом центрируем карту
                    selectedPin = nil
                    dismiss()
                    onFindOnMap?(pin)
                }
            }
            .sheet(item: $editPin) { pin in
                EditMemoryView(viewModel: viewModel, pin: pin)
            }
        }
    }
}

// MARK: - Row

private struct PinListRow: View {
    @ObservedObject var pin: MemoryPin

    private var backgroundColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .teal, .indigo]
        return colors[abs(pin.id.hashValue) % colors.count]
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 44, height: 44)
                Image(systemName: pin.safeSticker)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(pin.title ?? "Без названия")
                    .font(.headline)

                if let date = pin.date {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
