//
//  OpenAIService.swift
//  VoiceNoteApp
//
//  Created by Aman on 17/07/25.
//


// OpenAIService.swift

import Foundation

class OpenAIService {
    func generateQuizQuestions(from text: String) async throws -> [String] {
        // 🧠 Simulated logic based on input text
        // Replace with real API call if using a paid key
        return [
            "What is the main topic discussed in the text?",
            "Can you summarize the key point in one sentence?",
            "What supporting evidence is mentioned?"
        ]
    }

    func generateStudyGuide(from text: String) async throws -> String {
        return """
        Study Guide:
        1. Main Theme: \(text.prefix(80))...
        2. Key Points:
        - Introduction and background
        - Important concepts explained
        - Summary at the end
        """
    }
}
