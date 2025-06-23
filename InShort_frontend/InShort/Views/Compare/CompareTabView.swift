import SwiftUI

struct CompareTabView: View {
    @StateObject private var viewModel = CompareViewModel()
    @State private var showingFirstPicker = false
    @State private var showingSecondPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: AppLayout.spacing) {
                HStack(spacing: AppLayout.spacing) {
                    // First bill selector
                    Button {
                        showingFirstPicker = true
                    } label: {
                        HStack {
                            Text(viewModel.firstBill?.title ?? "Select First Bill")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.text)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .padding()
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(AppLayout.cornerRadius)
                    }
                    .sheet(isPresented: $showingFirstPicker) {
                        BillPickerView(bills: viewModel.bills) { bill in
                            viewModel.selectFirst(bill)
                            showingFirstPicker = false
                        }
                    }

                    // Second bill selector
                    Button {
                        showingSecondPicker = true
                    } label: {
                        HStack {
                            Text(viewModel.secondBill?.title ?? "Select Second Bill")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.text)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .padding()
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(AppLayout.cornerRadius)
                    }
                    .sheet(isPresented: $showingSecondPicker) {
                        BillPickerView(bills: viewModel.bills) { bill in
                            viewModel.selectSecond(bill)
                            showingSecondPicker = false
                        }
                    }
                }
                .padding(.horizontal)

                // Comparison view or prompt
                if let b1 = viewModel.firstBill, let b2 = viewModel.secondBill {
                    BillComparisonView(
                        bill1: b1,
                        bill2: b2,
                        comparison: viewModel.comparisonText
                    )
                    .transition(.opacity)
                } else {
                    Spacer()
                    Text("Select two bills to compare side-by-side.")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                }
            }
            .navigationTitle("Compare Bills")
            .onAppear { viewModel.loadBills() }
        }
    }
}

struct CompareTabView_Previews: PreviewProvider {
    static var previews: some View {
        CompareTabView()
    }
}
