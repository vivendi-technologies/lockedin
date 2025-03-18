//
//  ContentView.swift
//  lockedin
//
//  Created by Kevin Le on 3/17/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var taskManager = TaskManager()
    
    var body: some View {
        TaskListView(taskManager: taskManager)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
