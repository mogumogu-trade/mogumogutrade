import Dependencies
import SwiftUI

struct AuctionManageView: View {
    private let itemOptions = ["プリン", "ゼリー", "ヨーグルト", "フルーツ"]

    @State private var classCode: String
    @State private var selectedItemName = "プリン"
    @State private var latestRoom: AuctionRoom?
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
        ScrollView {
            VStack(spacing: 20) {
                manageCard
            }
            .padding(20)
        }
        .background(TeacherColors.cream.opacity(0.35))
        .task(id: classCode) {
            await observeLatestRoom()
        }
    }

    private var manageCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(TeacherColors.accentOrange)
                Text("オークション開催")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(TeacherColors.chocoLight)
            }

            classCodeField
            statusBox

            if latestRoom?.status == .open {
                closeButton
            } else {
                createForm
            }

            if let message {
                Text(message)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(TeacherColors.chocoLight)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.red)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray.opacity(0.2), lineWidth: 2))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }

    private var classCodeField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("クラスコード")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(TeacherColors.textLight)

            TextField("000000", text: Binding(
                get: { classCode },
                set: { classCode = sanitizeClassCode($0) }
            ))
            .keyboardType(.numberPad)
            .font(.system(size: 22, weight: .black, design: .rounded))
            .multilineTextAlignment(.center)
            .padding(.vertical, 10)
            .background(TeacherColors.cream)
            .cornerRadius(12)
        }
    }

    private var statusBox: some View {
        VStack(spacing: 8) {
            Text(statusText)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(TeacherColors.textLight)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(20)

            Text(statusDescription)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(TeacherColors.textLight)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(15)
        .background(TeacherColors.cream)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [6]))
        )
    }

    private var createForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("あまったメニュー")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(TeacherColors.textLight)

            Picker("あまったメニュー", selection: $selectedItemName) {
                ForEach(itemOptions, id: \.self) { item in
                    Text(item).tag(item)
                }
            }
            .pickerStyle(.segmented)

            Button {
                Task { await createRoom() }
            } label: {
                HStack {
                    if isWorking {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "plus")
                    }
                    Text(isWorking ? "開催中..." : "新しいオークションを開催")
                }
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(canOperate ? TeacherColors.accentOrange : Color.gray)
                .cornerRadius(15)
                .shadow(color: Color(red: 0.7, green: 0.3, blue: 0.0).opacity(canOperate ? 1 : 0), radius: 0, x: 0, y: 5)
            }
            .disabled(!canOperate)
        }
    }

    private var closeButton: some View {
        Button {
            Task { await closeRoom() }
        } label: {
            HStack {
                if isWorking {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.seal.fill")
                }
                Text(isWorking ? "締め切り中..." : "締め切って結果を出す")
            }
            .font(.system(size: 16, weight: .heavy, design: .rounded))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(canOperate ? TeacherColors.accentOrange : Color.gray)
            .cornerRadius(15)
            .shadow(color: Color(red: 0.7, green: 0.3, blue: 0.0).opacity(canOperate ? 1 : 0), radius: 0, x: 0, y: 5)
        }
        .disabled(!canOperate)
    }

    private var statusText: String {
        guard let latestRoom else { return "現在は未開催" }
        switch latestRoom.status {
        case .open:
            return "\(latestRoom.itemName) を開催中"
        case .closed:
            return "\(latestRoom.itemName) は締切済み"
        }
    }

    private var statusDescription: String {
        guard let latestRoom else {
            return "給食であまったメニューを\n出品しましょう。"
        }
        switch latestRoom.status {
        case .open:
            return "生徒がベットしています。\n集まったら締め切ってください。"
        case .closed:
            return "結果は生徒の画面に表示されます。\n次の開催もできます。"
        }
    }

    private var canOperate: Bool {
        classCode.count >= 4 && classCode.count <= 6 && !isWorking
    }

    private func observeLatestRoom() async {
        guard classCode.count >= 4 else {
            latestRoom = nil
            return
        }

        do {
            for try await room in auctionClient.observeLatestRoom(
                classCode,
                MealDate.string(for: now)
            ) {
                latestRoom = room
                errorMessage = nil
            }
        } catch {
            errorMessage = "オークションを読みこめませんでした"
        }
    }

    private func createRoom() async {
        guard canOperate else { return }
        isWorking = true
        message = nil
        errorMessage = nil
        defer { isWorking = false }

        do {
            latestRoom = try await auctionClient.createRoom(
                classCode,
                selectedItemName,
                MealDate.string(for: now)
            )
            message = "\(selectedItemName) を開催しました"
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

    private func sanitizeClassCode(_ raw: String) -> String {
        String(raw.filter(\.isNumber).prefix(6))
    }
}

#Preview {
    AuctionManageView(classCode: "123456")
}
