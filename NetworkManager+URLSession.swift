import Foundation

//MARK: - Enum
enum RestAllOperation {
    case get
    case post
    case put
    case delete
}

enum RestError {
    case url
    case taskError(error: Error)
    case noResponse
    case noData
    case responseStatusCode(code: Int)
    case invalidJSON
}

//MARK: - Model
class Item: Codable {
    let id: Int
    let descricao: String
    let imagem: Data
    
    init(_ id: Int, _ descricao: String, _ imagem: Data) {
        self.id = id
        self.descricao = descricao
        self.imagem = imagem
    }
}

//MARK: - NetworkManager
class NetworkManager {
    let baseHost = "localhost"
    let basePort = "8080"
    let baseProject = "nomeProjeto"
    let baseURL = "http://\(baseHost):\(basePort)/\(baseProject)/"
    let baseURLItem = "\(baseURL)item/"

    private static let configuration: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.httpAdditionalHeaders = ["Content-Type": "application/json; charset=utf-8;"]
        config.timeoutIntervalForRequest = 30.0
        config.httpMaximumConnectionsPerHost = 5
        return config
    }()
    
    static func getSession() -> URLSession {
        return URLSession(configuration: configuration)
    }
    
    static func getURL() -> String {
        return baseURL
    }
}

//MARK: - NetworkManagerItem
class NetworkManagerItem {
    class func get(item: Item, onComplete: @escaping (Bool) -> Void) {
        applyOperation(item: item, operation: .get, onComplete: onComplete)
    }
    class func post(item: Item, onComplete: @escaping (Bool) -> Void) {
        applyOperation(item: item, operation: .post, onComplete: onComplete)
    }
    class func put(item: Item, onComplete: @escaping (Bool) -> Void) {
        applyOperation(item: item, operation: .put, onComplete: onComplete)
    }
    class func delete(item: Item, onComplete: @escaping (Bool) -> Void) {
        applyOperation(item: item, operation: .delete, onComplete: onComplete)
    }
    
    private class func applyOperation (item: Item, operation: RestAllOperation, onComplete: @escaping (Bool) -> Void) {
        var urlString = ""
        switch operation {
        case .get:
            urlString = baseURLItem
        case .post:
            urlString = baseURLItem
        case .put:
            urlString = baseURLItemById + "/" + String(describing: item.id)
        case .delete:
            urlString = baseURLItemById + "/" + String(describing: item.id)
        }
        guard let url = URL(string: urlString) else {
            onComplete(false)
            return
        }
        var request = URLRequest(url: url)
        
        var httpMethod: String = ""
        switch operation {
        case .get:
            httpMethod = "GET"
        case .post:
            httpMethod = "POST"
        case .put:
            httpMethod = "PUT"
        case .delete:
            httpMethod = "DELETE"
        }
        request.httpMethod = httpMethod
        
        guard let json = try? JSONEncoder().encode(Item) else {
            onComplete(false)
            return
        }
        request.httpBody = json
        
        let dataTask = NetworkManager.getSession().dataTask(with: request) { (data, response, error) in
            if error == nil {
                guard let response = response as? HTTPURLResponse, response.statusCode == 200 , let _ = data else {
                    onComplete(false)
                    print("ERRO RESPONSE: \(String(describing: error))")
                    print("REQUISICAO: \(String(describing: request))")
                    return
                }
                onComplete(true)
            } else {
                onComplete(false)
                print("ERRO SESSION: \(String(describing: error))")
            }
        }
        dataTask.resume()
        print("REQUISICAO: \(String(describing: request))")
    }
    
    class func getItem(onComplete: @escaping ([Item]) -> Void, onError: @escaping (RestError) -> Void) {
        guard let url = URL(string: baseURLItem) else {
            onError(.url)
            return
        }
        let dataTask = NetworkManager.getSession().dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
            if error == nil {
                guard let response = response as? HTTPURLResponse  else {
                    onError(.noResponse)
                    return
                }
                if response.statusCode == 200 {
                    guard let data = data else {return}
                    do {
                        let item = try JSONDecoder().decode([Item].self, from: data)
                        onComplete(item)
                    } catch {
                        print(error.localizedDescription)
                        onError(.invalidJSON)
                    }
                } else {
                    print(response.url!)
                    print("Algum status invalido pelo servidor!!! \(response.statusCode)")
                    onError(.responseStatusCode(code: response.statusCode))
                }
            } else {
                print(error!.localizedDescription)
                onError(.taskError(error: error!))
            }
        }
        dataTask.resume()
    }
}

//MARK: - FetchData
import UIKit
class ViewController: UIViewController {
    var item: [Item] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchItem()
    }
    
    func fetchItem() {
        NetworkManagerItem.getItem(onComplete: { (item) in
            DispatchQueue.main.async {
                self.item = item
            }
        }) { (error) in
            print("Erro ao carregar os dados: \(error)")
        }
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return item.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = item[indexPath.row].descricao
        return cell
    }
}
