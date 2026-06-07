import SwiftUI
import CoreLocation

struct TripView: View {
    @StateObject private var vm = TripViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Full-screen map
            TripMapView(coordinates: vm.locationManager.collectedPoints)
                .ignoresSafeArea()

            // HUD overlay
            VStack {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                Spacer()
                controlBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 44)
            }

            // Summary modal
            if vm.showSummaryModal {
                TripSummaryModal(
                    vm: vm,
                    onSave:    { vm.saveTrip() },
                    onDiscard: { vm.discardTrip() }
                )
                .transition(.opacity.animation(.easeInOut(duration: 0.25)))
                .zIndex(1)
            }

            // Fireworks
            if vm.showFireworks {
                FireworksView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .zIndex(2)
            }

            // Permission denied overlay
            if vm.locationManager.authorizationStatus == .denied ||
               vm.locationManager.authorizationStatus == .restricted {
                permissionDeniedOverlay
                    .zIndex(3)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            switch vm.locationManager.authorizationStatus {
            case .notDetermined:
                vm.locationManager.requestPermission()
            case .authorizedAlways, .authorizedWhenInUse:
                if vm.state == .idle { vm.startTrip() }
            default:
                break
            }
        }
        .onChange(of: vm.locationManager.authorizationStatus) { _, status in
            if (status == .authorizedAlways || status == .authorizedWhenInUse) && vm.state == .idle {
                vm.startTrip()
            }
        }
        .onChange(of: vm.state) { _, newState in
            if newState == .saved { dismiss() }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 10) {
            // Close / stop
            Button { vm.stopTrip() } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            // Distance chip
            chip(icon: "road.lanes",   text: String(format: "%.2f km", vm.locationManager.currentDistance))
            // Duration chip
            chip(icon: "timer",        text: vm.formattedElapsed)
            // Status chip
            if vm.state == .paused {
                chip(icon: "pause.fill", text: "En pause", tint: .appGreen)
            }
        }
    }

    private func chip(icon: String, text: String, tint: Color = .appPurple) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundColor(tint)
            Text(text)
                .font(.caption.monospacedDigit().bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
    }

    // MARK: - Control bar

    private var controlBar: some View {
        HStack(spacing: 28) {
            Spacer()

            // Pause / Resume
            Button {
                vm.state == .paused ? vm.resumeTrip() : vm.pauseTrip()
            } label: {
                Image(systemName: vm.state == .paused ? "play.fill" : "pause.fill")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
            }
            .buttonStyle(.plain)

            // Stop
            Button { vm.stopTrip() } label: {
                ZStack {
                    Circle()
                        .fill(LinearGradient.appAccent)
                        .frame(width: 80, height: 80)
                        .shadow(color: .appPurple.opacity(0.55), radius: 24)
                    Image(systemName: "stop.fill")
                        .font(.title.bold())
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    // MARK: - Permission denied

    private var permissionDeniedOverlay: some View {
        ZStack {
            Color.appBackground.opacity(0.95).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.appPurple)
                Text("Accès à la localisation refusé")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                Text("Autorise l'accès dans Réglages > OnTheRoad > Localisation.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button("Ouvrir les Réglages") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(LinearGradient.appAccentH)
                .cornerRadius(14)
                .foregroundColor(.white)
                .font(.subheadline.bold())

                Button("Retour") { dismiss() }
                    .foregroundColor(.white.opacity(0.45))
                    .font(.subheadline)
            }
        }
    }

}

