//
//  YYTextField.swift
//  Runner
//
//  Created by lionel.hong on 2021/5/11.
//

import Foundation
import Flutter
import GrowingTextView

let bindClassKey = NSAttributedString.Key(rawValue: "BindClassKey")

class YYTextField : NSObject,FlutterPlatformView,GrowingTextViewDelegate {
    
    var viewId:Int64 = -1
    var textView:GrowingTextView!
    var channel:FlutterMethodChannel!
    
    var defaultAttributes: [NSAttributedString.Key: Any] = [
        bindClassKey: "",
        .font: UIFont.systemFont(ofSize: 14),
        .foregroundColor: UIColor.black,
    ]
    
    var atAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 14),
        .foregroundColor: UIColor.blue,
    ]
    
    func getAtAttributes() -> [NSAttributedString.Key: Any] {
        return [
            bindClassKey: UUID().uuidString,
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.blue,
        ]
    }
    
    init(frame: CGRect, viewId: Int64, args:Any?,  messenger: FlutterBinaryMessenger) {
        // 处理通信
        self.viewId = viewId
        // 页面初始化
        var _frame = frame
        if _frame.size.width == 0 {
            _frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: UIScreen.main.bounds.size.width, height: 40)
        }
        super.init()
        
        channel = FlutterMethodChannel(name: "com.fanbook.yytextfield_\(viewId)", binaryMessenger: messenger)
        channel.setMethodCallHandler { [weak self] (call, result) in
            self?.handlerMethodCall(call)
        }
        
        let args = args as? [String: Any]
        let initText = (args?["text"] as? String) ?? ""
        let textStyle = (args?["textStyle"] as? [String: Any])
        let placeHolderStyle = (args?["placeHolderStyle"] as? [String: Any])
        let placeHolder = (args?["placeHolder"] as? String) ?? ""
        defaultAttributes = textStyle2Attribute(textStyle: textStyle, defaultAttr: defaultAttributes)
        let placeHolderStyleAttr = textStyle2Attribute(textStyle: placeHolderStyle, defaultAttr: defaultAttributes)
        
        textView = GrowingTextView(frame: _frame)
        textView.attributedText = NSMutableAttributedString(string: initText,attributes: defaultAttributes)
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textView.delegate = self
        textView.backgroundColor = UIColor.clear
        textView.maxHeight = 142
        textView.minHeight = 40
        textView.placeholder = placeHolder
        textView.placeholderColor = placeHolderStyleAttr[.foregroundColor] as! UIColor
    }
    
    func handlerMethodCall(_ call: FlutterMethodCall) {
        switch call.method {
        case "insertAtName":
            if let args = call.arguments as? [String : Any] {
                let name = (args["name"] as? String) ?? ""
                let textStyle = (args["textStyle"] as? [String : Any]?) ?? [:]
                appendAtString(name: name, textStyle: textStyle)
            }
            break
        case "insertChannelName":
            if let args = call.arguments as? [String : Any] {
                let name = (args["name"] as? String) ?? ""
                let textStyle = (args["textStyle"] as? [String : Any]?) ?? [:]
                appendChannelString(name: name, textStyle: textStyle)
            }
            break
        case "updateFocus":
            if let focus = call.arguments as? Bool {
                if focus {
                    textView.becomeFirstResponder()
                } else {
                    textView.resignFirstResponder()
                }
            }
            break
        default:
            break
        }
    }
    
    
    func appendAtString(name: String, textStyle: [String: Any]?) {
        let isOriginEmpty = textView.text.isEmpty
            
        _ = self.textView(textView, shouldChangeTextIn: textView.selectedRange, replacementText: "")
        
        let atName = "@\(name) "
        
        let str = NSMutableAttributedString(attributedString: textView.attributedText!)
    
        let location = textView.selectedRange.location
        
        var attr:[NSAttributedString.Key: Any] = textStyle2Attribute(textStyle: textStyle, defaultAttr: atAttributes)
        attr[bindClassKey] = UUID().uuidString
        
        str.insert(NSAttributedString(string: atName,attributes: attr), at: location)
    
        textView.attributedText = str
        
        textView.selectedRange = NSMakeRange(location + atName.count, 0)
        
        if (isOriginEmpty) { // 必要时重绘placeHolder，不设置textView不会刷新
            textView.placeholder = textView.placeholder
        }
    }
    
    func appendChannelString(name: String, textStyle: [String: Any]?) {
        let isOriginEmpty = textView.text.isEmpty
        
        _ = self.textView(textView, shouldChangeTextIn: textView.selectedRange, replacementText: "")
        
        let atName = "#\(name) "
        
        let str = NSMutableAttributedString(attributedString: textView.attributedText!)
    
        let location = textView.selectedRange.location
        
        var attr:[NSAttributedString.Key: Any] = textStyle2Attribute(textStyle: textStyle, defaultAttr: atAttributes)
        attr[bindClassKey] = UUID().uuidString
        
        str.insert(NSAttributedString(string: atName,attributes: attr), at: location)
    
        textView.attributedText = str
        
        textView.selectedRange = NSMakeRange(location + atName.count, 0)
        
        textView.placeholder = textView.placeholder
        
        if (isOriginEmpty) { // 必要时重绘placeHolder，不设置textView不会刷新
            textView.placeholder = textView.placeholder
        }
    }
    
    func view() -> UIView {
        return textView
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        channel.invokeMethod("updateFocus", arguments: true)
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool{
        // 重置输入样式
        textView.typingAttributes = defaultAttributes
        // 输入文字
        if (range.location >= textView.attributedText.length) {
            return true
        }
        if range.length > 1 {
            // 需要把包含在range这个区间头部和尾部的富文本样式去掉
            let beginRange = getCurrentRange(position: range.location)
            let count = (textView.text as NSString).substring(with: beginRange).trimmingCharacters(in: .whitespaces).count
            if beginRange != NSRange() && range.location < beginRange.location + count {
                let str = NSMutableAttributedString(attributedString: textView.attributedText!)
                str.addAttributes(defaultAttributes, range: beginRange)
                textView.attributedText = str
                textView.selectedRange = range
            }
            let endRange = getCurrentRange(position: range.location + range.length)
            if endRange != NSRange() && beginRange != endRange {
                if range.location + range.length > endRange.location {
                    let str = NSMutableAttributedString(attributedString: textView.attributedText!)
                    str.addAttributes(defaultAttributes, range: endRange)
                    textView.attributedText = str
                    textView.selectedRange = range
                }
            }
            return true
        }
        
        // 删除或者替换文字
        let _range = getCurrentRange(position: range.location)
        if _range != NSRange() {
            let count = (textView.text as NSString).substring(with: _range).trimmingCharacters(in: .whitespaces).count
            // 尾部删除
            if (range.length == 1 && text.count == 0)
                && (range.location + 1 == _range.location + count || range.location + 1 == _range.location + count + 1) {
                let textRange = textView.textRange(from: textView.position(from: textView.beginningOfDocument, offset: _range.location)!, to: textView.position(from: textView.beginningOfDocument, offset: _range.location + _range.length)!)
                textView.replace(textRange!, withText: text)
                return false
            }
            // 尾部添加
            else if (range.length == 0 && text.count > 0)
                && (range.location == _range.location + count || range.location == _range.location + count + 1) {
                return true
            }
            // 正常删除，并去掉样式
            else if range.location + range.length > _range.location {
                let str = NSMutableAttributedString(attributedString: textView.attributedText!)
                str.addAttributes(defaultAttributes, range: _range)
                textView.attributedText = str
                textView.selectedRange = range
                return true
            }
            
        }
        
        return true
    }
    
    /// 高度变化回调
    func textViewDidChangeHeight(_ textView: GrowingTextView, height: CGFloat) {
        let frame = textView.frame
        channel.invokeMethod("updateHeight", arguments: height)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
            textView.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: height)
        }
    }

}


