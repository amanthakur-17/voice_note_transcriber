//
//  AudioRecorder.swift
//  VoiceNoteApp
//
//  Created by Aman on 21/07/25.
//


import SwiftUI
import AVFoundation
import Speech
import WhisperKit

class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    private var audioRecorder: AVAudioRecorder?
    private let audioFilename = FileManager.default.temporaryDirectory.appendingPathComponent("recording.m4a")
    private let speechRecognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func startRecording() {
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
    }
    
    func transcribeUsingApple(completion: @escaping (String) -> Void) {
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: audioFilename)
        request.requiresOnDeviceRecognition = false // avoid forcing local recognition
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                recognizer?.recognitionTask(with: request) { result, error in
                    if let result = result, result.isFinal {
                        DispatchQueue.main.async {
                            completion(result.bestTranscription.formattedString)
                        }
                    } else if let error = error {
                        print("Transcription error: \(error.localizedDescription)")
                    }
                }
            case .denied:
                print("Speech recognition authorization denied")
            case .restricted:
                print("Speech recognition is restricted on this device")
            case .notDetermined:
                print("Speech recognition authorization not determined")
            @unknown default:
                print("Unknown speech recognition authorization status")
            }
        }
    }
    
    
        func transcribeUsingWhisperKit(completion: @escaping (String) -> Void) {
            Task {
                do {
                    let whisperKit = try await WhisperKit(model: "tiny")
                    let results = await whisperKit.transcribe(audioPaths: [audioFilename.path])
                    if let text = results.first??.first?.text {
                        DispatchQueue.main.async {
                            completion(text)
                        }
                    } else {
                        print("WhisperKit returned no transcription result.")
                    }
                } catch {
                    print("WhisperKit transcription failed: \(error.localizedDescription)")
                }
            }
        }
    
//    func transcribeUsingWhisperKit(completion: @escaping (String) -> Void) {
//        Task {
//            do {
//                let whisperKit = try await WhisperKit(
//                    model: "tiny",//"base.en", // use a larger model like "base", "base.en", "small"
//                    prewarm: true,     // prewarm models for faster inference
//                    load: true         // load models on init
//                )
//                let results = await whisperKit.transcribe(audioPaths: [audioFilename.path])
//                if let text = results.first??.first?.text {
//                    DispatchQueue.main.async {
//                        completion(text)
//                    }
//                } else {
//                    print("WhisperKit returned no transcription result.")
//                }
//            } catch {
//                print("WhisperKit transcription failed: \(error.localizedDescription)")
//            }
//            
//        }
//    }

    
}
