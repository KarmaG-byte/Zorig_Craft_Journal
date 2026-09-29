import SwiftUI
import CoreData
import UIKit

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CraftEntry.date, ascending: false)],
        animation: .default
    ) private var entries: FetchedResults<CraftEntry>

    @State private var showingAddEntry = false
    @State private var deleteError: String?
    @State private var searchText = ""
    @State private var selectedCraft = "All crafts"

    private var filteredEntries: [CraftEntry] {
        entries.filter { entry in
            (selectedCraft == "All crafts" || entry.craftType == selectedCraft) &&
            (searchText.isEmpty || (entry.title ?? "").localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if filteredEntries.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: entries.isEmpty ? "book.closed" : "magnifyingglass")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text(entries.isEmpty ? "Your craft journal is empty" : "No matching entries")
                                .font(.headline)
                            Text(entries.isEmpty ? "Tap + to add your first craft." : "Try another search or craft filter.")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
                    } else {
                        ForEach(filteredEntries) { entry in
                            NavigationLink {
                                EntryDetailView(entry: entry)
                            } label: {
                                EntryRow(entry: entry)
                            }
                        }
                        .onDelete(perform: deleteEntries)
                    }
                } header: {
                    Text("\(entries.count) \(entries.count == 1 ? "entry" : "entries")")
                }
            }
            .navigationTitle("Craft Journal")
            .searchable(text: $searchText, prompt: "Search titles")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Craft", selection: $selectedCraft) {
                            Text("All crafts").tag("All crafts")
                            ForEach(crafts, id: \.self) { craft in
                                Text(craft).tag(craft)
                            }
                        }
                    } label: {
                        Label("Filter craft", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddEntry = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddEntryView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .alert("Could not delete entry", isPresented: Binding(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )) {
                Button("OK", role: .cancel) { deleteError = nil }
            } message: {
                Text(deleteError ?? "Please try again.")
            }
        }
    }

    private func deleteEntries(offsets: IndexSet) {
        offsets.map { filteredEntries[$0] }.forEach(viewContext.delete)
        do {
            try viewContext.save()
        } catch {
            viewContext.rollback()
            deleteError = error.localizedDescription
        }
    }
}

struct EntryRow: View {
    @ObservedObject var entry: CraftEntry

    var body: some View {
        HStack {
            if let data = entry.photo, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "photo")
                    .frame(width: 60, height: 60)
                    .foregroundStyle(.secondary)
            }
            VStack(alignment: .leading) {
                Text(entry.title ?? "Untitled")
                    .font(.headline)
                Text(entry.craftType ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let artisanName = entry.artisanName, !artisanName.isEmpty {
                    Text("Artisan: \(artisanName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
