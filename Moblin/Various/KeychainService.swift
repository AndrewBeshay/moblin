import Foundation
import Security
import OSLog

/// A service class to handle keychain operations
final class KeychainService {
    private static let logger = Logger(subsystem: "com.moblin.keychain", category: "service")
    
    /// Saves data to the keychain
    /// - Parameters:
    ///   - key: The key to identify the data
    ///   - data: The data to save
    /// - Returns: Boolean indicating success
    static func save(key: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // First try to delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Then add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            logger.error("Failed to save item to keychain: \(status)")
            return false
        }
        return true
    }
    
    /// Retrieves data from the keychain
    /// - Parameter key: The key to identify the data
    /// - Returns: The data if found, nil otherwise
    static func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            logger.error("Failed to retrieve item from keychain: \(status)")
            return nil
        }
        
        return string
    }
    
    /// Deletes data from the keychain
    /// - Parameter key: The key to identify the data
    /// - Returns: Boolean indicating success
    static func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            logger.error("Failed to delete item from keychain: \(status)")
            return false
        }
        return true
    }
} 