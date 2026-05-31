import Foundation
import Dependencies

@Observable
@MainActor
final class StudentsInformationViewModel{
    var students:[Student] = StudentMock.mockStudents
    @ObservationIgnored @Dependency(\.studentClient) private var studentClient
    
    func getStudents() async {
        do{
            self.students = try await self.studentClient.getStudents("123456")
        }catch{
            print(error)
        }
    }
}
