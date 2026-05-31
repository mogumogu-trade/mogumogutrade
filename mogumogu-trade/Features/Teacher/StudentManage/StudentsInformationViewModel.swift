import Foundation
import Dependencies

@Observable
@MainActor
final class StudentsInformationViewModel{
    var students:[Student] = StudentMock.mockStudents
    var classId: String
    @ObservationIgnored @Dependency(\.studentClient) private var studentClient
    init( classId: String) {
        self.classId = classId
          }
    
    func getStudents() async {
        do{
            self.students = try await self.studentClient.getStudents(classId)
        }catch{
            print(error)
        }
    }
}
