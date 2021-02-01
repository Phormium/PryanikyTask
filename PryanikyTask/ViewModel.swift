//
//  ViewModel.swift
//  PryanikyTask
//
//  Created by Leonid Safronov on 31.01.2021.
//

import Foundation
import Alamofire
import Combine

final class ViewModel: ObservableObject {
    @Published var jsonUrl: String = "https://pryaniky.com/static/json/sample.json"
    @Published var data: ViewData = .empty
    @Published var status: Status = .epmty
    
    private var cancellable: Set<AnyCancellable> = []
        
    init() {
        $jsonUrl
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .sink(receiveValue: { [weak self] data in
                AF.request(data).responseJSON { response in
                    guard let json = response.data else {
                        if data.isEmpty {
                            self?.status = .epmty
                        } else {
                            self?.status = .fail
                        }
                        self?.data = .empty
                        return
                    }
                    do {
                        self?.data = try JSONDecoder().decode(ViewData.self, from: json)
                        self?.status = .success
                    } catch {
                        self?.status = .fail
                        self?.data = .empty
                        print(error)
                    }
                }
            })
            .store(in: &cancellable)
    }
}
