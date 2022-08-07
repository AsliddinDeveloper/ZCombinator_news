//
//  AuthRepository.swift
//  ZCombinator
//
//  Created by Jiaqi Feng on 8/5/22.
//

import Foundation
import Alamofire
import Security

class AuthRepository {
    static let shared: AuthRepository = AuthRepository()
    
    private let server: String = "news.ycombinator.com"
    private let baseUrl: String = "https://news.ycombinator.com"
    private let query: CFDictionary = [
        kSecClass: kSecClassInternetPassword,
        kSecAttrServer: Constants.server,
        kSecReturnAttributes: true,
        kSecReturnData: true
    ] as CFDictionary
    
    var loggedIn: Bool {
        var result: AnyObject?
        _ = SecItemCopyMatching(query, &result)
        
        guard let dic = result as? NSDictionary else {
            return false
        }
        
        let username = dic[kSecAttrAccount] as! String?
        
        return username.isNotNullOrEmpty
    }
    
    var username: String? {
        var result: AnyObject?
        _ = SecItemCopyMatching(query, &result)
        
        guard let dic = result as? NSDictionary else {
            return nil
        }
        
        let username = dic[kSecAttrAccount] as! String?
        
        return username
    }
    
    var password: String? {
        var result: AnyObject?
        _ = SecItemCopyMatching(query, &result)
        
        guard let dic = result as? NSDictionary else {
            return nil
        }
        
        let passwordData = dic[kSecValueData] as! Data
        let password = String(data: passwordData, encoding: .utf8)
        
        return password
    }
    
    // MARK: - Authentication
    
    func logIn(username: String, password: String) async -> Bool {
        let parameters: [String: String] = [
            "acct": username,
            "pw": password
        ]
        let response = await AF.request("\(self.baseUrl)/login", method: .post, parameters: parameters, encoder: .urlEncodedForm).serializingString().response.response
        
        guard let url = response?.url else {
            return false
        }
        
        let cookies = HTTPCookieStorage.shared.cookies(for: url)
        let loggedIn = cookies.isNotNullOrEmpty
        
        if loggedIn {
            let keychainItem = [
                kSecValueData: password.data(using: .utf8)!,
                kSecAttrAccount: username,
                kSecAttrServer: server,
                kSecClass: kSecClassInternetPassword,
                kSecReturnData: true,
                kSecReturnAttributes: true
            ] as CFDictionary
            
            var ref: AnyObject?
            
            _ = SecItemAdd(keychainItem, &ref)
        }
        
        return loggedIn
    }
    
    func logOut() -> Bool {
        guard let url = URL(string: baseUrl) else {
            return false
        }
        
        guard let cookies = HTTPCookieStorage.shared.cookies(for: url) else {
            return false
        }
        
        for cookie in cookies {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
        
        let query = [
            kSecClass: kSecClassInternetPassword,
            kSecAttrServer: server,
            kSecReturnAttributes: true,
            kSecReturnData: true
        ] as CFDictionary
        
        
        let delStatus = SecItemDelete(query)
        
        if delStatus != 0 {
            return false
        }
        
        return true
    }
    
    // MARK: - Actions that require authentication
    
    func flag(_ id: Int) async -> Bool {
        guard let username = self.username, let password = self.password else {
            return false
        }
        
        let parameters: [String: String] = [
            "acct": username,
            "pw": password,
            "id": String(id),
        ]
        
        let response = await AF.request("\(self.baseUrl)/flag", method: .post, parameters: parameters, encoder: .urlEncodedForm).serializingString().response.response
        
        return true
    }
    
    func upvote(_ id: Int) async -> Bool {
        guard let username = self.username, let password = self.password else {
            return false
        }
        
        let parameters: [String: String] = [
            "acct": username,
            "pw": password,
            "id": String(id),
            "how": "up",
        ]
        
        let response = await AF.request("\(self.baseUrl)/vote", method: .post, parameters: parameters, encoder: .urlEncodedForm).serializingString().response.response
        
        return true
    }
    
    func fav(_ id: Int) async -> Bool {
        guard let username = self.username, let password = self.password else {
            return false
        }
        
        let parameters: [String: String] = [
            "acct": username,
            "pw": password,
            "id": String(id),
        ]
        
        let response = await AF.request("\(self.baseUrl)/fave", method: .post, parameters: parameters, encoder: .urlEncodedForm).serializingString().response.response
        
        return true
    }
    
    func reply(to id: Int, with text: String) async -> Bool {
        guard let username = self.username, let password = self.password else {
            return false
        }
        
        let parameters: [String: String] = [
            "acct": username,
            "pw": password,
            "parent": String(id),
            "text": text,
        ]
        
        let response = await AF.request("\(self.baseUrl)/comment", method: .post, parameters: parameters, encoder: .urlEncodedForm).serializingString().response.response
        
        return true
    }
}
