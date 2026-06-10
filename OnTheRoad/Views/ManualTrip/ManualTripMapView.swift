import SwiftUI
import MapKit

struct ManualTripMapView: UIViewRepresentable {
    let route:     MKRoute?
    let departure: MKMapItem?
    let arrival:   MKMapItem?

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = false
        map.isRotateEnabled   = false
        map.pointOfInterestFilter = .excludingAll
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        map.removeOverlays(map.overlays)
        map.removeAnnotations(map.annotations)

        if let dep = departure {
            let ann = ColoredAnnotation(coordinate: dep.placemark.coordinate,
                                        title: dep.name ?? "Départ",
                                        isStart: true)
            map.addAnnotation(ann)
        }
        if let arr = arrival {
            let ann = ColoredAnnotation(coordinate: arr.placemark.coordinate,
                                        title: arr.name ?? "Arrivée",
                                        isStart: false)
            map.addAnnotation(ann)
        }

        if let route {
            map.addOverlay(route.polyline, level: .aboveRoads)
            let padded = route.polyline.boundingMapRect
                .insetBy(dx: -route.polyline.boundingMapRect.width  * 0.15,
                         dy: -route.polyline.boundingMapRect.height * 0.15)
            map.setVisibleMapRect(padded, animated: true)
        } else {
            // Zoom to show available pins
            var rect = MKMapRect.null
            let size: Double = 3000
            if let dep = departure {
                let pt = MKMapPoint(dep.placemark.coordinate)
                rect = rect.union(MKMapRect(x: pt.x - size/2, y: pt.y - size/2, width: size, height: size))
            }
            if let arr = arrival {
                let pt = MKMapPoint(arr.placemark.coordinate)
                rect = rect.union(MKMapRect(x: pt.x - size/2, y: pt.y - size/2, width: size, height: size))
            }
            if !rect.isNull {
                let padded = rect.insetBy(dx: -rect.width * 0.2, dy: -rect.height * 0.2)
                map.setVisibleMapRect(padded, animated: true)
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: - Coordinator

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ map: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let r = MKPolylineRenderer(polyline: polyline)
            r.strokeColor = UIColor(red: 240/255, green: 16/255, blue: 94/255, alpha: 1) // appPink
            r.lineWidth   = 4
            r.lineCap     = .round
            r.lineJoin    = .round
            return r
        }

        func mapView(_ map: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let colored = annotation as? ColoredAnnotation else { return nil }
            let id   = "manualPin"
            let view = (map.dequeueReusableAnnotationView(withIdentifier: id)
                        ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id))
            view.annotation = annotation
            let color: UIColor = colored.isStart
                ? UIColor(red: 74/255,  green: 222/255, blue: 128/255, alpha: 1) // appGreen
                : UIColor(red: 240/255, green: 16/255,  blue: 94/255,  alpha: 1) // appPink
            let symbolName = colored.isStart ? "flag.fill" : "flag.checkered"
            view.image = UIImage(systemName: symbolName)?
                .withTintColor(color, renderingMode: .alwaysOriginal)
            view.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
            view.centerOffset = CGPoint(x: 0, y: -14)
            return view
        }
    }
}

// MARK: - Custom annotation

final class ColoredAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title:      String?
    let isStart:    Bool

    init(coordinate: CLLocationCoordinate2D, title: String, isStart: Bool) {
        self.coordinate = coordinate
        self.title      = title
        self.isStart    = isStart
    }
}
