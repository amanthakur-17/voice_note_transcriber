//
//  ElevenLabsTTS.swift
//  VoiceNoteApp
//
//  Created by Aman on 18/07/25.
//


import Foundation
import AVFoundation

class ElevenLabsTTS {
    private let apiKey = ""
    private let voiceId = "Xb7hH8MSUJpSbSDYk0k2" // e.g. Alice, Rachel, Domi, etc.
    private let session = URLSession.shared
    private var player: AVAudioPlayer?

    func speak(text: String) async throws {
        guard let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceId)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")

        let body: [String: Any] = [
            "text": text,
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.5
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                if let errorBody = String(data: data, encoding: .utf8) {
                    print("Error Response: \(errorBody)")
                }
                return
            }
        }

        // Play audio
        player = try AVAudioPlayer(data: data)
        player?.prepareToPlay()
        player?.play()
    }
}
