//
//  MContactFilter.swift
//  ContactFilter
//
//  Created by 齐风修 on 2020/6/23.
//  Copyright © 2020 齐风修. All rights reserved.
//

private let contactFilter = MContactFilter()

public class MContactFilter {
    
    public static var shared: MContactFilter {
        return contactFilter
    }
        
    /// 计算开口码使用
    let numberDic: [String: [Character]] = [
        "0": [Character("0")],
        "1": [Character("1")],
        "2": [Character("a"), Character("b"), Character("c"), Character("2")],
        "3": [Character("d"), Character("e"), Character("f"), Character("3")],
        "4": [Character("g"), Character("h"), Character("i"), Character("4")],
        "5": [Character("j"), Character("k"), Character("l"), Character("5")],
        "6": [Character("m"), Character("n"), Character("o"), Character("6")],
        "7": [Character("p"), Character("q"), Character("r"), Character("s"), Character("7")],
        "8": [Character("t"), Character("u"), Character("v"), Character("8")],
        "9": [Character("w"), Character("x"), Character("y"), Character("z"), Character("9")]]
    
    /// 通讯录侧边栏sectionIndex
    let chars = ["a", "b", "c", "d", "e", "f", "g",
                 "h", "i", "j", "k", "l", "m", "n",
                 "o", "p", "q", "r", "s", "t",
                 "u", "v", "w", "x", "y", "z", "#"]
    
    /// 将通讯录进行分组，便于展示
    ///
    /// - Parameter contactList: 通讯录列表
    /// - Returns: header列表+通讯录分组结果
    public func groupContacts(contactList: [MContact]) -> ([String], [String: [MContact]]) {
        
        var contactsDic = [String: [MContact]]()
        var headers = [String]()
        
        var contacts = contactList
        contacts.sort { (lhs, rhs) -> Bool in
            return lhs.pinyinName.compare(rhs.pinyinName) == .orderedAscending
        }
        for one in contacts {
            var first = ""
            if let firstChar = one.pinyinName.first {
                first = String(firstChar)
                if !chars.contains(first) {
                    first = "#"
                }
            } else {
                first = "#"
            }
            if var list = contactsDic[first] {
                list.append(one)
                contactsDic[first] = list
            } else {
                contactsDic[first] = [one]
                headers.append(first)
            }
        }
        if let first = headers.first, first == "#" {
            headers.append(headers.removeFirst())
        }
        return (headers, contactsDic)
    }
    
    
    /// 匹配开口码
    ///
    /// - Parameters:
    ///   - contacts: 通讯录
    ///   - numberString: 数字字符串
    /// - Returns: 结果
    public func match(contacts: [MContact], records: [MRecord], numberString: String, matchKey: String) -> ([MContact], [MRecord]) {
        
        /// 缓存没有匹配上名字，需要匹配号码的联系人
        var phoneContacts = [MContact]()
        /// 开口码代表的字母数组
        var targetChars = [[Character]]()
        
        for one in numberString {
            if let chars = self.numberDic[String(one)] {
                targetChars.append(chars)
            }
        }
        
        var rName = [MContact]()
        var rNumber = [MContact]()

        // 首先匹配名字
        for var one in contacts {

            /// 获取缓存的匹配结果
            var matchResult = one.matchResult[matchKey] ?? MContactMatchResult(nameAttribute: [], phoneAttribute: [])

            // 名字拼音
            let namePinYinDic = one.pinyinDic
            let (result, strInfo) = self.matchName(namePinyinDic: namePinYinDic, targetChars: targetChars)
            if result == true, strInfo.count > 0 {
                matchResult.nameAttribute = strInfo
                matchResult.phoneAttribute = []
                one.matchResult[matchKey] = matchResult
                rName.append(one)
            } else {
                phoneContacts.append(one)
            }
        }
        

        rName.sort { (l, r) -> Bool in
            return l.lastContactTime > r.lastContactTime
        }
        

        
        // 然后匹配手机号
        for var one in phoneContacts {
            
            var matchResult = one.matchResult[matchKey] ?? MContactMatchResult(nameAttribute: [], phoneAttribute: [])
            
            var matchInfo = [(String, Bool)]()
            for number in one.phones {
                let (result, strInfo) = self.matchString(string: number, targetString: numberString)
                if result == true, strInfo.count > 0 {
                    matchInfo = strInfo
                    break
                }
            }
            
            if matchInfo.count > 0 {
                matchResult.phoneAttribute = matchInfo
                matchResult.nameAttribute = []
                one.matchResult[matchKey] = matchResult
                rNumber.append(one)
            }
        }
        

        rNumber.sort { (l, r) -> Bool in
            return l.lastContactTime > r.lastContactTime
        }
        
        var cleanRecords = [MRecord]()
        
        // 排重
        var tempKeys = [String]()
        for one in records {
            if tempKeys.contains(one.number) {
                continue
            }
            tempKeys.append(one.number)
            cleanRecords.append(one)
        }
        
        return (rName + rNumber, cleanRecords)
        
    }
    
