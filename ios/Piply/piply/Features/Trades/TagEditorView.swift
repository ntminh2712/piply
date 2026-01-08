import SwiftUI

struct TagEditorView: View {
    @Binding var tags: [String]
    @State private var newTag: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            FlowLayout(tags: tags) { tag in
                Button {
                    tags.removeAll { $0 == tag }
                } label: {
                    HStack(spacing: 6) {
                        Text(tag)
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                TextField("Add tag…", text: $newTag)
                    .textInputAutocapitalization(.never)
                Button("Add") {
                    let t = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !t.isEmpty else { return }
                    if !tags.contains(t) { tags.append(t) }
                    newTag = ""
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

// Simple flow layout for chips
private struct FlowLayout<TagView: View>: View {
    let tags: [String]
    let content: (String) -> TagView

    init(tags: [String], @ViewBuilder content: @escaping (String) -> TagView) {
        self.tags = tags
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MVP: wrap manually by using LazyVGrid with adaptive columns.
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(tags, id: \.self) { t in
                    content(t)
                }
            }
        }
    }
}


