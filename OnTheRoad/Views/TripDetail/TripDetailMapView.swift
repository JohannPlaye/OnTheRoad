import SwiftUI
import MapKit

struct TripDetailMapView: UIViewRepresentable {
    let coordinates: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.overrideUserInterfaceStyle = .dark
        map.isScrollEnabled  = true
        map.isZoomEnabled    = true
        map.showsCompass     = false
        map.showsUserLocation = false
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        map.removeOverlays(map.overlays)
        map.removeAnnotations(map.annotations)
        guard !coordinates.isEmpty else { return }

        // Polyline
        if coordinates.count > 1 {
            map.addOverlay(MKPolyline(coordinates: coordinates, count: coordinates.count),
                           level: .aboveRoads)
        }

        // Start annotation
        let startPin = TripPin(coordinate: coordinates[0], kind: .start)
        map.addAnnotation(startPin)

        // End annotation (only if different from start)
        if coordinates.count > 1 {
            let endPin = TripPin(coordinate: coordinates[coordinates.count - 1], kind: .end)
            map.addAnnotation(endPin)
        }

        // Fit region
        let region: MKCoordinateRegion
        if coordinates.count > 1 {
            region = MKCoordinateRegion(fitting: coordinates)
        } else {
            region = MKCoordinateRegion(center: coordinates[0],
                                        latitudinalMeters: 500,
                                        longitudinalMeters: 500)
        }
        map.setRegion(region, animated: false)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let r = MKPolylineRenderer(polyline: polyline)
            r.strokeColor = UIColor(red: 240/255, green: 16/255, blue: 94/255, alpha: 1)
            r.lineWidth = 4
            r.lineCap   = .round
            r.lineJoin  = .round
            return r
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let pin = annotation as? TripPin else { return nil }
            let id = pin.kind == .start ? "start" : "end"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: id)
                ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.annotation = annotation
            view.image = pin.kind == .start
                ? UIImage(systemName: "flag.fill")?
                    .withTintColor(UIColor(red: 74/255, green: 222/255, blue: 128/255, alpha: 1),
                                   renderingMode: .alwaysOriginal)
                : UIImage(systemName: "flag.checkered")?
                    .withTintColor(UIColor(red: 240/255, green: 162/255, blue: 16/255, alpha: 1),
                                   renderingMode: .alwaysOriginal)
            view.frame.size = CGSize(width: 28, height: 28)
            return view
        }
    }
}

// MARK: - Helpers

final class TripPin: NSObject, MKAnnotation {
    enum Kind { case start, end }
    let coordinate: CLLocationCoordinate2D
    let kind: Kind
    init(coordinate: CLLocationCoordinate2D, kind: Kind) {
        self.coordinate = coordinate
        self.kind = kind
    }
}

extension MKCoordinateRegion {
    init(fitting coords: [CLLocationCoordinate2D]) {
        var minLat = coords[0].latitude,  maxLat = coords[0].latitude
        var minLon = coords[0].longitude, maxLon = coords[0].longitude
        for c in coords {
            minLat = min(minLat, c.latitude);  maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                             longitude: (minLon + maxLon) / 2)
        let span   = MKCoordinateSpan(latitudeDelta:  (maxLat - minLat) * 1.4,
                                       longitudeDelta: (maxLon - minLon) * 1.4)
        self.init(center: center, span: span)
    }
}
