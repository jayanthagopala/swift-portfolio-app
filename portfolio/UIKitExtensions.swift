import Foundation
import UIKit
import SwiftUI

extension UIApplication {
    // Helper function to dismiss the keyboard
    static func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// View extension to dismiss keyboard on tap
extension View {
    func dismissKeyboardOnTap() -> some View {
        return self.onTapGesture {
            UIApplication.dismissKeyboard()
        }
    }
}

// Extension to add keyboard dismiss button
struct KeyboardDismissButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.dismissKeyboard()
                    }
                }
            }
    }
}

extension View {
    func addKeyboardDismissButton() -> some View {
        return self.modifier(KeyboardDismissButton())
    }
}
