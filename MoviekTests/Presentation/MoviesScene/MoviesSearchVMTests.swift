
import Foundation
import XCTest
@testable import Moviek

class MoviesSearchVMTests: XCTestCase {
    
    var useCase: SearchMoviesUseCaseMock!
    var sut: DefaultMoviesVM!
    
    private enum MoviesSearchVMError: Error {
        case testError
    }
    
    let moviesPages: [MoviesPage] = {
        let page1 = MoviesPage(page: 1, totalPages: 2, movies: [
            Movie.stub(), Movie.stub()
        ])
        
        let page2 = MoviesPage(page: 2, totalPages: 2, movies: [
            Movie.stub()
        ])
        
        return [page1, page2]
    }()
    
    override func setUp() {
        super.setUp()
        
        useCase = SearchMoviesUseCaseMock()
        sut = DefaultMoviesVM(searchMoviesUseCase: useCase)
    }

    override func tearDown() {
        super.tearDown()
        
        useCase = nil
        sut = nil
    }
    
    func testDidSearch_whenSearchTextDoesNotMatchToMovies_thenItemsEmpty() async {
        // Given
        useCase._execute = { requestValue in
            return MoviesPage(page: 1, totalPages: 2, movies: [])
        }
        
        // When
        await sut.didSearch(text: "q")
        
        // Then
        XCTAssertTrue(sut.movies.isEmpty, "Items property of DefaultMoviesVM should be empty as the search text doesn't match any movies.")
    }
    
    func testDidSearch_whenSearchTextMatchesToMovies_thenContainsItems() async {
        // Given
        useCase._execute = { requestValue in
            return self.moviesPages[0]
        }

        let expectedItems = moviesPages[0]
            .movies
        
        // When
        await sut.didSearch(text: "q")
        
        // Then
        XCTAssertEqual(sut.movies, expectedItems, "Items property of DefaultMoviesVM should contain objects as the search text matches to movies.")
    }
    
    func testDidLoadNextPage_whenSearchTextMatchesToMovies_thenContainsItems() async {
        // Given
        useCase._execute = { requestValue in
            return self.moviesPages[0]
        }
        
        await sut.didSearch(text: "q")
        
        useCase._execute = { requestValue in
            return self.moviesPages[1]
        }
        
        let expectedItems = moviesPages
            .flatMap { $0.movies }
        
        // When
        await sut.didLoadNextPage()
        
        // Then
        XCTAssertEqual(sut.movies, expectedItems, "Items property of DefaultMoviesVM should contain objects as the search text matches to movies on the next page.")
    }
}


extension MoviesSearchVMTests {

    class SearchMoviesUseCaseMock: SearchMoviesUseCase {

        lazy var _execute: (SearchMoviesUseCaseRequestValue) async throws -> MoviesPage = { requestValue in
            XCTFail("_execute closure is not implemented.")
            return MoviesPage(page: 0, totalPages: 0, movies: [])
        }

        func execute(requestValue: SearchMoviesUseCaseRequestValue) async throws -> MoviesPage {
            return try await _execute(requestValue)
        }
    }
}
