//
//  MemoryMapApp.swift
//  MemoryMap
//
//  Created by Dagosh on 08.09.2025.
//

import SwiftUI

@main
struct MemoryMapApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
