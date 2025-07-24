//
//  ChatGPTService.swift
//  VoiceNoteApp
//
//  Created by Aman on 15/07/25.
//

import Foundation

struct ChatGPTResult {
    var summary: String
    var quiz: String
    var studyGuide: String
}

class ChatGPTService {
    
    static let apiKey = ""
    static func process(text: String) async -> ChatGPTResult {
        let systemPrompt = "You are an educational assistant that helps summarize lecture notes, create quizzes, and generate study guides."
        let prompt = "Transcript: \(text)\n\n1. Give a short summary.\n2. Create 3 quiz questions and answers.\n3. Provide a study guide with bullet points."

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            return ChatGPTResult(summary: "", quiz: "", studyGuide: "")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": "gpt-4",
            //"model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            print(String(data: data, encoding: .utf8) ?? "No response body")
            if let result = try? JSONDecoder().decode(OpenAIResponse.self, from: data) {
                
                let fullResponse = result.choices.first?.message.content ?? ""
                return parseChatOutput(fullResponse)
            }
        } catch {
            print("OpenAI API error: \(error.localizedDescription)")
        }

        return ChatGPTResult(summary: "Error generating response.", quiz: "", studyGuide: "")
    }

//    private static func parseChatOutput(_ text: String) -> ChatGPTResult {
//        let parts = text.components(separatedBy: "\n\n")
//        return ChatGPTResult(
//            summary: parts.first ?? "",
//            quiz: parts.dropFirst().first ?? "",
//            studyGuide: parts.dropFirst(2).joined(separator: "\n")
//        )
//    }
    
    private static func parseChatOutput(_ text: String) -> ChatGPTResult {
        // Any header can have multiple accepted versions
        let summaryMarkers = ["Summary:"]
        let quizMarkers = ["Quiz Questions:","Quiz Questions and Answers:"]
        let studyGuideMarkers = ["Study Guide Bullet Points:", "Study Guide:"]

        func findFirstMarker(_ markers: [String], in fullText: String, after index: String.Index? = nil) -> (String, Range<String.Index>)? {
            for marker in markers {
                if let range = fullText.range(of: marker, options: .caseInsensitive, range: (index ?? fullText.startIndex)..<fullText.endIndex) {
                    return (marker, range)
                }
            }
            return nil
        }

        func extractSection(fullText: String, startMarkers: [String], endMarkers: [String]?) -> String? {
            guard let (startMarker, startRange) = findFirstMarker(startMarkers, in: fullText) else { return nil }
            let contentStart = startRange.upperBound
            let contentEnd: String.Index

            if let endMarkers = endMarkers,
               let end = findFirstMarker(endMarkers, in: fullText, after: contentStart) {
                contentEnd = end.1.lowerBound
            } else {
                contentEnd = fullText.endIndex
            }
            return String(fullText[contentStart..<contentEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let summary = extractSection(fullText: text, startMarkers: summaryMarkers, endMarkers: quizMarkers + studyGuideMarkers) ?? ""
        let quiz = extractSection(fullText: text, startMarkers: quizMarkers, endMarkers: studyGuideMarkers) ?? ""
        let studyGuide = extractSection(fullText: text, startMarkers: studyGuideMarkers, endMarkers: nil) ?? ""

        return ChatGPTResult(summary: summary, quiz: quiz, studyGuide: studyGuide)
    }


    
}

struct OpenAIResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}
