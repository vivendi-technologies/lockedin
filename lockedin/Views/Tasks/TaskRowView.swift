//
//  TaskRowView.swift
//  lockedin
//
//  Created by Kevin Le on 3/17/25.
//

import SwiftUI

struct TaskRowView: View {
    let task: Task
    
    var body: some View {
        HStack {
            Image(systemName: task.status == .pending ? "circle" : "checkmark.circle.fill")
                .foregroundColor(task.status == .pending ? .blue : .green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .fontWeight(.medium)
                
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
