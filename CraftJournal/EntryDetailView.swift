import SwiftUI
import UIKit

struct EntryDetailView: View {
    @ObservedObject var entry: CraftEntry
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let data = entry.photo, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("Photo of \(entry.title ?? "craft item")")
                }
                Text(entry.title ?? "Untitled")
                    .font(.largeTitle)
                    .bold()
                Text(entry.craftType ?? "")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                if let artisanName = entry.artisanName, !artisanName.isEmpty {
                    Text("Artisan: \(artisanName)")
                }
                if let date = entry.date {
                    Text(date, style: .date)
                }
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") { showingEdit = true }
        }
        .sheet(isPresented: $showingEdit) {
            AddEntryView(entryToEdit: entry)
                .environment(\.managedObjectContext, viewContext)
        }
    }
}
