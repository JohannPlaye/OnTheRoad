//
//  OnTheRoadApp.swift
//  OnTheRoad
//
//  Created by Johann on 06/06/2026.
//

import SwiftUI
import CoreData

@main
struct OnTheRoadApp: App {
    let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .preferredColorScheme(.dark)
        }
    }
}
