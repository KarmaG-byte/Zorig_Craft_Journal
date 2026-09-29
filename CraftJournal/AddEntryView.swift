import SwiftUI

struct AddEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var craftType = crafts[0]
    @State private var notes = ""
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                Picker("Craft", selection: $craftType) {
                    ForEach(crafts, id: \.self) { craft in
                        Text(craft)
                    }
                }
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...8)
            }
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEntry() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Could not save entry", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "Please try again.")
            }
        }
    }

    private func saveEntry() {
        let entry = CraftEntry(context: viewContext)
        entry.id = UUID()
        entry.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.craftType = craftType
        entry.notes = notes
        entry.date = Date()
        do {
            try viewContext.save()
            dismiss()
        } catch {
            viewContext.rollback()
            saveError = error.localizedDescription
        }
    }
}
