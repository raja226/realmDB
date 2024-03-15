//
//  ViewController.swift
//  RealmSample
//
//  Created by Administrator on 01/03/24.
//
import UIKit
import RealmSwift

struct Constants {
    static let allItems = "all_items"
    static let myItems = "todo"
}

class Contact: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var name: String
    @Persisted var phonenumber: String
}

// Define your Todo model
class TodoTask: Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var name: String
    @Persisted var owner: String
    @Persisted var status: String
}

class Item: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var isComplete = false
    @Persisted var summary: String
    @Persisted var owner_id: String
}

class AuthManager {
    static let shared = AuthManager()
    var currentUser: User? // Store the current user object
    
    //application-0-skqlq
    //application-0-anzuc
    private let app = App(id: "application-0-anzuc")
    func login(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        app.login(credentials: Credentials.emailPassword(email: email, password: password)) { result in
            switch result {
            case .success(let user):
                print("Successfully logged in as user: \(user)")
                self.currentUser = user
                completion(.success(user))
            case .failure(let error):
                print("Failed to log in: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    /// Registers a new user with the email/password authentication provider.
    func signUp(email: String, password: String) async throws {
        do {
            try await app.emailPasswordAuth.registerUser(email: email, password: password)
            print("Successfully registered user")
            
        } catch {
            print("Failed to register user: \(error.localizedDescription)")
            throw error
        }
    }
    
    
    
    // Add more authentication methods as needed
}

class ViewController: UIViewController {
    // Create an instance of AuthManager
    @IBOutlet var myTableview: UITableView!
    var realmObject = try! Realm()
    let authManager = AuthManager.shared
    var notificationToken: NotificationToken?
    var currentUser: User?
    var realmPeopleResult: Results<Item>!
    var realmContactResult: Results<Contact>!
    
    @IBOutlet var atlasTableview: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        retriveLocalDBRealm()
    }
    
    
    
    private func setupTableView() {
        // Register cell class if needed
        myTableview.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        // Set delegates
        myTableview.delegate = self
        myTableview.dataSource = self
        
        
        atlasTableview.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        // Set delegates
        atlasTableview.delegate = self
        atlasTableview.dataSource = self
        
        
    }
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        authManager.login(email: "gogulayadhav@gmail.com", password: "Rajasekhar@226") { result in
            switch result {
            case .success(let user):
                print("Logged in as user: \(user)")
                self.currentUser = user
                
                self.createAtlasDatabase(currentuser: user)
                
            case .failure(let error):
                print("Failed to log in: \(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func contactButton(_ sender: UIButton) {
        insertDatatoLocalDbRealm(name: "Rajasekhar", mobileNo: "8247246163", id: "0")
        retriveLocalDBRealm()
        DispatchQueue.main.async {
            self.myTableview.reloadData()
        }
    }
    
    func insertDatatoLocalDbRealm(name:String,mobileNo:String,id:String)
    {
        let person = Contact()
        person.name = name
        person.phonenumber = mobileNo
        try! realmObject.write {
            realmObject.add(person)
        }
        realmContactResult = realmObject.objects(Contact.self).sorted(byKeyPath: "name", ascending: true)
        debugPrint(realmContactResult)
        
        notificationToken = realmContactResult.observe { [weak self] changes in
            guard let tableView = self?.myTableview else { return }
            switch changes {
            case .initial:
                // Results are now populated and can be accessed
                DispatchQueue.main.async {
                    self?.myTableview.reloadData()
                }
            case .update(_, let deletions, let insertions, let modifications):
                // Handle updates (deletions, insertions, modifications)
                self?.myTableview.beginUpdates()
                self?.myTableview.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0) }), with: .automatic)
                self?.myTableview.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }), with: .automatic)
                self?.myTableview.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }), with: .automatic)
                self?.myTableview.endUpdates()
            case .error(let error):
                // Handle error
                fatalError("Failed to observe Realm changes: \(error)")
            }
        }
    }
    func retriveLocalDBRealm()
    {
        let realmConfiguration = Realm.Configuration.defaultConfiguration
        if let realmFileURL = realmConfiguration.fileURL {
            print("Local DB path: \(realmFileURL.path)")
            let realm = try! Realm(configuration: realmConfiguration)
            self.realmContactResult = realm.objects(Contact.self)
            for person in self.realmContactResult {
                print("Name: \(person.name), Phone Number: \(person.phonenumber)")
            }
            
            DispatchQueue.main.async {
                self.myTableview.reloadData()
            }
            
        } else {
            print("Failed to retrieve Realm file URL")
        }
        
    }
    
    
    @IBAction func logoutButtonTapped(_ sender: UIButton) {
        Task{
            await logout(user: currentUser!)
        }
    }
    
    func logout(user: User) async {
        do {
            try await user.logOut()
            print("Successfully logged user out")
        } catch {
            print("Failed to log user out: \(error.localizedDescription)")
            // Handle error here, such as displaying an alert
        }
    }
    
    @MainActor
    func openSyncedRealm(user: User) async {
        do {
            var config = user.flexibleSyncConfiguration()
            config.objectTypes = [Item.self]
            let realm = try await Realm(configuration: config, downloadBeforeOpen: .always)
            let subscriptions = realm.subscriptions
            try await subscriptions.update {
                subscriptions.remove(named: Constants.allItems)
            }
            if subscriptions.first(named: Constants.allItems) == nil {
                subscriptions.append(QuerySubscription<Item>(name: Constants.allItems))
            }
            
        } catch {
            print("Error opening realm: \(error.localizedDescription)")
        }
    }
    
    
    // MARK: - Atlas Syn Apps
    // Function to create a new database
    func createAtlasDatabase(currentuser: User) {
        do {
            // Create Realm configuration with Flex Sync enabled
            let app = App(id: "application-0-anzuc")
            let currentUser = app.currentUser
            let config = currentUser?.flexibleSyncConfiguration(cancelAsyncOpenOnNonFatalErrors: false) { subscriptions in
                // Customize subscriptions here if needed
                if subscriptions.first(named: Constants.myItems) == nil {
                    subscriptions.append(QuerySubscription<Item>(name: Constants.myItems) { $0.owner_id == currentuser.id })
                }
            } ?? Realm.Configuration.defaultConfiguration
            
            // Open the Realm instance
            let realm = try Realm(configuration: config)
            
            print("Realm database created successfully")
            print("Atlas Path:\(String(describing: config.fileURL?.path))")
            
            self.addItemToAtlasDatabase(realm: realm, currentUser: currentuser)

        } catch {
            print("Failed to create Realm database: \(error.localizedDescription)")
        }
    }
    
    // Function to add an item to the database
    
    func addItemToAtlasDatabase(realm: Realm, currentUser: User) {
            do {
                try realm.write {
                    let item = Item()
                    item.summary = "Govindh"
                    item.owner_id = currentUser.id
                    realm.add(item)
                }
                print("Item added to Realm successfully")
                
                self.realmPeopleResult = realm.objects(Item.self)
                for person in self.realmPeopleResult {
                    print("Name: \(person.summary), Phone Number: \(person.id)")
                }
                debugPrint(self.realmPeopleResult)
                
               // self.realmPeopleResult = realmPeopleResult
                DispatchQueue.main.async {
                   //self.atlasTableview.reloadData()
                }
            } catch {
                print("Failed to add item to Realm: \(error.localizedDescription)")
            }
        
    }


    
}



// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(tableView == myTableview)
        {
            return realmContactResult?.count ?? 0
            
        }else
        {
            return realmPeopleResult?.count ?? 0
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if(tableView == myTableview)
        {
            let person = realmContactResult[indexPath.row]
            cell.textLabel?.text = "\(person.name) and Mobile: \(person.phonenumber) id:\(person._id)"
            
        }
        else{
            let person = realmPeopleResult[indexPath.row]
            
            cell.textLabel?.text = "\(person.summary) and  id:\(person._id)"
            
        }
        //cell.textLabel?.text = "\(person.name) - \(person.phonenumber)"
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Handle row selection
        print("Selected item: \(indexPath.row)")
    }
}

