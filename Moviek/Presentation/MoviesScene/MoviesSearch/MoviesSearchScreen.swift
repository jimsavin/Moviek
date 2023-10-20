
import SwiftUI

struct MoviesSearchScreen<VM: MoviesSearchVM>: View {
    
    // MARK: - Private properties
    @ObservedObject private var viewModel: VM
    @ObservedObject private var keyboardManager = KeyboardHelper()
    @State private var showAlert = false
    @State private var searchText: String = ""
    private let sceneBuilder: MoviesSceneBuilder
    
    
    // MARK: - Exposed methods
    init(
        viewModel: VM,
        moviesSceneBuilder: MoviesSceneBuilder = MoviesSceneBuilder()
    ) {
        self.viewModel = viewModel
        self.sceneBuilder = moviesSceneBuilder
    }
    
    var body: some View {
        var vm = viewModel // Capture a mutable reference
        
        NavigationView {
            VStack {
                if keyboardManager.isKeyboardVisible &&
                    searchText.isEmpty &&
                    viewModel.loadingState == .none {

                    sceneBuilder.makeMoviesQueriesView { selectedQueryVM in
                        searchText = selectedQueryVM.query
                        Task {
                            await viewModel.didSearch(text: searchText)
                        }
                        hideKeyboard()
                    }
                } else {
                    MoviesSearchResultView(
                        viewModel: viewModel,
                        sceneBuilder: sceneBuilder
                    )
                }
            }
            .navigationTitle("Find your movie")
            .searchable(text: $searchText, prompt: "Search...")
            .disableAutocorrection(true)
            .onChange(of: viewModel.showAlert) { newValue, _ in
                if newValue {
                    showAlert = true
                }
            }
            .onSubmit(of: .search) {
                Task {
                    await viewModel.didSearch(text: searchText)
                }
            }
            .onChange(of: searchText) { oldValue, newValue in
                if oldValue.isEmpty == false && newValue.isEmpty {
                    Task {
                        await viewModel.didCancelSearch()
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"),
                      message: Text(viewModel.errorMessage),
                      dismissButton: .default(Text("OK")) {
                        vm.showAlert = false
                        showAlert = false
                      })
            }
        }
    }
}
