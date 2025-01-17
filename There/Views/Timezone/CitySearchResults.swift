import SwiftUI
import MapKit

enum KeyboardNavigationDirection {
    case up
    case down
    case enter
}

struct CitySearchResults: View {
    @ObservedObject var searchCompleter: SearchCompleter
    @Binding var isShowingPopover: Bool
    @Binding var selectedCity: String
    @Binding var selectedTimezone: TimeZone?
    @Binding var countryEmoji: String
    @FocusState private var isFocused: Bool
    @State private var selectedIndex: Int = -1
    
    var body: some View {
        VStack(spacing: 0) {
            CustomTextField(
                text: $searchCompleter.queryFragment,
                placeholder: "Search for a city or timezone",
                onKeyDown: handleKeyEvent
            )
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal, 6)
            .frame(width: 280, height: 32)
            .background(AdaptiveColors.textFieldBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? .blue : AdaptiveColors.textFieldBorder.opacity(0.5), lineWidth: 1)
            )
            .focused($isFocused)
            .foregroundColor(AdaptiveColors.textColor)
            .padding(.vertical)
            
            ScrollViewReader { proxy in
                List(searchCompleter.results.indices, id: \.self) { index in
                    let result = searchCompleter.results[index]
                    
                    Button(action: {
                        self.selectCity(result)
                    }) {
                        CitySearchResultRow(result: result)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(selectedIndex == index ? Color.accentColor.opacity(0.1) : Color.clear)
                    .id(index)
                }
                .listStyle(PlainListStyle())
                .onChange(of: selectedIndex) { newValue in
                    if newValue >= 0 {
                        // This handles all scrolling scenarios, including scrolling to the bottom
                        // when the last item is selected:
                        // 1. It triggers whenever selectedIndex changes.
                        // 2. It scrolls to the newly selected item if it's in the list (index >= 0).
                        // 3. The .center anchor attempts to center the item in the visible area.
                        // 4. For the last item, this effectively scrolls to the bottom of the list.
                        // 5. It also ensures that the selected item is always visible, even if it's
                        //    not the last item.
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
        .frame(width: 300, height: 400)
    }
}

// MARK: - Private Methods

private extension CitySearchResults {
    
    func handleKeyEvent(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 126: // Up arrow
            moveSelection(direction: .up)
            return true
            
        case 125: // Down arrow
            moveSelection(direction: .down)
            return true
            
        case 36: // Return key
            if selectedIndex >= 0 && selectedIndex < searchCompleter.results.count {
                selectCity(searchCompleter.results[selectedIndex])
            }
            return true
            
        default:
            return false
        }
    }
    
    func moveSelection(direction: KeyboardNavigationDirection) {
        let itemCount = searchCompleter.results.count
        switch direction {
        case .up:
            if selectedIndex > 0 {
                // If not at the top of the list, move up one item
                selectedIndex -= 1
            }
            else if selectedIndex == 0 {
                // If at the top of the list, move focus to the search field
                selectedIndex = -1
            }
            else if selectedIndex == -1 {
                // If focus is on the search field, move to the bottom of the list
                selectedIndex = itemCount - 1
            }
            
        case .down:
            if selectedIndex == -1 {
                // If focus is on the search field and there are items, select the first item
                if itemCount > 0 {
                    selectedIndex = 0
                }
            }
            else if selectedIndex < itemCount - 1 {
                // If not at the bottom of the list, move down one item
                selectedIndex += 1
            }
            else if selectedIndex == itemCount - 1 {
                // If at the bottom of the list, move focus back to the search field
                selectedIndex = -1
            }
            
        case .enter:
            // Enter key handling is done elsewhere
            break
        }
    }
    
    func selectCity(_ result: TimeZoneSearchResult) {
        switch result.type {
        case .city:
            selectedCity = "\(result.title), \(result.subtitle)"
            
            Task {
                if let timezone = await result.getTimeZone() {
                    await MainActor.run {
                        selectedTimezone = timezone
                        let geocoder = CLGeocoder()
                        geocoder.geocodeAddressString(result.title) { [self] placemarks, _ in
                            if let placemark = placemarks?.first, let timezone = selectedTimezone {
                                countryEmoji = Utils.shared.getCountryEmoji(for: placemark.isoCountryCode ?? "")
                            }
                        }
                    }
                }
                else {
                    await MainActor.run {
                        fallbackToGeocoding(for: selectedCity)
                    }
                }
            }
            
        case .abbreviation:
            selectedCity = result.title
            selectedTimezone = result.identifier.flatMap { TimeZone(identifier: $0) }
            countryEmoji = ""
            
        case .utcOffset:
            selectedCity = result.title
            selectedTimezone = result.identifier.flatMap { TimeZone(identifier: $0) }
            countryEmoji = ""
        }
        
        isShowingPopover = false
    }
    
    func fallbackToGeocoding(for address: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { [self] placemarks, _ in
            if let placemark = placemarks?.first, let timezone = placemark.timeZone {
                selectedTimezone = timezone
                countryEmoji = Utils.shared.getCountryEmoji(for: placemark.isoCountryCode ?? "")
            }
        }
    }
}
