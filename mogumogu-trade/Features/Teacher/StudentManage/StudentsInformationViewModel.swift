import Foundation

@Observable
@MainActor
final class StudentsInformationViewModel{
    var students:[Student] = StudentMock.mockStudents
}
