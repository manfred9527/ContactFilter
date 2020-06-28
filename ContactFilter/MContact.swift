//
//  MContact.swift
//  ContactFilter
//
//  Created by 齐风修 on 2020/6/23.
//  Copyright © 2020 齐风修. All rights reserved.
//

import UIKit

/// 联系人
public protocol MContact {
    
    /// 联系人姓名：张三
    var name: String { get }
    
    /// 联系人姓名拼音：zhangsan
    var pinyinName: String { get }
    
    /// 联系人姓名拼音dic: [("张", "zhang"), ("三", "san")]
    var pinyinDic: [(String, String)] { get }
    
    /// 匹配结果缓存，高亮信息
    var matchResult: [String: MContactMatchResult] { get set }
    
    /// 上次使用时间，用于结果排序，优先显示最近联系过的人
    var lastContactTime: TimeInterval { get }
    
    /// 联系人的号码s
    var phones: [String] { get }
}
