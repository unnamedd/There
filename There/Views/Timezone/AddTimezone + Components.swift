import SwiftUI

// MARK: - IconView

struct IconView: View {
    @Binding var image: NSImage?
    @Binding var countryEmoji: String

    @State private var showPopover = false
    @State private var isDropTargeted = false
    @State private var showingXAccountInput = false
    @State private var showingTGAccountInput = false
    @State private var username = ""
    @State private var debounceTask: Task<Void, Never>?

    var body: some View {
        iconContent
            .frame(width: 70, height: 70)
            .onTapGesture { showPopover = true }
            .popover(isPresented: $showPopover) { popoverContent }
    }

    private var iconContent: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else if !countryEmoji.isEmpty {
                flagView
            } else {
                placeholderView
            }
        }
    }

    private var flagView: some View {
        Circle()
            .fill(.white)
            .overlay(Text(countryEmoji).font(.largeTitle))
    }

    private var placeholderView: some View {
        Circle()
            .fill(.gray.opacity(0.1))
            .overlay(
                Image(systemName: "photo.badge.plus")
                    .font(.title)
                    .foregroundColor(.gray.opacity(0.8))
            )
    }

    private var popoverContent: some View {
        VStack {
            importButtons

            if showingXAccountInput {
                SocialMediaInput(platform: "X", username: $username, image: $image, debounceTask: $debounceTask)
                    .onSubmit {
                        showPopover = false
                    }
            } else if showingTGAccountInput {
                SocialMediaInput(platform: "Telegram", username: $username, image: $image, debounceTask: $debounceTask)
                    .onSubmit {
                        showPopover = false
                    }
            }
        }
        .padding()
    }

    private var importButtons: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("Set from").foregroundColor(.secondary)
            Button("Telegram") {
                showingXAccountInput = false
                showingTGAccountInput = true
            }
            .buttonStyle(.link)
            .padding(.horizontal, 2)
            Text("/").foregroundColor(.secondary).padding(.horizontal, 2)
            Button("X") {
                showingTGAccountInput = false
                showingXAccountInput = true
            }
            .buttonStyle(.link)
            .padding(.horizontal, 2)
            Text("/").foregroundColor(.secondary).padding(.horizontal, 2)
            Button("Finder") {
                let selectedImage = Utils.shared.selectPhoto()
                DispatchQueue.main.async {
                    self.image = selectedImage
                }
                }
            }
        }
    }


            Spacer()

                    }
                }
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else {
            return false
        }

        provider.loadObject(ofClass: NSImage.self) { object, _ in
            if let image = object as? NSImage {
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }
    }
}

}
