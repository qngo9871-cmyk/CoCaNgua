import SwiftUI

struct RulesView: View {
    @Environment(\.dismiss) private var dismiss

    private let sections: [(String, String)] = [
        ("rules.goal.title", "rules.goal.body"),
        ("rules.leaving.title", "rules.leaving.body"),
        ("rules.moving.title", "rules.moving.body"),
        ("rules.six.title", "rules.six.body"),
        ("rules.capture.title", "rules.capture.body"),
        ("rules.safe.title", "rules.safe.body"),
        ("rules.win.title", "rules.win.body"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(sections, id: \.0) { title, body in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L(title)).font(.headline)
                            Text(L(body)).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(L("rules.title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("rules.done")) { dismiss() }
                }
            }
        }
    }
}

#Preview { RulesView() }
