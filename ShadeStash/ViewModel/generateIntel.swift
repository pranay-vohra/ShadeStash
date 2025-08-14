//
//  generateIntel.swift
//  ShadeStash
//
//  Created by pranay vohra on 14/08/25.
//

import Foundation
import FoundationModels

@available(iOS 26.0, *)
class GenerateIntel:  ObservableObject {
    @Published var model = SystemLanguageModel.default
    @Published var responseContent:String = ""
    @Published var generatedText: String = ""
    static let instructions = """
    You are a creative colour expert. I will give you a colour in hexadecimal format. Your job is to:
    
    1. Give me one interesting or unusual fun fact about that colour (it can be historical, cultural, scientific, or artistic).
    2. Suggest 2–3 other colours that pair well with it for design purposes. For each suggested colour, give:
       - The colour’s common name.
       - Its hex code.
       - A short reason why it pairs well with the given colour.
    
    Respond in this format:
    Fun Fact: [Your fact]
    Best Combinations:
    - [Name] (#HEX) – [Reason]
    - [Name] (#HEX) – [Reason]
    - [Name] (#HEX) – [Reason]
    """
    
    private var session: LanguageModelSession
    
    init() {
        self.session = LanguageModelSession(instructions: GenerateIntel.instructions)
    }
    
    func genResponse(hexCode:String){
        let prompt = "Here is the colour: #\(hexCode)"
        Task.detached { [weak self] in
            guard let self = self else { return }
            do {
                let response = try await self.session.respond(to: prompt)
                await MainActor.run {
                    self.responseContent = response.content
                    self.generatedText = response.content
                    print(self.responseContent)
                }
            } catch {
                await MainActor.run {
                    self.responseContent = "Failed to generate response."
                    self.generatedText = self.responseContent
                }
                print("GenerateIntel error: \(error)")
            }    }
    }
}
