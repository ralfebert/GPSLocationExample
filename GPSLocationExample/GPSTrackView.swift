import BottomSheet
import Combine
import CoreLocation
import MapKit
import SwiftUI

struct GPSPosition: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct GPSTrack {
    var positions: [GPSPosition] = []
}

@MainActor
class GPSTrackModel: ObservableObject {
    @Published var track = GPSTrack()

    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(),
        latitudinalMeters: 750,
        longitudinalMeters: 750
    )

    @Published var recording = false {
        didSet {
            if oldValue != self.recording {
                if self.recording {
                    self.locationMonitoringTask = Task {
                        for await coordinate in self.$mapRegion.map(\.center).values {
                            self.add(coordinate: coordinate)
                        }
                    }
                } else {
                    self.locationMonitoringTask?.cancel()
                    self.locationMonitoringTask = nil
                }
            }
        }
    }

    private var locationMonitoringTask: Task<Void, Never>?

    private func add(coordinate: CLLocationCoordinate2D) {
        self.track.positions.append(GPSPosition(coordinate: coordinate))
    }
}

struct ContentView: View {
    @State private var bottomSheetPresented = false
    @StateObject var trackModel = GPSTrackModel()

    var body: some View {
        Map(
            coordinateRegion: $trackModel.mapRegion,
            showsUserLocation: true,
            userTrackingMode: .constant(.follow)
        )
        .overlay(
            alignment: .bottomTrailing,
            content: {
                Button(
                    action: {
                        bottomSheetPresented = true
                    },
                    label: {
                        Image(systemName: "recordingtape")
                            .aspectRatio(1, contentMode: .fit)
                            .padding(15)
                            .background {
                                Color.white
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                            }
                    }
                )
                .padding(25)
                .edgesIgnoringSafeArea([])
            }
        )
        .ignoresSafeArea()
        .bottomSheet(
            isPresented: $bottomSheetPresented,
            prefersGrabberVisible: true,
            prefersEdgeAttachedInCompactHeight: true,
            contentView: {
                GPSTrackView(trackModel: trackModel)
            }
        )
    }
}

struct GPSTrackView: View {
    @ObservedObject var trackModel: GPSTrackModel

    var body: some View {
        List {
            Button(trackModel.recording ? "Stop recording" : "Start recording") {
                trackModel.recording.toggle()
            }
            ForEach(trackModel.track.positions) { pos in
                Text("\(pos.coordinate.latitude), \(pos.coordinate.longitude)")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