    /// 筛选通讯录
    ///
    /// - Parameters:
    ///   - contacts: 原通讯录
    ///   - string: 非纯数字字符串
    /// - Returns: 筛选结果
    public func filter(contacts: [MContact], targetString: String, matchKey: String) -> [MContact] {
        
        var r = [MContact]()
        
        if targetString.isNumber() {
            // 纯数字匹配手机号
            for var one in contacts {
                var matchResult = one.matchResult[matchKey] ?? MContactMatchResult(nameAttribute: [], phoneAttribute: [])
                var matchInfo = [(String, Bool)]()
                for number in one.phones {
                    let (result, strInfo) = self.matchString(string: number, targetString: targetString)
                    if result == true, strInfo.count > 0 {
                        matchInfo = strInfo
                        break
                    }
                }
                if matchInfo.count > 0 {
                    matchResult.phoneAttribute = matchInfo
                    matchResult.nameAttribute = []
                    one.matchResult[matchKey] = matchResult
                    r.append(one)
                }
            }
        } else {
            // 其他匹配名字
            for var one in contacts {
                var matchResult = one.matchResult[matchKey] ?? MContactMatchResult(nameAttribute: [], phoneAttribute: [])
                // 匹配拼音
                let namePinYinDic = one.pinyinDic
                let (result, strInfo) = matchName(namePinyinDic: namePinYinDic, targetString: targetString)
                if result == true, strInfo.count > 0 {
                    matchResult.nameAttribute = strInfo
                    matchResult.phoneAttribute = []
                    one.matchResult[matchKey] = matchResult
                    r.append(one)
                } else {
                    // 匹配原字
                    let (nameResult, nameInfo) = matchString(string: one.name, targetString: targetString)
                    if nameResult, nameInfo.count > 0 {
                        matchResult.nameAttribute = nameInfo
                        matchResult.phoneAttribute = []
                        one.matchResult[matchKey] = matchResult
                        r.append(one)
                    }
                }
                
            }
        }
        
        return r
    }
    
}

extension MContactFilter {
    
    // MARK: 匹配姓名拼音
    
    /// 从一个人的人名拼音中找到目标字符串（字符数组）
    ///
    /// - Parameters:
    ///   - namePinyinDic: 一个人名的拼音字典
    ///   - targetString: 目标字符串
    /// - Returns: (是否成功，多彩文字信息(文字，是否高亮))
    func matchName(namePinyinDic: [(String, String)], targetString: String) -> (Bool, [(String, Bool)])  {
        var r =  [(String, Bool)]()
        
        // 目标字符串所包含的字符数组:eg. zsf
        var leftTargetChars = targetString.chars
        // 挨个名字拼音遍历: zhang san feng / zhang san
        for (name, namePinyin) in namePinyinDic {
            if leftTargetChars.count == 0 {
                // 匹配完全了，不需要匹配了
                r.append((name, false))
                continue
            }
            let tempLeftTargetChars = matchChars(string: namePinyin, targetChars: leftTargetChars)
            if tempLeftTargetChars.count < leftTargetChars.count {
                // 匹配成功
                r.append((name, true))
            } else {
                // 匹配失败
                r.append((name, false))
            }
            leftTargetChars = tempLeftTargetChars
        }
        
        if leftTargetChars.count == 0 {
            // 完全匹配成功了，符合筛选结果
            return (true, r)
        } else {
            // 完全匹配失败，不符合筛选结果
            return (false, [])
        }
    }
    
    /// 从一个字符串中，匹配字符数组
    ///
    /// - Parameters:
    ///   - string: 一个字的拼音
    ///   - targetChars: 字符数组
    /// - Returns: 剩余待匹配的字符数组
    func matchChars(string: String, targetChars: [Character]) -> [Character] {
        // 拼音或者开口码用完了，返回
        if string.isEmpty || targetChars.count == 0 {
            return targetChars
        }
        let leftTargetChars = targetChars
        let first = leftTargetChars[0]
        let (result, _ , rightString) = matchChar(string: string, char: first)
        if result {
            // 匹配到了，用剩余的字符串和字符数组
            var tempChars = targetChars
            tempChars.removeFirst()
            return matchChars(string: rightString, targetChars: tempChars)
        } else {
            // 没匹配上，返回
            return targetChars
        }
    }
    
