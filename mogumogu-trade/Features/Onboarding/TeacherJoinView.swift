import Dependencies
import SwiftUI

struct TeacherJoinView: View {
    @State var viewModel = TeacherViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    
                    inputCard(title: "クラスコード", hint: viewModel.classCodeHint) {
                        TextField("000000", text: Binding(
                            get: { viewModel.classCode },
                            set: { viewModel.classCode = viewModel.sanitizeClassCode($0) }
                        ))
                        .keyboardType(.numberPad)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                    }
                    
                    inputCard(title: "パスワード", hint: "") {
                        SecureField("", text: $viewModel.pass )
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                   submitButton
                       
                }
                .padding(24)
            }
            .navigationDestination(isPresented: $viewModel.isAuthenticated, destination: {
                TeacherDashboardView(classId: viewModel.classCode)
            })
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
            Text("管理画面に参加")
                .font(.system(size: 26, weight: .black, design: .rounded))
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
                Text(viewModel.isSubmitting ? "ためしているよ…" : "ログイン")
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
    TeacherJoinView(viewModel: TeacherViewModel())
}

#Preview("バリデーションエラー") {
    let vm = TeacherViewModel()
    vm.classCode = ""
    vm.pass = ""
    return TeacherJoinView(viewModel: vm)
}

#Preview("クラス未存在エラー") {
    let vm = withDependencies {
        $0.classClient.verifyClass = { _ in false }
    } operation: {
        TeacherViewModel()
    }
    vm.classCode = "123456"
    vm.pass = ""
    vm.errorMessage = "そのクラスコードは見つかりません"
    return TeacherJoinView(viewModel: vm)
}

