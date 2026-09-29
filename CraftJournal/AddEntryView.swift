import SwiftUI
import PhotosUI
import UIKit

struct AddEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let entryToEdit: CraftEntry?
    @State private var title = ""
    @State private var craftType = crafts[0]
    @State private var artisanName = ""
    @State private var notes = ""
    @State private var image: UIImage?
    @State private var showingCamera = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var saveError: String?

    init(entryToEdit: CraftEntry? = nil) {
        self.entryToEdit = entryToEdit
        _title = State(initialValue: entryToEdit?.title ?? "")
        _craftType = State(initialValue: entryToEdit?.craftType ?? crafts[0])
        _artisanName = State(initialValue: entryToEdit?.artisanName ?? "")
        _notes = State(initialValue: entryToEdit?.notes ?? "")
        _image = State(initialValue: entryToEdit?.photo.flatMap(UIImage.init(data:)))
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                Picker("Craft", selection: $craftType) {
                    ForEach(crafts, id: \.self) { craft in
                        Text(craft)
                    }
                }
                TextField("Artisan name", text: $artisanName)
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
            .navigationTitle(entryToEdit == nil ? "New Entry" : "Edit Entry")
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
        let entry = entryToEdit ?? CraftEntry(context: viewContext)
        if entryToEdit == nil {
            entry.id = UUID()
            entry.date = Date()
        }
        entry.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.craftType = craftType
        entry.artisanName = artisanName.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.notes = notes
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
