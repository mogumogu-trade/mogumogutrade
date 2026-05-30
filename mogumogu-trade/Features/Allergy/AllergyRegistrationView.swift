import Dependencies
import SwiftUI

/// 教員用: 生徒ごとのアレルギー登録画面。
struct AllergyRegistrationView: View {
    @State var viewModel: AllergyRegistrationViewModel

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                studentSection
                allergenSection
                messages
                saveButton
            }
            .padding(24)
        }
        .background(Color(red: 0.95, green: 0.96, blue: 0.98).ignoresSafeArea())
        .navigationTitle("アレルギーとうろく")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("せんせい用")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(red: 0.85, green: 0.35, blue: 0.30))
                .clipShape(Capsule())
            Text("生徒ごとに アレルギーを とうろくしてね")
                .font(.system(size: 18, weight: .black, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var studentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("だれの とうろく？")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.secondary)

            if viewModel.roster.isEmpty {
                Text("生徒が いないよ")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.roster) { student in
                            studentChip(student)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func studentChip(_ student: StudentAllergy) -> some View {
        let selected = student.studentNumber == viewModel.selectedStudentNumber
        return Button {
            viewModel.select(student.studentNumber)
        } label: {
            VStack(spacing: 2) {
                Text(student.displayName)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                if !student.allergens.isEmpty {
                    Text("アレルギー \(student.allergens.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(selected ? .white.opacity(0.85) : .secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(selected ? Color(red: 0.18, green: 0.18, blue: 0.18) : Color.white)
            .foregroundStyle(selected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private var allergenSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("アレルギーの ある食べもの")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Allergen.allCases) { allergen in
                    allergenCard(allergen)
                }
            }
            .opacity(viewModel.selectedStudent == nil ? 0.5 : 1)
        }
    }

    private func allergenCard(_ allergen: Allergen) -> some View {
        let on = viewModel.isOn(allergen)
        return Button {
            viewModel.toggle(allergen)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                Text(allergen.displayName)
                    .font(.system(size: 15, weight: .black, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(on ? Color(red: 1.0, green: 0.58, blue: 0.53).opacity(0.30) : Color.white)
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        on ? Color(red: 0.85, green: 0.35, blue: 0.30) : Color.black.opacity(0.08),
                        lineWidth: on ? 2 : 1
                    )
            )
        }
        .disabled(viewModel.selectedStudent == nil)
    }

    @ViewBuilder
    private var messages: some View {
        if let saved = viewModel.savedMessage {
            Text(saved)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.green)
        }
        if let error = viewModel.errorMessage {
            Text(error)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.red)
        }
    }

    private var saveButton: some View {
        VStack(spacing: 8) {
            Button {
                Task { await viewModel.save() }
            } label: {
                HStack {
                    if viewModel.isSaving { ProgressView().tint(.white) }
                    Text(viewModel.isSaving ? "ほぞんしているよ…" : "ほぞんする")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(viewModel.canSave ? Color(red: 0.18, green: 0.18, blue: 0.18) : Color.gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(!viewModel.canSave)

            if let hint = viewModel.saveHint {
                Text(hint)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.red)
            }
        }
    }
}

#Preview("正常") {
    NavigationStack {
        AllergyRegistrationView(viewModel: AllergyRegistrationViewModel(classId: "123456"))
    }
}

#Preview("空（生徒なし）") {
    withDependencies {
        $0.allergyClient.loadRoster = { _ in [] }
    } operation: {
        NavigationStack {
            AllergyRegistrationView(viewModel: AllergyRegistrationViewModel(classId: "123456"))
        }
    }
}

#Preview("エラー") {
    withDependencies {
        $0.allergyClient.loadRoster = { _ in throw URLError(.notConnectedToInternet) }
    } operation: {
        NavigationStack {
            AllergyRegistrationView(viewModel: AllergyRegistrationViewModel(classId: "123456"))
        }
    }
}
