import SwiftUI
import MapKit

struct TripMapView: UIViewRepresentable {
    var coordinates: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.showsUserLocation   = true
        map.userTrackingMode    = .followWithHeading   // centré + orientation
        map.delegate            = context.coordinator
        map.overrideUserInterfaceStyle = .dark
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        // Mise à jour du tracé uniquement — ne touche pas au tracking mode
        map.removeOverlays(map.overlays)
        guard coordinates.count > 1 else { return }
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        map.addOverlay(polyline, level: .aboveRoads)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate {

        /// Timer de recentrage automatique après interaction manuelle.
        private var recenterTimer: Timer?
        /// Empêche de détecter notre propre changement de mode comme une interaction utilisateur.
        private var isProgrammaticChange = false

        // MARK: Tracking mode

        /// Appelé par MapKit chaque fois que le mode de suivi change.
        /// Quand l'utilisateur déplace la carte, MapKit passe automatiquement en .none.
        func mapView(_ mapView: MKMapView,
                     didChange mode: MKUserTrackingMode,
                     animated: Bool) {
            guard !isProgrammaticChange else { return }

            if mode == .none {
                // L'utilisateur a bougé la carte manuellement → planifie le recentrage
                scheduleRecenter(for: mapView)
            } else {
                // Le suivi a été rétabli → annule le timer en cours
                recenterTimer?.invalidate()
                recenterTimer = nil
            }
        }

        private func scheduleRecenter(for mapView: MKMapView) {
            recenterTimer?.invalidate()
            recenterTimer = Timer.scheduledTimer(
                withTimeInterval: 10,
                repeats: false
            ) { [weak self, weak mapView] _ in
                guard let self, let mapView else { return }
                self.isProgrammaticChange = true
                mapView.setUserTrackingMode(.followWithHeading, animated: true)
                // Laisse le delegate se déclencher avant de remettre le flag à false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isProgrammaticChange = false
                }
            }
        }

        // MARK: Overlay renderer

        func mapView(_ mapView: MKMapView,
                     rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer        = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor(red: 240/255, green: 16/255, blue: 94/255, alpha: 1) // appPink
            renderer.lineWidth  = 5
            renderer.lineCap    = .round
            renderer.lineJoin   = .round
            return renderer
        }
    }
}
