//
//  LockScreenMediaPanelView.swift
//  Droppy
//
//  Created by Droppy on 26/01/2026.
//  SwiftUI view for the lock screen media widget
//  Displays album art, track info, progress bar, visualizer and playback controls
//

import SwiftUI

/// Lock screen media panel - iPhone-inspired design
/// Displays on the macOS lock screen via SkyLight.framework
struct LockScreenMediaPanelView: View {
    @EnvironmentObject var musicManager: MusicManager
    @ObservedObject var animator: LockScreenMediaPanelAnimator
    
    // MARK: - Layout Constants
    private let albumArtSize: CGFloat = 60
    private let albumArtCornerRadius: CGFloat = 12
    private let controlButtonSize: CGFloat = 28
    private let playPauseButtonSize: CGFloat = 36
    
    // MARK: - Computed Properties
    
    /// Visualizer color extracted from album art
    private var visualizerColor: Color {
        musicManager.visualizerColor
    }
    
    // MARK: - Body
    
    var body: some View {
        // TimelineView for live updates - updates every 0.5s when playing
        TimelineView(.periodic(from: .now, by: musicManager.isPlaying ? 0.5 : 60)) { context in
            let estimatedTime = musicManager.estimatedPlaybackPosition(at: context.date)
            let progress: Double = musicManager.songDuration > 0 
                ? min(1, max(0, estimatedTime / musicManager.songDuration)) 
                : 0
            
            VStack(spacing: 16) {
                // Header: Album art + visualizer + track info
                headerSection
                
                // Progress bar with live updates
                progressBar(progress: progress, estimatedTime: estimatedTime)
                    .padding(.top, 4)
                
                // Playback controls
                playbackControls
                    .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(width: 420, height: 180)
            .background(panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 30, x: 0, y: 15)
            // Entry/exit animations
            .scaleEffect(animator.isPresented ? 1 : 0.85, anchor: .center)
            .opacity(animator.isPresented ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animator.isPresented)
        }
    }
    
    // MARK: - Panel Background
    
    private var panelBackground: some View {
        ZStack {
            // Blur behind
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
            
            // Dark overlay for readability
            Color.black.opacity(0.5)
            
            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    Color.white.opacity(0.08),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            // Album art with visualizer overlay
            ZStack(alignment: .bottomTrailing) {
                albumArtView
                
                // Mini visualizer in corner of album art
                AudioSpectrumView(
                    isPlaying: musicManager.isPlaying,
                    barCount: 3,
                    barWidth: 2,
                    spacing: 1.5,
                    height: 12,
                    color: .white
                )
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.5))
                )
                .offset(x: 2, y: 2)
            }
            
            // Track info
            VStack(alignment: .leading, spacing: 4) {
                // Song title
                Text(musicManager.songTitle.isEmpty ? "Not Playing" : musicManager.songTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Artist name
                Text(musicManager.artistName.isEmpty ? "Unknown Artist" : musicManager.artistName)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                
                // Album name (if available)
                if !musicManager.albumName.isEmpty {
                    Text(musicManager.albumName)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Larger visualizer on right side
            AudioSpectrumView(
                isPlaying: musicManager.isPlaying,
                barCount: 5,
                barWidth: 3,
                spacing: 2,
                height: 24,
                color: visualizerColor
            )
            .padding(.trailing, 8)
            
            // App icon (small, in corner)
            appIconView
        }
    }
    
    // MARK: - Album Art
    
    @ViewBuilder
    private var albumArtView: some View {
        if musicManager.albumArt.size.width > 0 {
            Image(nsImage: musicManager.albumArt)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: albumArtSize, height: albumArtSize)
                .clipShape(RoundedRectangle(cornerRadius: albumArtCornerRadius, style: .continuous))
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        } else {
            // Placeholder
            RoundedRectangle(cornerRadius: albumArtCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.1))
                .frame(width: albumArtSize, height: albumArtSize)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                )
        }
    }
    
    // MARK: - App Icon
    
    @ViewBuilder
    private var appIconView: some View {
        if let bundleId = musicManager.bundleIdentifier,
           let appPath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            let icon = NSWorkspace.shared.icon(forFile: appPath.path)
            Image(nsImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .opacity(0.7)
        }
    }
    
    // MARK: - Progress Bar
    
    private func progressBar(progress: Double, estimatedTime: Double) -> some View {
        VStack(spacing: 4) {
            // Progress track
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 4)
                    
                    // Progress fill
                    Capsule()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: max(0, geo.size.width * progress), height: 4)
                }
            }
            .frame(height: 4)
            
            // Time labels with live elapsed time
            HStack {
                Text(formatTime(estimatedTime))
                    .font(.system(size: 10, weight: .medium).monospacedDigit())
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                Text(formatTime(musicManager.songDuration))
                    .font(.system(size: 10, weight: .medium).monospacedDigit())
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
    
    // MARK: - Playback Controls
    
    private var playbackControls: some View {
        HStack(spacing: 40) {
            // Previous track
            Button {
                musicManager.previousTrack()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: controlButtonSize, height: controlButtonSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Play/Pause
            Button {
                musicManager.togglePlay()
            } label: {
                Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: playPauseButtonSize, height: playPauseButtonSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Next track
            Button {
                musicManager.nextTrack()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: controlButtonSize, height: controlButtonSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Visual Effect View (NSVisualEffectView wrapper)

private struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black
        LockScreenMediaPanelView(animator: LockScreenMediaPanelAnimator())
            .environmentObject(MusicManager.shared)
    }
    .frame(width: 500, height: 300)
}
