//
//  ViewCardUI.swift
//  ShadeStash
//
//  Created by pranay vohra on 13/08/25.
//

import SwiftUI


@available(iOS 26.0, *)
struct ViewCardUI: View {
    let hexCode:String
    let colourName:String
    let ignoreAI:Bool
    @ObservedObject var viewModel:GenerateIntel
    var body: some View {
        VStack{
            HStack{
                Text("#\(hexCode)")
                    .font(.headline).bold()
                    .foregroundColor(Color(hex: complementaryColor(hex: hexCode)))
                    .padding()
                
                Spacer()
                
                if #available(iOS 26.0, *), !ignoreAI{
                    Button{
                        //foundational model
                        viewModel.genResponse(hexCode: hexCode)
                        
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


