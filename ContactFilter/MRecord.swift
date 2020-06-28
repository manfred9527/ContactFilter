//
//  MRecord.swift
//  ContactFilter
//
//  Created by 齐风修 on 2020/6/23.
//  Copyright © 2020 齐风修. All rights reserved.
//

import UIKit

/// 通话记录
public protocol MRecord {
    
    /// 对方号码
    var number: String { get }

}
