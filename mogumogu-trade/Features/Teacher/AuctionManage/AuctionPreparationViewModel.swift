import Foundation
import Observation

@Observable
@MainActor
final class AuctionPreparationViewModel {
    var menus: [AuctionActiveModel] = []

    // 入力値
    var newMenuName: String = ""
    var newMenuCount: Int = 1

    func addMenu() {
        guard !newMenuName.isEmpty else { return }

        menus.append(
            AuctionActiveModel(
                name: newMenuName,
                stock: newMenuCount
            )
        )

        newMenuName = ""
        newMenuCount = 1
    }

    func deleteMenu(menu: AuctionActiveModel) {
        menus.removeAll { $0.id == menu.id }
    }
}
