import Dependencies
import DependenciesMacros
import Foundation

/// クラス内の生徒ごとのアレルギー登録情報を扱う Client。
///
/// v1（今回）はクライアント側ストア（UserDefaults に JSON 保存）。
/// AGENTS.md の方針どおり、将来は Firestore `classes/{classId}/students/{studentId}.allergens`
/// に置き換え、Security Rules でサーバ側検証を加える。
@DependencyClient
struct AllergyClient: Sendable {
    /// クラスの生徒名簿（アレルギー登録付き）を読み込む。
    var loadRoster: @Sendable (_ classId: String) async throws -> [StudentAllergy]
    /// 1人分のアレルギー登録を保存する。
    var save: @Sendable (_ classId: String, _ allergy: StudentAllergy) async throws -> Void
}

extension AllergyClient: DependencyKey {
    static let liveValue: AllergyClient = {
        let defaults = UserDefaults.standard
        func key(_ classId: String) -> String { "allergyRoster.\(classId)" }

        func load(_ classId: String) -> [StudentAllergy] {
            guard
                let data = defaults.data(forKey: key(classId)),
                let roster = try? JSONDecoder().decode([StudentAllergy].self, from: data)
            else {
                // 初回は仮の名簿を用意する（将来はクラス参加データ / Firestore から取得）。
                return AllergyClient.seedRoster
            }
            return roster.sorted { $0.studentNumber < $1.studentNumber }
        }

        return AllergyClient(
            loadRoster: { classId in
                load(classId)
            },
            save: { classId, allergy in
                var roster = load(classId)
                if let index = roster.firstIndex(where: { $0.studentNumber == allergy.studentNumber }) {
                    roster[index] = allergy
                } else {
                    roster.append(allergy)
                }
                let data = try JSONEncoder().encode(roster.sorted { $0.studentNumber < $1.studentNumber })
                defaults.set(data, forKey: key(classId))
            }
        )
    }()

    static let previewValue = AllergyClient(
        loadRoster: { _ in seedRoster },
        save: { _, _ in }
    )

    /// 動作確認・プレビュー用の仮名簿。
    static let seedRoster: [StudentAllergy] = [
        StudentAllergy(studentNumber: 1, nickname: "もぐ", allergens: [.milk]),
        StudentAllergy(studentNumber: 2, nickname: "はる", allergens: []),
        StudentAllergy(studentNumber: 3, nickname: "りん", allergens: [.egg, .wheat]),
        StudentAllergy(studentNumber: 8, nickname: "そら", allergens: []),
    ]
}

extension DependencyValues {
    var allergyClient: AllergyClient {
        get { self[AllergyClient.self] }
        set { self[AllergyClient.self] = newValue }
    }
}
