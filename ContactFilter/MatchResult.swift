//
//  MatchResult.swift
//  ContactFilter
//
//  Created by 齐风修 on 2020/6/23.
//  Copyright © 2020 齐风修. All rights reserved.
//

/// 开口码匹配结果
public struct MContactMatchResult {
    /// 多彩名字
    public var nameAttribute = [(String, Bool)]()
    /// 多彩手机号
    public var phoneAttribute = [(String, Bool)]()
    
    public init(nameAttribute: [(String, Bool)], phoneAttribute: [(String, Bool)]) {
        self.nameAttribute = nameAttribute
        self.phoneAttribute = phoneAttribute
    }
}
