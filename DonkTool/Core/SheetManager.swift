//
//  SheetManager.swift
//  DonkTool
//
//  Centralized sheet management to fix blank popup issues
//

import SwiftUI
import Foundation

@Observable
class SheetManager {
    static let shared = SheetManager()
    
    // Sheet presentation state
    var isAttackExecutionSheetPresented = false
    var currentAttackVector: AttackVector?
    var currentTarget: String = ""
    var currentPort: Int = 0
    
    // Sheet content identifier for forcing refresh
    var sheetContentId: UUID = UUID()
    
    private init() {}
    
    func presentAttackExecution(attackVector: AttackVector, target: String, port: Int = 0) {
        print("🎯 SheetManager: Presenting attack execution for \(attackVector.name) on \(target)")
        
        // Reset everything first
        resetSheet()
        
        // Small delay to ensure clean state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            print("🎯 SheetManager: Setting attack vector and showing sheet")
            self.currentAttackVector = attackVector
            self.currentTarget = target
            self.currentPort = port
            self.sheetContentId = UUID() // Force new content
            self.isAttackExecutionSheetPresented = true
        }
    }
    
    func dismissAttackExecution() {
        isAttackExecutionSheetPresented = false
        
        // Reset state after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.resetSheet()
        }
    }
    
    private func resetSheet() {
        currentAttackVector = nil
        currentTarget = ""
        currentPort = 0
        sheetContentId = UUID()
    }
}

// SwiftUI extension for easier use
extension View {
    func attackExecutionSheet() -> some View {
        let sheetManager = SheetManager.shared
        
        return self.sheet(isPresented: Binding(
            get: { 
                let presented = sheetManager.isAttackExecutionSheetPresented
                if presented {
                    print("🎯 Sheet binding: Sheet is presented = \(presented)")
                }
                return presented
            },
            set: { newValue in
                print("🎯 Sheet binding: Setting sheet presented to \(newValue)")
                if !newValue {
                    sheetManager.dismissAttackExecution()
                }
            }
        )) {
            if let attackVector = sheetManager.currentAttackVector {
                AttackExecutionView(
                    attackVector: attackVector,
                    target: sheetManager.currentTarget,
                    port: sheetManager.currentPort
                )
                .id(sheetManager.sheetContentId)
                .environment(SheetManager.shared)
                .onAppear {
                    print("🎯 AttackExecutionView appeared successfully for \(attackVector.name)")
                }
            } else {
                // Fallback content if something goes wrong
                VStack {
                    ProgressView("Loading...")
                    Text("Preparing attack execution...")
                        .foregroundColor(.secondary)
                }
                .frame(minWidth: 400, minHeight: 300)
                .onAppear {
                    print("🎯 Fallback content appeared - no attack vector available")
                }
            }
        }
    }
}