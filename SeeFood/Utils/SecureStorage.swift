import Foundation
import Security

enum SecureStorage {
    private static let keychain = KeychainWrapper()
    
    static func getAPIKey() -> String? {
        return keychain.get(key: "GEMINI_API_KEY")
    }
    
    static func saveAPIKey(_ apiKey: String) {
        keychain.set(key: "GEMINI_API_KEY", value: apiKey)
    }
}

private class KeychainWrapper {
    func set(key: String, value: String) {
        if let data = value.data(using: .utf8) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecValueData as String: data
            ]
            
            SecItemDelete(query as CFDictionary)
            SecItemAdd(query as CFDictionary, nil)
        }
    }
    
    func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            if let data = dataTypeRef as? Data,
               let value = String(data: data, encoding: .utf8) {
                return value
            }
        }
        return nil
    }
} 