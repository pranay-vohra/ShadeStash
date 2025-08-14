//
//  ColourCasrdUIView.swift
//  ShadeStash
//
//  Created by pranay vohra on 13/08/25.
//

import SwiftUI

struct ColourCasrdUIView: View {
   
    @Binding var hexCode:String
    @Binding var colourName:String
    @Binding var ignoreAI:Bool
    
    var body: some View {
        VStack{
            HStack{
                Text("#\(hexCode)")
                    .font(.headline).bold()
                    .foregroundColor(Color(hex: complementaryColor(hex: hexCode)))
                    .padding()
                
                Spacer()
                
                if(!ignoreAI){
                    Button{
                     
                    } label: {
                        Image(systemName: "apple.intelligence")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color(hex: complementaryColor(hex: hexCode)))
                            .padding()
                    }
                }
            }
            
            Spacer()
            
            Text(colourName)
                .font(.title2).bold()
                .foregroundColor(Color(hex: complementaryColor(hex: hexCode)))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 150)
        .background(Color(hex: hexCode))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 5, y: 5)
        .padding(.horizontal)
    }

    // Function to get complementary hex
    func complementaryColor(hex: String) -> String {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = 255 - Int((rgb & 0xFF0000) >> 16)
        let g = 255 - Int((rgb & 0x00FF00) >> 8)
        let b = 255 - Int(rgb & 0x0000FF)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