    /// 从一个人的人名拼音中找到目标字符数组
    ///
    /// - Parameters:
    ///   - namePinyinDic: 一个人名的拼音字典（张三：zhangsan）
    ///   - targetChars: 目标开口码（数字代表的字母数组）
    /// - Returns: (是否成功，多彩文字信息(文字，是否高亮))
    func matchName(namePinyinDic: [(String, String)], targetChars: [[Character]]) -> (Bool, [(String, Bool)])  {
        // 返回用的数据
        var r = [(String, Bool)]()
        // 剩余的待匹配数字代表的字母数组 如 23 [[a,b,c],[d,e,f]]
        var leftTargetChars = targetChars
        // 挨个名字拼音遍历
        for (name, namePinyin) in namePinyinDic {
            if leftTargetChars.count == 0 {
                // 匹配完全了，不需要匹配了
                r.append((name, false))
                continue
            }
            // 挨个数字（代表字母数字）匹配
            let tempLeftTargetChars = matchChars(namePinyin: namePinyin, targetChars: leftTargetChars)
            if tempLeftTargetChars.count < leftTargetChars.count {
                // 匹配成功过，记录该汉字的颜色
                r.append((name, true))
                // 改变待匹配数组
                leftTargetChars = tempLeftTargetChars
            } else {
                r.append((name, false))
            }
        }
        if leftTargetChars.count == 0 {
            // 完全匹配成功了，符合筛选结果
            return (true, r)
        } else {
            // 完全匹配失败，不符合筛选结果
            return (false, [])
        }
    }
    
    /// 从一个字符串中，匹配尽量多的字符数组
    ///
    /// - Parameters:
    ///   - namePinyin: 一个字的拼音
    ///   - targetChars: 开口码数组
    /// - Returns: 剩余待匹配的开口码字符数组
    func matchChars(namePinyin: String, targetChars: [[Character]]) -> [[Character]] {
        // 拼音或者开口码用完了，返回
        if namePinyin.isEmpty || targetChars.count == 0 {
            return targetChars
        }
        let first = targetChars[0]
        let (result, rightString) = matchChars(namePinyin: namePinyin, oneChars: first)
        if result {
            // 匹配到了，用剩余的字符串和开口码递归
            var tempChars = targetChars
            tempChars.removeFirst()
            return matchChars(namePinyin: rightString, targetChars: tempChars)
        } else {
            // 没匹配上，返回
            return targetChars
        }
    }
    
    /// 从一个字符串中，找到一个字符数组中一个元素的最优解，比如从zhangsan 里面找到a,b,c的最前结果
    ///
    /// - Parameters:
    ///   - string: 被检索字符串
    ///   - char: 目标字符
    /// - Returns: (是否成功，字符前字符串，字符后字符串)
    func matchChars(namePinyin: String, oneChars: [Character]) -> (Bool, String) {
        
        var minResult: (String, String)?
        
        // 找到最小匹配结果，返还最大剩余字符串
        for one in oneChars {
            let (result, leftString, rightString) = matchChar(string: namePinyin, char: one)
            if result == true {
                
                // 匹配成功
                if minResult == nil {
                    // 第一次匹配上，直接返回
                    minResult = (leftString, rightString)
                } else if minResult!.0.count > leftString.count {
                    // 如果多次匹配上，保留最靠前的匹配记录
                    minResult = (leftString, rightString)
                }
                
                if minResult!.0 == "" {
                    // 第一个字母就是匹配字母，无需比较剩余字母的匹配程度，此为最优结果
                    break
                }
            }
        }
        // 匹配到这个字符了
        if minResult != nil {
            return (true, minResult!.1)
        } else {
            return (false, "")
        }
    }
    
    /// 从一个字符串中找到目标字符
    ///
    /// - Parameters:
    ///   - string: 被检索字符串
    ///   - char: 目标字符
    /// - Returns: (是否成功，字符前字符串，字符后字符串)
    func matchChar(string: String, char: Character) -> (Bool, String, String) {
        if let index = string.firstIndex(of: char) {
            let rightIndex = string.index(after: index)
            let rightString = string[rightIndex...]
            let leftString = string[string.startIndex..<index]
            return (true, String(leftString), String(rightString))
        } else {
            return (false, "", "")
        }
    }
    
    /// 匹配字符串，可用于匹配姓名原字和手机号
    ///
    /// - Parameters:
    ///   - string: 被检索字符串
    ///   - targetString: 关键字
    /// - Returns: 检索成功
    func matchString(string: String, targetString: String) -> (Bool, [(String, Bool)]) {
        
        var rightString = string
        var r = [(String, Bool)]()
        
        for one in targetString {
            let (result, leftString, tempRightString) = matchChar(string: rightString, char: one)
            if result == true {
                r.append((leftString, false))
                r.append((String(one), true))
                rightString = tempRightString
            } else {
                return (false, [])
            }
        }
        r.append((rightString, false))
        return (true, r)
    }
    
}

extension String {
    
    var chars: [Character] {
        var r = [Character]()
        for one in self {
            r.append(one)
        }
        return r
    }
    
    func isNumber() -> Bool {
        var r = true
        for c in self {
            let scan = Scanner(string: String(c))
            var int = Int32()
            if !scan.scanInt32(&int) {
                r = false
                break
            }
        }
        return r
    }
}
