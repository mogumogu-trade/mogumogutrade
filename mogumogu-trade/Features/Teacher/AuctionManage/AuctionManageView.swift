import Dependencies
import SwiftUI

struct AuctionManageView: View {
    @State private var classCode: String
    @State private var newMenuName = ""
    @State private var preparedMenuName: String?
    @State private var latestRoom: AuctionRoom?
    @State private var bids: [AuctionBid] = []
    @State private var message: String?
    @State private var errorMessage: String?
    @State private var isWorking = false

    @Dependency(\.auctionClient) private var auctionClient
    @Dependency(\.date.now) private var now

    init(classCode: String? = nil) {
        @Dependency(\.profileStorage) var profileStorage
        _classCode = State(initialValue: classCode ?? profileStorage.load()?.classId ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let latestRoom, latestRoom.status == .open {
                    activeView(room: latestRoom)
                } else {
                    preparationView
                }
            }
            .background(Color(white: 0.96))
            .navigationTitle("オークション管理")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(latestRoom?.status == .open ? .red : .orange)
                }
            }
        }
        .task(id: classCode) {
            await observeLatestRoom()
        }
        .task(id: bidObservationID) {
            await observeBidsForLatestRoom()
        }
    }

    private var preparationView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text(statusText)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color(white: 0.9))
                    .cornerRadius(20)

                Text(statusDescription)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.orange.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [6]))
            )

            VStack(alignment: .leading, spacing: 12) {
                Text("出品メニューの追加")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)

                TextField("メニュー名 (例: 唐揚げ)", text: $newMenuName)
                    .padding()
                    .background(Color(white: 0.96))
                    .cornerRadius(12)
                    .font(.system(size: 16, weight: .bold))
                    .disabled(isWorking)

                Button {
                    preparedMenuName = trimmedMenuName
                    newMenuName = ""
                    message = nil
                    errorMessage = nil
                } label: {
                    Text("追加")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(trimmedMenuName.isEmpty ? .gray : .orange)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(trimmedMenuName.isEmpty ? Color(white: 0.9) : Color.orange.opacity(0.15))
                        .cornerRadius(12)
                }
                .disabled(trimmedMenuName.isEmpty || isWorking)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)

            ScrollView {
                VStack(spacing: 12) {
                    if let preparedMenuName {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(preparedMenuName)
                                    .font(.system(size: 16, weight: .bold))
                            }
                            Spacer()
                            Button {
                                self.preparedMenuName = nil
                                message = nil
                                errorMessage = nil
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.gray)
                                    .padding(8)
                            }
                            .disabled(isWorking)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
                    } else {
                        Text("追加されたメニューがここに表示されます")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(Color.white.opacity(0.5))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                            )
                    }
                }
                .padding(.top, 4)
            }

            statusMessage

            Button {
                Task { await createRoom() }
            } label: {
                HStack {
                    if isWorking {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                    }
                    Text(isWorking ? "開催中..." : "この内容でオークションを開始")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                }
                .foregroundColor(canStart ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(canStart ? Color.orange : Color(white: 0.85))
                .cornerRadius(16)
                .shadow(color: canStart ? Color(red: 0.76, green: 0.25, blue: 0.05) : .clear, radius: 0, x: 0, y: 5)
            }
            .disabled(!canStart)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
    }

    private func activeView(room: AuctionRoom) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("現在開催中")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .cornerRadius(20)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("出品中のメニュー")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)

                ScrollView {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(room.itemName)
                                    .font(.system(size: 18, weight: .bold))
                            }
                            Spacer()
                            Text("受付中")
                                .font(.system(size: 13, weight: .black))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                    }
                }

                ScrollView {
                    if bids.isEmpty {
                        Text("まだベットはありません")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                            .background(Color.white.opacity(0.5))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                            )
                    } else {
                        VStack(spacing: 0) {
                            ForEach(bids) { bid in
                                HStack(spacing: 12) {
                                    Text(bid.student.nickname)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)

                                    Spacer()

                                    Text("\(bid.amount)P")
                                        .font(.system(size: 14, weight: .black, design: .rounded))
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.orange.opacity(0.15))
                                        .cornerRadius(8)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                                if bid.id != bids.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                }
            }

            Spacer()
            statusMessage

            Button {
                Task { await closeRoom() }
            } label: {
                HStack {
                    if isWorking {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "square.fill")
                            .font(.system(size: 18))
                    }
                    Text(isWorking ? "終了中..." : "オークションを終了する")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color(red: 0.15, green: 0.2, blue: 0.25))
                .cornerRadius(16)
                .shadow(color: Color(red: 0.1, green: 0.1, blue: 0.15), radius: 0, x: 0, y: 5)
            }
            .disabled(!canOperate)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var statusMessage: some View {
        if let message {
            Text(message)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        if let errorMessage {
            Text(errorMessage)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var statusText: String {
        if latestRoom?.status == .closed {
            return "締切済み"
        }
        return "準備中 (未開催)"
    }

    private var statusDescription: String {
        if latestRoom?.status == .closed {
            return "結果は生徒の画面に表示されます。\n次の開催もできます。"
        }
        return "あまったメニューを追加して\nオークションを開始しましょう。"
    }

    private var trimmedMenuName: String {
        newMenuName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canOperate: Bool {
        classCode.count >= 4 && classCode.count <= 6 && !isWorking
    }

    private var canStart: Bool {
        canOperate && preparedMenuName != nil
    }

    private var bidObservationID: String {
        guard let latestRoom else { return "\(classCode)-none" }
        return "\(classCode)-\(latestRoom.id)-\(latestRoom.status.rawValue)"
    }

    private func observeLatestRoom() async {
        guard classCode.count >= 4 else {
            latestRoom = nil
            bids = []
            return
        }

        do {
            for try await room in auctionClient.observeLatestRoom(
                classCode,
                MealDate.string(for: now)
            ) {
                latestRoom = room
                if room?.status != .open {
                    bids = []
                }
                errorMessage = nil
            }
        } catch {
            errorMessage = "オークションを読みこめませんでした"
        }
    }

    private func observeBidsForLatestRoom() async {
        guard
            classCode.count >= 4,
            let latestRoom,
            latestRoom.status == .open
        else {
            bids = []
            return
        }

        do {
            for try await latestBids in auctionClient.observeBids(classCode, latestRoom.id) {
                bids = latestBids
                errorMessage = nil
            }
        } catch {
            errorMessage = "ベットした生徒を読みこめませんでした"
        }
    }

    private func createRoom() async {
        guard canStart, let preparedMenuName else { return }
        isWorking = true
        message = nil
        errorMessage = nil
        defer { isWorking = false }

        do {
            latestRoom = try await auctionClient.createRoom(
                classCode,
                preparedMenuName,
                MealDate.string(for: now)
            )
            self.preparedMenuName = nil
            message = "\(preparedMenuName) を開催しました"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func closeRoom() async {
        guard canOperate, let latestRoom else { return }
        isWorking = true
        message = nil
        errorMessage = nil
        defer { isWorking = false }

        do {
            let result = try await auctionClient.closeRoom(classCode, latestRoom.id)
            if let winner = result.winner {
                message = "\(winner.student.displayName) が落札しました"
            } else {
                message = "落札者なしで締め切りました"
            }
        } catch {
            errorMessage = "締め切りできませんでした"
        }
    }
}

#Preview {
    AuctionManageView(classCode: "123456")
}
