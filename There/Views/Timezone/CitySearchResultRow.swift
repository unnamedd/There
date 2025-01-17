import SwiftUI

struct CitySearchResultRow: View, Equatable {
    let result: TimeZoneSearchResult

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(result.title)

                Text(result.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    static func == (lhs: CitySearchResultRow, rhs: CitySearchResultRow) -> Bool {
        lhs.result == rhs.result
    }
}
