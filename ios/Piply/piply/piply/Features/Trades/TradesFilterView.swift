import SwiftUI

struct TradesFilterView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var from: Date?
    @Binding var to: Date?
    @Binding var symbol: String
    @Binding var outcome: TradeOutcomeFilter?
    @Binding var limit: Int

    @State private var fromEnabled = false
    @State private var toEnabled = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Date range") {
                    Toggle("From", isOn: $fromEnabled)
                    if fromEnabled {
                        DatePicker("From", selection: Binding(
                            get: { from ?? Date() },
                            set: { from = $0 }
                        ), displayedComponents: [.date])
                    }

                    Toggle("To", isOn: $toEnabled)
                    if toEnabled {
                        DatePicker("To", selection: Binding(
                            get: { to ?? Date() },
                            set: { to = $0 }
                        ), displayedComponents: [.date])
                    }
                }

                Section("Symbol") {
                    TextField("e.g. XAUUSD", text: $symbol)
                        .textInputAutocapitalization(.never)
                }

                Section("Outcome") {
                    Picker("Outcome", selection: Binding(
                        get: { outcome },
                        set: { outcome = $0 }
                    )) {
                        Text("Any").tag(Optional<TradeOutcomeFilter>.none)
                        ForEach(TradeOutcomeFilter.allCases, id: \.self) { o in
                            Text(o.rawValue.capitalized).tag(Optional(o))
                        }
                    }
                }

                Section("Limit") {
                    Stepper(value: $limit, in: 10...500, step: 10) {
                        Text("Limit: \(limit)")
                    }
                }

                Section {
                    Button("Clear filters") {
                        from = nil
                        to = nil
                        symbol = ""
                        outcome = nil
                        limit = 100
                        fromEnabled = false
                        toEnabled = false
                    }
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                fromEnabled = from != nil
                toEnabled = to != nil
            }
            .onChange(of: fromEnabled) { _, enabled in
                if !enabled { from = nil }
                else if from == nil { from = Date() }
            }
            .onChange(of: toEnabled) { _, enabled in
                if !enabled { to = nil }
                else if to == nil { to = Date() }
            }
        }
    }
}


