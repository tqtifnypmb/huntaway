//
//  Progress.swift
//  Huntaway
//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 tqtifnypmb
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:

//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

public struct Progress: CustomStringConvertible {
    public enum WorkType {
        case Sending
        case Receiving
    }
    
    /// Type of current work.
    /// Either Sending or Receiving
    public let type: WorkType
    
    /// The total number of bytes to send or receive
    public let workload: Int64
    
    /// The total number of bytes sent or received so far
    public let done: Int64
    
    /// The number of bytes just sent or received
    public let did: Int64
    
    /// Current work progress.
    /// **progress = done / workload**
    public var progress: Float {
        guard self.workload > 0 else {
            return -1
        }
        return Float(self.done) / Float(self.workload)
    }
    
    public var description: String {
        switch self.workload {
        case 0 ..< 1024:
            return "\(done) / \(workload) bytes"
            
        case 1024 ..< 1024 * 1024:
            return String(format: "%.1f", arguments: [Float(self.done) / 1024.0]) + "/" + String(format: "%.1f", arguments: [Float(self.workload) / 1024.0]) + " Kb"
            
        case 1024 * 1024 ..< 1024 * 1024 * 1024:
            return String(format: "%.1f", arguments: [Float(self.done) / (1024.0 * 1024.0)]) + "/" + String(format: "%.1f", arguments: [Float(self.workload) / (1024.0 * 1024.0)]) + " Mb"
            
        default:
            return String(format: "%.2f", arguments: [Float(self.done) / (1024.0 * 1024.0 * 1024.0)]) + "/" + String(format: "%.2f", arguments: [Float(self.workload) / (1024.0 * 1024.0 * 1024.0)]) + " Gb"
        }
    }
    
    init(type: WorkType, did: Int64, done: Int64, workload: Int64) {
        self.type = type
        self.did = did
        self.done = done
        self.workload = workload
    }
}