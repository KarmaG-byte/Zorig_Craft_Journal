import SwiftUI

struct EntryDetailView: View {
    @ObservedObject var entry: CraftEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(entry.title ?? "Untitled")
                    .font(.largeTitle)
                    .bold()
                Text(entry.craftType ?? "")
                    .font(.title3)
                    .foregroundStyle(.secondary)
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
    }
}
