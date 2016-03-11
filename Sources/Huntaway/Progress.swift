//
//  Progress.swift
//  XcodeProject
//
//  Created by Tqtifnypmb on 3/11/16.
//  Copyright © 2016 Tqtifnypmb. All rights reserved.
//

import Foundation

public struct Progress {
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
    public var progress: Double {
        guard self.workload > 0 else {
            return -1
        }
        return Double(self.done) / Double(self.workload)
    }
    
    init(type: WorkType, did: Int64, done: Int64, workload: Int64) {
        self.type = type
        self.did = did
        self.done = done
        self.workload = workload
    }
}