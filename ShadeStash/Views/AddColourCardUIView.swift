//
//  AddColourCardUIView.swift
//  ShadeStash
//
//  Created by pranay vohra on 13/08/25.
//

import SwiftUI
import SwiftData

struct AddColourCardUIView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context
    @State var hexCode:String = "C8A2C8"
    @State var colourName:String = ""
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var viewModel = DataViewModel()
    
    var body: some View {
    
            VStack{
                ColourCasrdUIView(hexCode: $hexCode, colourName: $colourName,ignoreAI: .constant(true))
                
                
                Form {
                    Button("Generate Random Hex Colour") {
                        let randomHex = String(format: "%06X", Int.random(in: 0...0xFFFFFF))
                        hexCode = randomHex
                        if let name = UIColor(hex: randomHex)?.name {
                            colourName = name
                        }
                    }
                    
                    ColorPicker("Select a Color", selection: Binding(
                        get: {
                            Color(hexString: hexCode) ?? .white
                        },
                        set: { newColor in
                            if let hex = newColor.toHex() {
                                hexCode = hex
                            }
                        }
                    ))
                    
                    HStack{
                        Text("Hex Code: ")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("#\(hexCode)")
                    }
                    
                    TextField("Colour Name", text: $colourName)
                }
            }
         
            .toolbar{
                ToolbarItem{
                    Button("Done"){
                        guard let userId = authViewModel.user?.uid else{return}
                        let card = Card(hexCode: hexCode, colourName: colourName)
                        
                        Task{
                            do {
                                // Add to Firestore
                                try await viewModel.addColourCard(userId: userId, card: card)
                                context.insert(card)
                            } catch {
                                print("adding card failed: \(error)")
            
                            }
                        }
                        dismiss()
                    }
                }
            }
        }
        
    
}

extension Color {
    init?(hexString: String) {
        let r, g, b: Double
        var hexColor = hexString
        if hexString.hasPrefix("#") {
            hexColor = String(hexString.dropFirst())
        }
        guard let intCode = Int(hexColor, radix: 16) else { return nil }
        r = Double((intCode >> 16) & 0xFF) / 255
        g = Double((intCode >> 8) & 0xFF) / 255
        b = Double(intCode & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
    
    func toHex() -> String? {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        let rgb = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255)
        return String(format: "%06X", rgb)
    }
}

extension UIColor {
    convenience init?(hex: String) {
        var hexColor = hex
        if hex.hasPrefix("#") {
            hexColor = String(hex.dropFirst())
        }
        guard let intCode = Int(hexColor, radix: 16) else { return nil }
        let r = CGFloat((intCode >> 16) & 0xFF) / 255
        let g = CGFloat((intCode >> 8) & 0xFF) / 255
        let b = CGFloat(intCode & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
    
    var name: String {
        // Placeholder for color name detection
        // You might integrate a library or API for real names
        return "Random Colour"
    }
}


#Preview {
    AddColourCardUIView()
}
