//
//  Login.swift
//  Notes
//
//  Created by user250993 on 4/5/24.
//

import SwiftUI
import Firebase
import Lottie

struct Login: View {
    @State private var activeTab: Tab = .login
    @State private var isLoading: Bool = false
    @State private var showEmailVerificationView: Bool = false
    @State private var emailAddress: String = ""
    @State private var password: String = ""
    @State private var reEnterPassword: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var showResetAlert: Bool = false
    @State private var resetEmailAddress: String = ""
    @AppStorage("log_status") private var logStatus: Bool = false
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Email Address", text: $emailAddress)
                        .keyboardType(.emailAddress)
                        .customTextField("person")
                    
                    SecureField("Password", text: $password)
                        .customTextField("lock", 0, activeTab == .login ? 10 : 0)
                    
                    if activeTab == .SignUp {
                        SecureField("Re-Enter Password", text: $reEnterPassword)
                            .customTextField("lock", 0, activeTab != .login ? 10 : 0)
                    }
                } header: {
                    Picker("", selection: $activeTab) {
                        ForEach(Tab.allCases, id: \.rawValue) {
                            Text($0.rawValue)
                                .tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(.init(top: 15, leading: 0, bottom: 15, trailing: 0))
                    .listRowSeparator(.hidden)
                } footer: {
                    VStack(alignment: .trailing, spacing: 12, content: {
                        if activeTab == .login {
                            Button("Forgot Password?") {
                                showResetAlert = true
                            }
                            .font(.caption)
                            .tint(Color.accentColor)
                        }
                        
                        Button(action: loginAndSignUp, label: {
                            HStack(spacing: 12) {
                                Text(activeTab == .login ? "Login" : "Create Account")
                                
                                Image(systemName: "arrow.right")
                                    .font(.callout)
                            }
                            .padding(.horizontal, 10)
                        })
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .showLoadingIndicator(isLoading)
                        .disabled(buttonStatus)
                    })
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .listRowInsets(.init(top: 15, leading: 0, bottom: 0, trailing: 0))
                }
                .disabled(isLoading)
            }
            .animation(.snappy, value: activeTab)
            .listStyle(.insetGrouped)
            .navigationTitle("Welcome Back!")
        }
        .sheet(isPresented: $showEmailVerificationView, content: {
            EmailVerificationView()
                .presentationDetents([.height(350)])
                .presentationCornerRadius(25)
                .interactiveDismissDisabled()
        })
        .alert(alertMessage, isPresented: $showAlert) {  }
        .alert("Reset Password", isPresented: $showResetAlert, actions: {
            TextField("Email Address", text: $resetEmailAddress)
            
            Button("Send Reset Link", role: .destructive, action: sendResetLink)
            
            Button("Cancel", role: .cancel) {
                resetEmailAddress = ""
            }
        }, message: {
            Text("Enter the email address")
        })
        .onChange(of: activeTab, initial: false) { oldValue, newValue in
            password = ""
            reEnterPassword = ""
        }
    }
    
    @ViewBuilder
    func EmailVerificationView() -> some View {
        VStack(spacing: 6) {
            GeometryReader { _ in
                if let bundle = Bundle.main.path(forResource: "EmailAnimation", ofType: "json") {
                    LottieView {
                        await LottieAnimation.loadedFrom(url: URL(filePath: bundle))
                    }
                    .playing(loopMode: .loop)
                }
            }
            
            Text("Verification")
                .font(.title.bold())
            
            Text("A verification email has been sent to your email address.\nPlease verify to continue.")
                .multilineTextAlignment(.center)
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.horizontal, 25)
        }
        .overlay(alignment: .topTrailing, content: {
            Button("Cancel") {
                showEmailVerificationView = false
                isLoading = false
            }
            .padding(15)
        })
        .padding(.bottom, 15)
        .onReceive(Timer.publish(every: 2, on: .main, in: .default).autoconnect(), perform: { _ in
            if let user = Auth.auth().currentUser {
                user.reload()
                if user.isEmailVerified {
                    /// Email Successfully Verified
                    showEmailVerificationView = false
                    logStatus = true
                }
            }
        })
    }
    
    func sendResetLink() {
        Task {
            do {
                if resetEmailAddress.isEmpty {
                    await presentAlert("Please enter an email address.")
                    return
                }
                
                isLoading = true
                try await Auth.auth().sendPasswordReset(withEmail: resetEmailAddress)
                await presentAlert("Please check your email inbox and follow the steps to reset your password!")
                
                resetEmailAddress = ""
                isLoading = false
            } catch {
                await presentAlert(error.localizedDescription)
            }
        }
    }
    
    func loginAndSignUp() {
        Task {
            isLoading = true
            do {
                if activeTab == .login {
    
                    let result = try await Auth.auth().signIn(withEmail: emailAddress, password: password)
                    if result.user.isEmailVerified {
                        
                        logStatus = true
                    } else {
                        try await result.user.sendEmailVerification()
                        showEmailVerificationView = true
                    }
                } else {
                    if password == reEnterPassword {
                        let result = try await Auth.auth().createUser(withEmail: emailAddress, password: password)
                        try await result.user.sendEmailVerification()
                        showEmailVerificationView = true
                    } else {
                        await presentAlert("Mismatching Password")
                    }
                }
            } catch {
                await presentAlert(error.localizedDescription)
            }
        }
    }
    
    func presentAlert(_ message: String) async {
        await MainActor.run {
            alertMessage = message
            showAlert = true
            isLoading = false
            resetEmailAddress = ""
        }
    }
    
    enum Tab: String, CaseIterable {
        case login = "Login"
        case SignUp = "Sign Up"
    }
    
    var buttonStatus: Bool {
        if activeTab == .login {
            return emailAddress.isEmpty || password.isEmpty
        }
        
        return emailAddress.isEmpty || password.isEmpty || reEnterPassword.isEmpty
    }
}

fileprivate extension View {
    @ViewBuilder
    func showLoadingIndicator(_ status: Bool) -> some View {
        self
            .animation(.snappy) { content in
                content
                    .opacity(status ? 0 : 1)
            }
            .overlay {
                if status {
                    ZStack {
                        Capsule()
                            .fill(.bar)
                        
                        ProgressView()
                    }
                }
            }
    }
    
    @ViewBuilder
    func customTextField(_ icon: String? = nil, _ paddingTop: CGFloat = 0, _ paddingBottom: CGFloat = 0) -> some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.gray)
            }
            
            self
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .background(.bar, in: .rect(cornerRadius: 10))
        .padding(.horizontal, 15)
        .padding(.top, paddingTop)
        .padding(.bottom, paddingBottom)
        .listRowInsets(.init(top: 10, leading: 0, bottom: 0, trailing: 0))
        .listRowSeparator(.hidden)
    }
}

#Preview {
    ContentView()
}
