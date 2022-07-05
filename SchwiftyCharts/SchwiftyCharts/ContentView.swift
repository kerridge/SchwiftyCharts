import Charts
import SwiftUI

enum CashFlowType: String {
    case moneyIn = "Money In"
    case moneyOut = "Money Out"
}

struct CashFlowDay: Identifiable, Equatable {
    var type: CashFlowType
    var label: String
    var value: Double
    var id = UUID()
    
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
    
//    func isLoading() -> Bool {
//        return (self == .loading)
//    }
}

@MainActor
final class CashFlowGraphViewModel: ObservableObject {
    @Published var cashFlowGraphData: [CashFlowDay] = []
    @Published var state: LoadingState<[CashFlowDay]> = .idle
    
    private let cashFlowInData: [CashFlowDay] = [
        .init(type: .moneyIn, label: "Monday", value: 1),
        .init(type: .moneyIn, label: "Tuesday", value: 0.3),
        .init(type: .moneyIn, label: "Wednesday", value: 1),
        .init(type: .moneyIn, label: "Thursday", value: 0.2),
        .init(type: .moneyIn, label: "Friday", value: 2)
    ]
    
    private let cashFlowOutData: [CashFlowDay] = [
        .init(type: .moneyOut, label: "Monday", value: 0.2),
        .init(type: .moneyOut, label: "Tuesday", value: 0.9),
        .init(type: .moneyOut, label: "Wednesday", value: 1),
        .init(type: .moneyOut, label: "Thursday", value: 1),
        .init(type: .moneyOut, label: "Friday", value: 0.6)
    ]
    
    func buildCashFlowGraphData() async {
        state = .loading(placeholder: CashFlowDay.placeholderData)
        
        try! await Task.sleep(nanoseconds: 3_000_000_000)

        self.cashFlowGraphData = cashFlowOutData + cashFlowInData
        
        state = .loaded(content: self.cashFlowGraphData)
    }
}

struct ContentView: View {
    @Namespace private var animation

    @ObservedObject var viewModel = CashFlowGraphViewModel()
    
    @State var graphData: [CashFlowDay] = []
    
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 200)
            
            Text("Cash In & Out")
            
            switch viewModel.state {
            case .idle:
                EmptyView()
                
            case let .loading(placeholder):
                CashFlowGraph(cashFlowGraphData: placeholder)
                    .redacted(reason: .placeholder)
                    .chartForegroundStyleScale([
                        CashFlowType.moneyIn.rawValue: .black,
                        CashFlowType.moneyOut.rawValue: .gray,
                    ])
                    .matchedGeometryEffect(id: "Graph", in: animation)
//                    .onAppear {
//                        let baseAnimation = Animation.easeInOut(duration: 3)
//
//                        withAnimation(baseAnimation) {
//                            $viewModel.state
//                        }
//                    }
                
            case let .loaded(content):
                CashFlowGraph(cashFlowGraphData: content)
                    .chartForegroundStyleScale([
                        CashFlowType.moneyIn.rawValue: .green,
                        CashFlowType.moneyOut.rawValue: .red,
                    ])
                    .matchedGeometryEffect(id: "Graph", in: animation)
            }
        }
        .task {
            await viewModel.buildCashFlowGraphData()
        }
        .padding()
    }
}

struct CashFlowGraph: View {
    @State var cashFlowGraphData: [CashFlowDay]
    
    var body: some View {
        Chart(cashFlowGraphData) {
            BarMark(
                x: .value("Day", $0.label),
                y: .value("Cash Out", $0.value)
            )
            .foregroundStyle(by: .value("Cash Flow Type", $0.type.rawValue))
        }
        .onAppear {
            withAnimation() {}
        }
//        .animation(.easeInOut(duration: 0.5))
//        .transition(
////            .move(edge: .bottom)
//            .slide
////            .scale
//            .combined(with: .opacity)
//            .animation(.easeInOut(duration: 0.5))
//        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
