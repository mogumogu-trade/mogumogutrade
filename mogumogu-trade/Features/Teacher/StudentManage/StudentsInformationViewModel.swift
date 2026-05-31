import Foundation
import Dependencies

@Observable
@MainActor
final class StudentsInformationViewModel{
    var students:[Student] = StudentMock.mockStudents
    /// 出席番号 → 残高（pointLedger の合計）。残高の正はこちら。
    var balances: [Int: Int] = [:]
    var classId: String
    @ObservationIgnored @Dependency(\.studentClient) private var studentClient
    @ObservationIgnored @Dependency(\.mileageClient) private var mileageClient
    init( classId: String) {
        self.classId = classId
          }

    func getStudents() async {
        do{
            self.students = try await self.studentClient.getStudents(classId)
            self.balances = try await self.mileageClient.fetchClassBalances(classId)
        }catch{
            print(error)
        }
    }

    /// 表示用の残高。台帳に履歴が無ければ 0。
    func point(for student: Student) -> Int {
        balances[student.studentNumber] ?? 0
    }
}
