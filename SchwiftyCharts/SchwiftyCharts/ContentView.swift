import Charts
import SwiftUI

enum CashFlowType: String {
    case moneyIn = "Money In"
    case moneyOut = "Money Out"
}

struct CashFlowSeries {
    var weekToDate: [CashFlowDay]
    var monthToDate: [CashFlowDay]
    
    static let placeholders: CashFlowSeries = .init(
        weekToDate: CashFlowDay.placeholderData,
        monthToDate: CashFlowDay.placeholderData
    )
}

struct CashFlowDay: Identifiable, Equatable {
    var type: CashFlowType
    var label: String
    var value: Double
    var id: String
    var cashIn: Double = 0.0
    var cashOut: Double = 0.0
    
    
    init(
        type: CashFlowType,
        label: String,
        value: Double,
        cashIn: Double = 45,
        cashOut: Double = 2
    ) {
        self.type = type
        self.label = label
        self.value = value
        self.id = label + type.rawValue
        self.cashIn = cashIn
        self.cashOut = cashOut
    }
    
    static let placeholderData: [CashFlowDay] = [
        .init(type: .moneyOut, label: "Monday", value: 2),
        .init(type: .moneyOut, label: "Tuesday", value: 4),
        .init(type: .moneyOut, label: "Wednesday", value: 1),
        .init(type: .moneyOut, label: "Thursday", value: 0.5),
        .init(type: .moneyOut, label: "Friday", value: 1.9),
        .init(type: .moneyIn, label: "Monday", value: 5),
        .init(type: .moneyIn, label: "Tuesday", value: 7),
        .init(type: .moneyIn, label: "Wednesday", value: 2),
        .init(type: .moneyIn, label: "Thursday", value: 2.5),
        .init(type: .moneyIn, label: "Friday", value: 2.9)
    ]
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
    
    private let weekCashFlowInData: [CashFlowDay] = [
//        .init(type: .moneyIn, label: "Monday", value: 1),
        .init(type: .moneyIn, label: "Tuesday", value: 0.3),
        .init(type: .moneyIn, label: "Wednesday", value: 1),
        .init(type: .moneyIn, label: "Thursday", value: 0.2),
        .init(type: .moneyIn, label: "Friday", value: 2)
    ]
    
    private let weekCashFlowOutData: [CashFlowDay] = [
        .init(type: .moneyOut, label: "Monday", value: 0.2),
        .init(type: .moneyOut, label: "Tuesday", value: 0.9),
        .init(type: .moneyOut, label: "Wednesday", value: 1),
        .init(type: .moneyOut, label: "Thursday", value: 1),
        .init(type: .moneyOut, label: "Friday", value: 0.6)
    ]
    
    private let monthCashFlowInData: [CashFlowDay] = [
        .init(type: .moneyIn, label: "Monday", value: 5),
        .init(type: .moneyIn, label: "Tuesday", value: 1.3),
        .init(type: .moneyIn, label: "Wednesday", value: 6),
        .init(type: .moneyIn, label: "Thursday", value: 0.7),
        .init(type: .moneyIn, label: "Friday", value: 1)
    ]
    
    private let monthCashFlowOutData: [CashFlowDay] = [
        .init(type: .moneyOut, label: "Monday", value: 3.2),
        .init(type: .moneyOut, label: "Tuesday", value: 5.9),
        .init(type: .moneyOut, label: "Wednesday", value: 4),
        .init(type: .moneyOut, label: "Thursday", value: 1),
        .init(type: .moneyOut, label: "Friday", value: 1.3)
    ]
    
    func buildCashFlowGraphData() async {
        state = .loading(placeholder: CashFlowSeries.placeholders)
        
        if state.isLoading() {
            print("Holup")
        }
        
//        self.cashFlowGraphData = CashFlowDay.placeholderData
        
        try! await Task.sleep(nanoseconds: 2_000_000_000)

        let weekToDate =  weekCashFlowOutData
        let monthToDate = monthCashFlowOutData
        
        
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
    
    @State var selectedElement: String = ""
    
    var body: some View {
        Chart(cashFlowGraphData) { entry in
            BarMark(
                x: .value("Day", entry.label),
                y: .value("Cash Out", entry.value)
            )
            .foregroundStyle(by: .value("Cash Flow Type", entry.type.rawValue))
        }
        .chartBackground { chart in
            GeometryReader { geo in
                let lineHeight = geo[chart.plotAreaFrame].maxY
                
                let popoverStartPosition = chart.position(forX: selectedElement) ?? 0
                
                ZStack {
                    Rectangle()
                        .fill(.quaternary)
                        .frame(width: 2, height: lineHeight)
                        .position(x: popoverStartPosition, y: lineHeight / 2)
                    
                    if isPresented {
//                        Rectangle()
//                            .fill(.red)
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
                    self.selectedElement = findElement(
                        geometry: geo,
                        chart: proxy,
                        location: tapLocation
                    )
                    
                    self.isPresented.toggle()
                }
            }
        }
    }
    
    func findElement(
        geometry: GeometryProxy,
        chart: ChartProxy,
        location: CGPoint
    ) -> String {
        if let bar: String = chart.value(atX: location.x) {
            print(bar)
            
            let matched = cashFlowGraphData.compactMap { entry in
                entry.label == bar
            }
            
            return bar
        } else {
            return ""
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
