
import Foundation
import SwiftUI

protocol MoviesVMInput {
    func didSearch(text searchText: String) async
    func didCancelSearch() async
    func didLoadNextPage() async
}

protocol MoviesVMOutput {
    var movies: [Movie] { get }
    var searchText: String { get set }
    var loadingState: ViewModelLoadingState { get }
    var showAlert: Bool { get set }
    var errorMessage: String? { get set }
}

protocol MoviesSearchVM: MoviesVMInput & MoviesVMOutput & ObservableObject {
}


final class DefaultMoviesVM: MoviesSearchVM {

    // MARK: - Exposed properties
    @Published var loadingState: ViewModelLoadingState = .none
    @Published var showAlert: Bool = false

    var searchText: String = ""
    var errorMessage: String?
    var movies: [Movie] {
        pages.movies
    }
    
    // MARK: - Private properties
    private let searchMoviesUseCase: SearchMoviesUseCase
    private var pages: [MoviesPage] = []
    private let loadNextPageHelper: LoadNextPageHelper
    
    
    // MARK: - Exposed methods
    init(searchMoviesUseCase: SearchMoviesUseCase) {
        self.searchMoviesUseCase = searchMoviesUseCase
        self.loadNextPageHelper = LoadNextPageHelper(currentPage: 0, totalPageCount: 1)
    }
    
    func didSearch(text searchText: String) async {
        await resetSearch(forText: searchText)
    }
    
    @MainActor func didCancelSearch() async {
        await resetSearch(forText: "")
        loadingState = .none
    }
    
    @MainActor func didLoadNextPage() async {
        guard loadNextPageHelper.hasNextPage,
                loadingState == .none
        else { return }
        
        await searchMovies(forText: searchText, 
                           loadingState: .nextPage)
    }
    
    
    // MARK: - Private methods
    @MainActor private func resetSearch(forText searchText: String) async {
        pages.removeAll()
        loadNextPageHelper.update(currentPage: 0, totalPageCount: 1)
        
        guard !searchText.isEmpty else { return }

        await searchMovies(forText: searchText, 
                           loadingState: .firstPage)
    }
    
    @MainActor private func searchMovies(
        forText searchText: String,
        loadingState: ViewModelLoadingState
    ) async {
        self.searchText = searchText
        self.loadingState = loadingState

        let requestValue = SearchMoviesUseCaseRequestValue(
            searchText: searchText,
            page: loadNextPageHelper.nextPage
        )

        do {
            let moviesPage = try await searchMoviesUseCase.execute(requestValue: requestValue)
                if (requestValue.searchText == searchText) {
                    appendPage(moviesPage)
                }
        } catch {
            handle(error: error)
        }
    }

    private func appendPage(_ moviesPage: MoviesPage) {
        loadNextPageHelper.update(
            currentPage: moviesPage.page,
            totalPageCount: moviesPage.totalPages
        )
        
        pages = pages
            .filter { $0.page != moviesPage.page }
            + [moviesPage]
        
        if pages.movies.count > 0 {
            loadingState = .none
        } else {
            loadingState = .emptyPage
        }
    }

    private func handle(error: Error) {
        errorMessage = "failed_to_load_movies"
        showAlert = true
        loadingState = .none
    }
}


// MARK: - Private extensions
private extension Array where Element == MoviesPage {
    var movies: [Movie] { flatMap { $0.movies } }
}
