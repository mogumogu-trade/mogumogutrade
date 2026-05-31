import Dependencies
import SwiftUI

struct ClassJoinView: View {
    @State var viewModel: ClassJoinViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header

                    inputCard(title: "クラスコード（4〜6けた）", hint: viewModel.classCodeHint) {
                        TextField("000000", text: Binding(
                            get: { viewModel.classCode },
                            set: { viewModel.classCode = viewModel.sanitizeClassCode($0) }
                        ))
                        .keyboardType(.numberPad)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                    }

                    inputCard(title: "出席ばんごう", hint: viewModel.studentNumberHint) {
                        TextField("12", text: Binding(
                            get: { viewModel.studentNumberText },
                            set: { viewModel.studentNumberText = viewModel.sanitizeStudentNumber($0) }
                        ))
                        .keyboardType(.numberPad)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                    }

                    inputCard(title: "ニックネーム（1〜8もじ）", hint: viewModel.nicknameHint) {
                        TextField("もぐ", text: Binding(
                            get: { viewModel.nickname },
                            set: { viewModel.nickname = viewModel.sanitizeNickname($0) }
                        ))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    submitButton
                    NavigationLink {
                        TeacherDashboardView()
                    } label: {
                        Text("先生はこちら")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(24)
            }
            .background(Color(red: 0.95, green: 0.96, blue: 0.98).ignoresSafeArea())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 54))
                .foregroundStyle(AppColors.primary)
            Text("クラスに さんかしよう")
                .font(.system(size: 26, weight: .black, design: .rounded))
            Text("せんせいから もらった コードを いれてね")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private func inputCard<Content: View>(
        title: String,
        hint: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.secondary)
            content()
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.primaryLight.opacity(0.55), lineWidth: 2)
                )
            if let hint {
                Text(hint)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var submitButton: some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            HStack {
                if viewModel.isSubmitting {
                    ProgressView().tint(.white)
                }
                Text(viewModel.isSubmitting ? "ためしているよ…" : "さんかする！")
                    .font(.system(size: 18, weight: .black, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.canSubmit ? AppColors.primary : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: viewModel.canSubmit ? AppColors.primary.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
        }
        .disabled(!viewModel.canSubmit)
    }
}

#Preview("空の入力") {
    ClassJoinView(viewModel: ClassJoinViewModel(onJoined: { _ in }))
}

#Preview("バリデーションエラー") {
    let vm = ClassJoinViewModel(onJoined: { _ in })
    vm.classCode = "12"
    vm.studentNumberText = "0"
    vm.nickname = ""
    return ClassJoinView(viewModel: vm)
}

#Preview("クラス未存在エラー") {
    let vm = withDependencies {
        $0.classClient.verifyClass = { _ in false }
    } operation: {
        ClassJoinViewModel(onJoined: { _ in })
    }
    vm.classCode = "123456"
    vm.studentNumberText = "12"
    vm.nickname = "もぐ"
    vm.errorMessage = "そのクラスコードは見つかりません"
    return ClassJoinView(viewModel: vm)
}
