//
//  Crypto.swift
//  App
//
//  Created by Jiří Zdvomka on 25/11/2019.
//

import Vapor
import Crypto

final class Crypto: Service {
    private let iv = "aqHthucyeqWJjU96"
    
    func encrypt(_ plaintext: String) throws -> String {
        let ciphertext = try AES256CBC.encrypt(plaintext, key: getKey(), iv: iv)
        return ciphertext.base64EncodedString()
    }
    
    func decrypt(_ ciphertext: String) throws -> String {
        guard let data = Data(base64Encoded: ciphertext) else {
            print("Unsuccessful decoding")
            throw Abort(.internalServerError)
        }
        
        let plainData = try AES256CBC.decrypt(data, key: getKey(), iv: iv)
        let plaintext = String(decoding: plainData, as: UTF8.self)
        return plaintext
    }
    
    private func getKey() -> String {
        // Key will be stored in a KeyVault service either provided by a cloud provider on own server
        // Now only mock the key request
        let responseTime = Int.random(in: 35...400)
        usleep(UInt32(responseTime * 1000))
        return "7WzXJqpkup0pLiMjW5rBpy1sfaqPyNNB"
    }
}

extension Crypto: ServiceType {
    static func makeService(for container: Container) throws -> Crypto {
        return Crypto()
    }
}