extension YYTextField {
    func textStyle2Attribute(textStyle :[String: Any]?, defaultAttr :[NSAttributedString.Key: Any]?) -> [NSAttributedString.Key: Any] {
        guard let textStyle = textStyle else {
            return defaultAttr ?? [:]
        }
        let textColorValue = (textStyle["color"] as? Int) ?? 0
        let fontSize = (textStyle["fontSize"] as? Int) ?? 14
        let height = (textStyle["height"] as? Double) ?? 1.17
        let textColor = UIColor.init(color: textColorValue)
        return [
            bindClassKey: "",
            .font: UIFont.systemFont(ofSize: CGFloat(fontSize)),
            .foregroundColor: textColor,
        ]
    }
}

// MARK: - Range 处理
extension YYTextField {
    
    func getBindClassValue(attr: [NSAttributedString.Key : Any]) -> String? {
        
        func isBindClass(attr: [NSAttributedString.Key : Any]) -> Bool {
            return attr.keys.contains(bindClassKey) && (attr[bindClassKey] as! String).count > 0
        }
        
        if !isBindClass(attr: attr) {
            return nil
        }
        return attr[bindClassKey] as? String
    }
    
    func getBindClassValue(position: Int) -> String? {
        if position <= 0 { return nil }
        let attr = textView.attributedText.attributes(at: position, effectiveRange: nil)
        return getBindClassValue(attr: attr)
    }
    
    func getCurrentRange(position: Int) -> NSRange {
        if position < 0 || position >= textView.text.count {
            return NSRange()
        }
        
        guard let value = getBindClassValue(position: position) else {
            return NSRange()
        }
        
        var _position = position, _location = 0, _length = 0
        while _position >= 0 {
            var range = NSRange()
            let attr = textView.attributedText.attributes(at: _position, effectiveRange: &range)
            if value != getBindClassValue(attr: attr) {
                break
            } else {
                _location = range.location
                _length += range.length
                _position = _location - 1
            }
        }
        
        _position = _location + _length
        while _position < textView.text.count {
            var range = NSRange()
            let attr = textView.attributedText.attributes(at: _position, effectiveRange: &range)
            if value != getBindClassValue(attr: attr) {
                break
            } else {
                _length = range.length + range.location - _location
                _position = range.location + range.length + 1
            }
        }
        
        
        return NSRange(location: _location, length: _length)
    }
    
}
