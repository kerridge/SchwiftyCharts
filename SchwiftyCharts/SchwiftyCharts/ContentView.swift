import Charts
import SwiftUI

enum CashFlowType: String {
    case moneyIn = "Money In"
    case moneyOut = "Money Out"
}

enum Days: String, CaseIterable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
}

struct CashFlowSeries {
    var weekToDate: [CashFlowDay]
    var monthToDate: [CashFlowDay]
    
    static let placeholders: CashFlowSeries = .init(
        weekToDate: CashFlowDay.getPlaceholders(),
        monthToDate: CashFlowDay.getPlaceholders()
    )
}

struct CashFlowDay: Identifiable, Equatable {
    var label: String
    var id: String
    var cashIn: Double
    var cashOut: Double
    
    init(
        label: String,
        cashIn: Double,
        cashOut: Double
    ) {
        self.label = label
        self.id = label
        self.cashIn = cashIn
        self.cashOut = cashOut
    }
    
    static func getPlaceholders() -> [CashFlowDay] {
        Days.allCases.map { day in
            CashFlowDay(
                label: day.rawValue,
                cashIn: Double.random(in: 0...150),
                cashOut: Double.random(in: 0...150)
            )
        }
    }
}

enum LoadingState<T> {
    case idle
    case loading(placeholder: T)
    case loaded(content: T)
    
    func isLoading() -> Bool {
        if case .loading(placeholder: _) = self {
            return true
        }
        return false
    }
}

@MainActor
final class CashFlowGraphViewModel: ObservableObject {
    @Published var cashFlowGraphData: CashFlowSeries = .placeholders
    @Published var state: LoadingState<CashFlowSeries> = .idle
    
    func buildCashFlowGraphData() async {
        state = .loading(placeholder: CashFlowSeries.placeholders)
        
        if state.isLoading() {
            print("Holup")
        }
        
        //        self.cashFlowGraphData = CashFlowDay.placeholderData
        
        try! await Task.sleep(nanoseconds: 2_000_000_000)
        
        let weekToDate =  CashFlowDay.getPlaceholders()
        let monthToDate = CashFlowDay.getPlaceholders()
        
        self.cashFlowGraphData = .init(weekToDate: weekToDate, monthToDate: monthToDate)
        
        withAnimation(.easeIn) {
            state = .loaded(content: self.cashFlowGraphData)
        }
    }
}

enum ReportPeriod: String {
    case week
    case month
}

struct ContentView: View {
    @State var selectedReportPeriod: ReportPeriod = .week
    
    @ObservedObject var viewModel = CashFlowGraphViewModel()
    
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 100)
            
            Text("Cash In & Out")
                .font(.largeTitle)
            
            Spacer()
                .frame(height: 40)
            
            switch viewModel.state {
            case .idle:
                EmptyView()
                
            case let .loading(placeholder):
                CashFlowGraph(cashFlowGraphData: placeholder.weekToDate)
                    .redacted(reason: .placeholder)
                    .chartForegroundStyleScale([
                        CashFlowType.moneyIn.rawValue: .black,
                        CashFlowType.moneyOut.rawValue: .gray,
                    ])
                //                    .matchedGeometryEffect(id: "Graph", in: animation)
                
            case let .loaded(content):
                
                CashFlowGraph(cashFlowGraphData: selectedReportPeriod == .week
                              ? content.weekToDate
                              : content.monthToDate
                )
                .chartForegroundStyleScale([
                    CashFlowType.moneyIn.rawValue: .purple,
                    CashFlowType.moneyOut.rawValue: .orange,
                ])
                //                    .matchedGeometryEffect(id: "Graph", in: animation)
            }
            
            Picker("Date Range", selection: $selectedReportPeriod.animation(.easeInOut)) {
                Text("Week to Date").tag(ReportPeriod.week)
                Text("Month to Date").tag(ReportPeriod.month)
            }
            .pickerStyle(.segmented)
        }
        .task {
            await viewModel.buildCashFlowGraphData()
        }
        .padding()
    }
}

struct CashFlowGraph: View {
    var cashFlowGraphData: [CashFlowDay]
    @State var isPresented: Bool = false
    
    @State var tapCoords: CGPoint = CGPoint()
    
    @State var selectedElement: CashFlowDay = .init(label: "Dafault", cashIn: 0, cashOut: 0)
    
    var body: some View {
        Chart(cashFlowGraphData) { entry in
            BarMark(
                x: .value("Day", entry.label),
                y: .value("Cash Flow", entry.cashOut)
            )
            .foregroundStyle(by: .value("Cash Flow Type", CashFlowType.moneyOut.rawValue))
            
            BarMark(
                x: .value("Day", entry.label),
                y: .value("Cash Flow", entry.cashIn)
            )
            .foregroundStyle(by: .value("Cash Flow Type", CashFlowType.moneyIn.rawValue))
        }
        .chartBackground { chart in
            GeometryReader { geo in
                let lineHeight = geo[chart.plotAreaFrame].maxY
                
                // get x value for selected element
                let barMarkCenter = chart.position(forX: selectedElement.label) ?? 0
                
                // offset by chart frame
                let startPositionX = barMarkCenter + geo[chart.plotAreaFrame].origin.x
                
                let boxWidth: CGFloat = 200
                
                let popoverPosition = max(0, min(geo.size.width - boxWidth, startPositionX - boxWidth / 2))
                
                if isPresented {
                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .fill(.quaternary)
                            .frame(width: 2, height: lineHeight)
                            .position(x: barMarkCenter, y: lineHeight / 2)
                        
                        VStack(alignment: .leading) {
                            Text("\(selectedElement.label)")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Text("Cash Out: \(selectedElement.cashOut, format: .currency(code: "NZD"))")
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            Text("Cash In: \(selectedElement.cashIn, format: .currency(code: "NZD"))")
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                        }
                        .padding(10)
                        .frame(width: boxWidth)
                        .background { // some styling
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.background)
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.quaternary.opacity(0.7))
                            }
                            .padding([.leading, .trailing], 5)
                        }
                        .offset(x: popoverPosition)
                    }
                }
            }
        }
        .chartOverlay{ proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { tapLocation in
                        
                        // maybe View with generic closure returning element?
                        
                        if let element = findElement(
                            geometry: geo,
                            chart: proxy,
                            location: tapLocation
                        ) {
                            // if clicked the same element
                            if element == selectedElement {
                                // hide element
                                withAnimation(.easeInOut) {
                                    self.isPresented.toggle()
                                }
                            } else {
                                // always display popover if tapping between elements
                                withAnimation(.easeInOut) {
                                    self.isPresented = true
                                    self.selectedElement = element
                                }
                            }
                        }
                    }
            }
        }
    }
    
    func findElement(
        geometry: GeometryProxy,
        chart: ChartProxy,
        location: CGPoint
    ) -> CashFlowDay? {
        let relativeXPosition = location.x - geometry[chart.plotAreaFrame].origin.x
        
        if let xValue: String = chart.value(atX: relativeXPosition) {
            return cashFlowGraphData.first(where: { $0.label == xValue })
        } else {
            return nil
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
