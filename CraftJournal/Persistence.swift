import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        for index in 0..<5 {
            let entry = CraftEntry(context: viewContext)
            entry.id = UUID()
            entry.title = "Sample craft \(index + 1)"
            entry.craftType = "Thagzo"
            entry.date = Date().addingTimeInterval(Double(-index) * 86400)
            entry.notes = "A sample journal note."
        }
        do {
            try viewContext.save()
        } catch {
            fatalError("Could not save preview data: \(error)")
        }
        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CraftJournal")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Could not load persistent store: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
