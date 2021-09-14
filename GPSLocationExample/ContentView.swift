import BottomSheet
import Combine
import CoreLocation
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

    @Published var recording = false {
        didSet {
            self.currentLocation.isActive = self.recording
            if oldValue != self.recording {
                if self.recording {
                    self.locationMonitoringTask = Task {
                        for await location: CLLocation? in self.currentLocation.$location.values {
                            if let location = location {
                                self.add(location: location)
                            }
                        }
                    }
                } else {
                    self.locationMonitoringTask?.cancel()
                    self.locationMonitoringTask = nil
                }
            }
        }
    }

    private var currentLocation = CurrentLocation()
    private var locationMonitoringTask: Task<Void, Never>?

    private func add(location: CLLocation) {
        self.track.positions.append(GPSPosition(coordinate: location.coordinate))
    }
}

struct ContentView: View {
    @State private var bottomSheetPresented = false
    @StateObject var trackModel = GPSTrackModel()

    var body: some View {
        VStack {
            Button("Show Sheet") {
                bottomSheetPresented = true
            }
        }
        .ignoresSafeArea()
        .bottomSheet(
            isPresented: $bottomSheetPresented,
            prefersGrabberVisible: true,
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
