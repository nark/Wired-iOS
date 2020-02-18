//
//  Connection.swift
//  Wired 3
//
//  Created by Rafael Warnault on 18/07/2019.
//  Copyright © 2019 Read-Write. All rights reserved.
//

import Foundation
import Dispatch

public protocol ConnectionDelegate {
    func connectionDidConnect(connection: Connection)
    func connectionDidFailToConnect(connection: Connection, error: Error)
    func connectionDisconnected(connection: Connection, error: Error?)
    
    func connectionDidReceiveMessage(connection: Connection, message: P7Message)
}

public class Connection: NSObject {
    public var spec:        P7Spec
    public var url:         Url!
    public var socket:      P7Socket!
    public var delegates:   [ConnectionDelegate] = []
    
    public var userID: UInt32!
    public var nick: String     = "Swift Wired"
    public var status: String   = ""
    public var icon: String     = Wired.defaultUserIcon
    
    public var serverInfo: ServerInfo!
    
    public init(withSpec spec: P7Spec, delegate: ConnectionDelegate? = nil) {
        self.spec = spec
        
        if let d = delegate {
            self.delegates.append(d)
        }
    }
    
    
    public func connect(withUrl url: Url) -> Bool {
        self.url = url
        
        self.socket = P7Socket(hostname: self.url.hostname, port: self.url.port, spec: self.spec)
        
        self.socket.username = url.login
        self.socket.password = url.password
        
        self.socket.cipherType  = .RSA_AES_256
        self.socket.compression = .NONE
        
        if !self.socket.connect() {
            return false
        }
        
        for d in self.delegates {
            DispatchQueue.main.async {
                d.connectionDidConnect(connection: self)
            }
        }
        
        if !self.clientInfo() {
            return false
        }
        
        if !self.setUser() {
            return false
        }
        
        if !self.login() {
            return false
        }
        
        self.listen()
        
        return true

    }
    
    
    public func disconnect() {
        self.socket.disconnect()
    }
    
    
    
    public func joinChat(chatID: Int) -> Bool  {
        let message = P7Message(withName: "wired.chat.join_chat", spec: self.spec)
        
        message.addParameter(field: "wired.chat.id", value: UInt32(chatID))
        
        if !self.socket.write(message) {
            return false
        }
    
        return true
    }
    
    
    private func listen() {
        DispatchQueue.global().async {
            while (true) {
                Logger.debug("listen try to read")
                if let message = self.socket.read() {
                    self.handleMessage(message)
                }
            }
        }
    }
    
    
    
    private func handleMessage(_ message:P7Message) {
        switch message.name {
        case "wired.send_ping":
            self.pingReply()
            
        default:
            for d in self.delegates {
                DispatchQueue.main.async {
                    d.connectionDidReceiveMessage(connection: self, message: message)
                }
            }
        }
    }
    
    
    
    private func pingReply() {
        _ = self.socket.write(P7Message(withName: "wired.ping", spec: self.spec))
    }

    
    
    private func setNick() -> Bool {
        let message = P7Message(withName: "wired.user.set_nick", spec: self.spec)
        
        message.addParameter(field: "wired.user.nick", value: self.nick)
        
        if !self.socket.write(message) {
            return false
        }
        
        if self.socket.read() == nil {
            return false
        }
        
        return true
    }
    
    
    private func setStatus() -> Bool {
        let message = P7Message(withName: "wired.user.set_status", spec: self.spec)
        
        message.addParameter(field: "wired.user.status", value: self.status)
        
        if !self.socket.write(message) {
            return false
        }
        
        if self.socket.read() == nil {
            return false
        }
        
        return true
    }
    
    
    private func setIcon() -> Bool {
        let message = P7Message(withName: "wired.user.set_icon", spec: self.spec)
        
        message.addParameter(field: "wired.user.icon", value: Data(base64Encoded: Wired.defaultUserIcon, options: .ignoreUnknownCharacters))
        
        if !self.socket.write(message) {
            return false
        }
        
        if self.socket.read() == nil {
            return false
        }
        
        return true
    }
    
    
    
    private func setUser() -> Bool {
        if !self.setNick() {
            return false
        }
        
        if !self.setStatus() {
            return false
        }
        
        if !self.setIcon() {
            return false
        }
        
        return true
    }
    
    
    private func login() -> Bool  {
        let message = P7Message(withName: "wired.send_login", spec: self.spec)
        
        message.addParameter(field: "wired.user.login", value: self.url!.login)
        
        var password = "".sha1()
        
        if self.url?.password != nil && self.url?.password != "" {
            password = self.url!.password.sha1()
        }
                
        message.addParameter(field: "wired.user.password", value: password)
        
        _ = self.socket.write(message)
        
        //sleep(1)
        
        guard let response = self.socket.read() else {
            return false
        }
        
        if let uid = response.uint32(forField: "wired.user.id") {
            self.userID = uid
        }
                
        return true
    }
    
    
    private func clientInfo() -> Bool {
        let message = P7Message(withName: "wired.client_info", spec: self.spec)
        message.addParameter(field: "wired.info.application.name", value: "Wired Swift")
        message.addParameter(field: "wired.info.application.version", value: "1.0")
        message.addParameter(field: "wired.info.application.build", value: "1")
        message.addParameter(field: "wired.info.os.name", value: "macOS")
        message.addParameter(field: "wired.info.os.version", value: "10.14")
        message.addParameter(field: "wired.info.arch", value: "x86_64")
        message.addParameter(field: "wired.info.supports_rsrc", value: false)
        
        _ = self.socket.write(message)
        
        guard let response = self.socket.read() else {
            return false
        }
                
        self.serverInfo = ServerInfo(message: response)
        
        return true
    }
}