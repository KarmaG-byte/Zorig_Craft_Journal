import SwiftUI
import PhotosUI
import UIKit

struct AddEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var craftType = crafts[0]
    @State private var notes = ""
    @State private var image: UIImage?
    @State private var showingCamera = false
    @State private var selectedPhoto: PhotosPickerItem?
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
                Section("Photo") {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 250)
                    }
                    Button("Take Photo") { showingCamera = true }
                        .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                    PhotosPicker("Choose from Library", selection: $selectedPhoto, matching: .images)
                }
            }
            .navigationTitle("New Entry")
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(image: $image)
                    .ignoresSafeArea()
            }
            .onChange(of: selectedPhoto) { newSelection in
                Task {
                    guard let newSelection else { return }
                    do {
                        if let data = try await newSelection.loadTransferable(type: Data.self),
                           let pickedImage = UIImage(data: data) {
                            image = pickedImage
                        } else {
                            saveError = "The selected image could not be opened."
                        }
                    } catch {
                        saveError = error.localizedDescription
                    }
                }
            }
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
        entry.photo = image?.jpegData(compressionQuality: 0.7)
        do {
            try viewContext.save()
            dismiss()
        } catch {
            viewContext.rollback()
            saveError = error.localizedDescription
        }
    }
}
