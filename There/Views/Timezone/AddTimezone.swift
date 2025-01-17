import Foundation

import AppKit
import CoreLocation
import MapKit
import SwiftUI

struct AddTimezone: View {
    @Environment(\.database) var database
    @StateObject private var searchCompleter = SearchCompleter()

    @EnvironmentObject var router: Router

    @State var image: NSImage?
    @State var name = ""
    @State var city = ""
    @State var selectedTimeZone: TimeZone? = nil
    @State var isShowingPopover = false
    @State var countryEmoji = ""

    @State var showingXAccountInput = false
    @State var showingTGAccountInput = false

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            IconSection(
                image: $image,
                countryEmoji: $countryEmoji
            )

            FormSection(
                name: $name,
                city: $city,
                selectedTimeZone: $selectedTimeZone,
                isShowingPopover: $isShowingPopover,
                searchCompleter: searchCompleter,
                countryEmoji: $countryEmoji,
                image: $image,
                saveEntry: saveEntry
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

        .overlay(alignment: .topLeading) {
            Titlebar()
                .padding(6)
        }
    }
}

// MARK: - Private Methods

private extension AddTimezone {
    func searchPlace(_ completion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, _ in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else {
                return
            }

            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
                DispatchQueue.main.async {
                    if let placemark = placemarks?.first {
                        if let timeZone = placemark.timeZone {
                            self.selectedTimeZone = timeZone
                        }
                        self.countryEmoji = Utils.shared.getCountryEmoji(for: placemark.isoCountryCode ?? "")
                    }
                }
            }
        }
    }

    func saveEntry() {
        let fileName = UUID().uuidString + ".png"
        let fileURL = getApplicationSupportDirectory().appendingPathComponent(fileName)

        if let tiffData = image?.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapImage.representation(using: .png, properties: [:]) {
            do {
                try pngData.write(to: fileURL)
            }
            catch {
                print("Failed to save image: \(error)")
            }
        }

        do {
            try database.dbWriter.write { db in
                let entry = Entry(
                    id: Int64.random(in: 1 ... 99999),
                    type: !countryEmoji.isEmpty && image == nil ? .place : .person,
                    name: name,
                    city: city,
                    timezoneIdentifier: selectedTimeZone?.identifier ?? "",
                    flag: image == nil ? countryEmoji : "",
                    photoData: image != nil ? fileURL.absoluteString : nil
                )

                try entry.save(db)
            }
        }
        catch {
            print("Failed to save entry \(error)")
        }

        router.cleanActiveRoute()
        resetForm()
    }

    func resetForm() {
        image = nil
        name = ""
        city = ""
        showingXAccountInput = false
        showingTGAccountInput = false
        selectedTimeZone = TimeZone.current
        isShowingPopover = false
        countryEmoji = ""
        selectedTimeZone = nil
    }

    func getApplicationSupportDirectory() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }
}

#Preview {
    AddTimezone()
        .frame(width: 300, height: 400)
}
