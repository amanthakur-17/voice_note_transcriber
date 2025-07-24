//
//  ContentView.swift
//  VoiceNoteApp
//
//  Created by Aman on 15/07/25.
//

import SwiftUI
import AVFoundation
import Speech

struct ContentView: View {
    
    @StateObject var recorder = AudioRecorder()
    @State private var transcribedText = ""
    @State private var summary = ""
    @State private var quiz = ""
    @State private var studyGuide = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isTextEditorFocused: Bool
    @State private var selectedTab = 0
    
    let tts = ElevenLabsTTS()
    
    var body: some View {
        NavigationView {
            // Use a VStack to contain all elements, allowing for scrolling
            // on the top part and a fixed TabView at the bottom.
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        TextEditor(text: $transcribedText)
                            .frame(height: 150)
                            .padding(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                            .padding(.horizontal)
                            .focused($isTextEditorFocused)
                        
                        HStack {
                            Button(action: recorder.toggleRecording) {
                                Image(systemName: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                    .resizable()
                                    .frame(width: 64, height: 64)
                                    .foregroundColor(recorder.isRecording ? .red : .blue)
                            }
                            
                            Spacer()
                            
                            Button("Speak Text") {
//                                guard !transcribedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
//                                    print("No text to speak.")
//                                    return
//                                }
//                                
//                                Task {
//                                    try? await tts.speak(text: transcribedText)
//                                }
                                Task {
                                    try? await tts.speak(text: "Labs technology refers to the advanced technology developed by Apple for its iOS operating system. Although the specific details of the lecture aren't provided, it's likely that the discussion was about the various innovations Apple has made in its iOS platform under the umbrella of 11 Labs. These could include enhancements in Augmented Reality (AR), Machine Learning (ML), Artificial Intelligence (AI), and overall system performance and efficiency. iPhone 11 and newer models all feature this advanced technology integrated into their systems.")
                                }
                            }
                            
                            Spacer()
                            
                            Menu("Transcribe") {
                                Button("Apple Speech") {
                                    recorder.transcribeUsingApple { text in
                                        transcribedText = text
                                    }
                                }
                                Button("Whisper") {
                                    recorder.transcribeUsingWhisperKit { text in
                                        transcribedText = text
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Divider()
                        
                        Button(action: generateContent) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Generate Summary & Quiz")
                            }
                        }
                        .padding()
                        
                        if let error = errorMessage {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                    .padding(.bottom, 10) // Adjust padding as needed, reduced from 100
                }
                .navigationTitle("Voice Note Transcriber")
                .onTapGesture {
                    isTextEditorFocused = false // dismiss keyboard on tap outside
                    errorMessage = nil
                }
                
                Spacer()
                // --- TabView moved outside the ScrollView ---
                TabView(selection: $selectedTab) {
                    // Each tab's content should be in its own ScrollView if needed
                    ScrollView {
                        Text(summary.isEmpty ? "No summary available." : "Summary:\n\n\(summary)")
                            .padding()
                    }
                    .tag(0)
                    .tabItem {
                        Label("Summary", systemImage: "doc.text")
                    }
                    
                    ScrollView {
                        Text(quiz.isEmpty ? "No quiz generated." : "Quiz:\n\n\(quiz)")
                            .padding()
                    }
                    .tag(1)
                    .tabItem {
                        Label("Quiz", systemImage: "questionmark.circle")
                    }
                    
                    ScrollView {
                        Text(studyGuide.isEmpty ? "No guide generated." : "Study Guide:\n\n\(studyGuide)")
                            .padding()
                    }
                    .tag(2)
                    .tabItem {
                        Label("Guide", systemImage: "book")
                    }
                }
                //.frame(height: 250) // Keep your desired height for the TabView
                .onChange(of: selectedTab) { newValue in
                    print("User switched to tab: \(newValue)")
                }
                .padding(.bottom, 0)
            }
        }
    }
    
    private func generateContent() {
        guard !transcribedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please transcribe some audio first."
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            let result = await ChatGPTService.process(text: transcribedText)
            await MainActor.run {
                self.summary = result.summary
                self.quiz = result.quiz
                self.studyGuide = result.studyGuide
                self.isLoading = false
            }
        }
    }
}
