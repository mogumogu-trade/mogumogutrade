import SwiftUI

struct TeacherView: View {
    @State private var menus: [AuctionActiveModel] = []
    @State private var isAuctionActive = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                if isAuctionActive {
                    AuctionActiveView(
                        menus: $menus,
                        isAuctionActive: $isAuctionActive
                    )
                } else {
                    AuctionPreparationView(
                        menus: $menus,
                        isAuctionActive: $isAuctionActive
                    )
                }
            }
            .background(Color(white: 0.96))
            .navigationTitle("オークション管理")
            .navigationBarTitleDisplayMode(.large) 
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(isAuctionActive ? .red : .orange)
                }
            }
        }
    }
}

#Preview {
    TeacherView()
}
