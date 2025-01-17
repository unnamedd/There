import SwiftUI

struct SocialMediaInput: View {
    let source: PhotoSource
    @Binding var username: String
    @Binding var image: NSImage?
    @Binding var debounceTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading) {
            StyledLabel(title: "Enter an \(source.description) username")
                .padding(.top, 8)

            Input(text: $username, placeholder: "eg. dena_sohrabi")
                .onChange(of: username) { value in
                    debounceTask?.cancel()

                    if !value.isEmpty {
                        debounceTask = Task {
                            try? await Task.sleep(for: .milliseconds(800))

                            if !Task.isCancelled {
                                do {
                                    let username = value.lowercased()

                                    // FIXME: While Unavatar does not support Bluesky, we've decided
                                    // to extract the user profile picture directly from the Bluesky API.
                                    // However current implementation should be rolled back after Unavatar
                                    // receives proper support for it.
                                    let imageURL = switch source {
                                    case .bluesky:
                                        try await fetchBlueskyProfileImageURL(for: username)
                                        
                                    default:
                                        "https://unavatar.io/\(source.id)/\(username)"
                                    }

                                    let fetchedImage = try await simpleImageFetch(from: imageURL)

                                    await MainActor.run {
                                        self.image = NSImage(data: fetchedImage)
                                    }
                                } catch {
                                    print("Got error \(error)")
                                }
                            }
                        }
                    } else {
                        image = nil
                    }
                }
        }
    }

    func simpleImageFetch(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let _ = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        image = NSImage(data: data)
        return data
    }

    // This method should not be exposed to callers outside of this file
    private func fetchBlueskyProfileImageURL(for username: String) async throws -> String {
        let urlString = "https://public.api.bsky.app/xrpc/app.bsky.actor.getProfile?actor=\(username)"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let _ = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        let bluesky = try decoder.decode(Bluesky.self, from: data)

        return bluesky.avatar
    }
}

private struct Bluesky: Decodable {
    let avatar: String
}
