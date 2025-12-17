import Foundation
import Supabase
import Combine

/// Dependency injection container for managing app dependencies
@MainActor
class DIContainer: ObservableObject {
    // MARK: - Core Services

    let objectWillChange = PassthroughSubject<Void, Never>()
    
    lazy var supabaseClient: SupabaseClient = {
        SupabaseClient(
            supabaseURL: Environment.supabaseURL,
            supabaseKey: Environment.supabaseAnonKey
        )
    }()

    lazy var tokenManager: TokenManager = {
        TokenManager()
    }()

    lazy var authService: AuthenticationService = {
        AuthenticationService(
            supabase: supabaseClient,
            tokenManager: tokenManager
        )
    }()

    lazy var apiClient: APIClient = {
        APIClientImpl(
            baseURL: Environment.backendURL,
            authService: authService
        )
    }()

    // MARK: - Repositories

    lazy var userRepository: UserRepository = {
        UserRepositoryImpl(apiClient: apiClient)
    }()

    lazy var contactRepository: ContactRepository = {
        ContactRepositoryImpl(apiClient: apiClient)
    }()

    lazy var timelineRepository: TimelineRepository = {
        TimelineRepositoryImpl(apiClient: apiClient)
    }()

    // MARK: - User Use Cases

    func makeGetUsersUseCase() -> GetUsersUseCase {
        GetUsersUseCase(repository: userRepository)
    }

    func makeGetUserByIdUseCase() -> GetUserByIdUseCase {
        GetUserByIdUseCase(repository: userRepository)
    }

    func makeCreateUserUseCase() -> CreateUserUseCase {
        CreateUserUseCase(repository: userRepository)
    }

    func makeUpdateUserUseCase() -> UpdateUserUseCase {
        UpdateUserUseCase(repository: userRepository)
    }

    func makeDeleteUserUseCase() -> DeleteUserUseCase {
        DeleteUserUseCase(repository: userRepository)
    }

    // MARK: - Contact Use Cases

    func makeGetContactsUseCase() -> GetContactsUseCase {
        GetContactsUseCase(repository: contactRepository)
    }

    func makeGetContactByIdUseCase() -> GetContactByIdUseCase {
        GetContactByIdUseCase(repository: contactRepository)
    }

    func makeCreateContactUseCase() -> CreateContactUseCase {
        CreateContactUseCase(repository: contactRepository)
    }

    func makeUpdateContactUseCase() -> UpdateContactUseCase {
        UpdateContactUseCase(repository: contactRepository)
    }

    func makeDeleteContactUseCase() -> DeleteContactUseCase {
        DeleteContactUseCase(repository: contactRepository)
    }

    func makeSearchContactsUseCase() -> SearchContactsUseCase {
        SearchContactsUseCase(repository: contactRepository)
    }

    // MARK: - Timeline Use Cases

    func makeGetTimelineUseCase() -> GetTimelineUseCase {
        GetTimelineUseCase(repository: timelineRepository)
    }

    // MARK: - Dashboard

    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(userRepository: userRepository)
    }

    // MARK: - Twilio Services

    lazy var callManager: CallManager = {
        let manager = CallManager()
        manager.twilioService = twilioService
        return manager
    }()

    lazy var twilioService: TwilioService = {
        TwilioService(authService: authService)
    }()

    lazy var voipPushService: VoIPPushService = {
        let service = VoIPPushService()
        service.callManager = callManager
        service.twilioService = twilioService
        return service
    }()

    lazy var smsService: SMSServiceProtocol = {
        SMSService(authService: authService)
    }()

    // MARK: - Call ViewModels

    func makeCallViewModel() -> CallViewModel {
        CallViewModel(
            twilioService: twilioService,
            callManager: callManager,
            authService: authService
        )
    }

    // MARK: - Messaging ViewModels

    func makeConversationViewModel() -> ConversationViewModel {
        ConversationViewModel(smsService: smsService)
    }
}
