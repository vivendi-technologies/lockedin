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
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .fontWeight(.medium)
                
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if task.status != .pending {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var statusIcon: String {
        switch task.status {
        case .pending:
            return "circle"
        case .completed:
            return "checkmark.circle"
        case .verified:
            return "checkmark.seal.fill"
        }
    }
    
    private var statusColor: Color {
        switch task.status {
        case .pending:
            return .blue
        case .completed:
            return .orange
        case .verified:
            return .green
        }
    }
}
