//
//  YYTextField.swift
//  Runner
//
//  Created by lionel.hong on 2021/5/11.
//

import Flutter
import Foundation

let bindClassKey = NSAttributedString.Key(rawValue: "BindClassKey")
let dataKey = NSAttributedString.Key(rawValue: "data")

class RichTextField: NSObject, FlutterPlatformView {
    var viewId: Int64 = -1
    var textView: GrowingTextView!
    var channel: FlutterMethodChannel!
    var bakReplacementText: String = ""
    var beginScollOffestY: CGFloat = 1
    
    var pHStyle: [String: Any]?;
    
    var pHBreakWord: Bool?;

    var defaultAttributes: [NSAttributedString.Key: Any] = [
        bindClassKey: "",
        .font: UIFont.systemFont(ofSize: 17),
        .foregroundColor: UIColor.black,
    ]

    var atAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 17),
        .foregroundColor: UIColor.blue,
    ]

    init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
        // 处理通信
        self.viewId = viewId
        // 页面初始化
        let args = args as? [String: Any]
        let height = (args?["height"] as? CGFloat) ?? 32
        var _frame = frame
        if _frame.size.width == 0 {
            let width = (args?["width"] as? CGFloat) ?? UIScreen.main.bounds.size.width
            _frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: width, height: height)
        }
        super.init()

        channel = FlutterMethodChannel(name: "com.fanbook.rich_textfield_\(viewId)", binaryMessenger: messenger)
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handlerMethodCall(call, result)
        }
        
        var _textContainerInset = UIEdgeInsets.zero
        if let textContainerInsetMap = args?["textContainerInset"] as? [String: Any],
            let top = textContainerInsetMap["top"] as? CGFloat,
           let left = textContainerInsetMap["left"] as? CGFloat,
           let bottom = textContainerInsetMap["bottom"] as? CGFloat,
           let right = textContainerInsetMap["right"] as? CGFloat {
            _textContainerInset = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
        }

        let initText = (args?["text"] as? String) ?? ""
        let textStyle = (args?["textStyle"] as? [String: Any])
        let cursorColor = (args?["cursorColor"] as? Int) ?? 0
        let placeHolderStyle = (args?["placeHolderStyle"] as? [String: Any])
        let placeHolder = (args?["placeHolder"] as? String) ?? ""
        let maxLength = (args?["maxLength"] as? Int) ?? 5000
        let done = (args?["done"] as? Bool) ?? false
        
        let minHeight = (args?["minHeight"] as? CGFloat) ?? 32
        let maxHeight = (args?["maxHeight"] as? CGFloat) ?? 142
        let fontSize = (textStyle?["fontSize"] as? CGFloat) ?? 17
        let placeHolderBreakWord =  (args?["placeHolderBreakWord"] as? Bool) ?? false
        defaultAttributes = textStyle2Attribute(textStyle: textStyle, defaultAttr: defaultAttributes)

        textView = GrowingTextView(frame: _frame)
        textView.font = .systemFont(ofSize: fontSize)
        textView.textColor = defaultAttributes[.foregroundColor] as? UIColor ?? UIColor.black
        textView.tintColor = UIColor(color: cursorColor)
        textView.attributedText = NSMutableAttributedString(string: initText, attributes: defaultAttributes)
        textView.textContainerInset = _textContainerInset
        textView.delegate = self
        textView.backgroundColor = UIColor.clear
        textView.inputAccessoryView = UIView()
        
        textView.maxHeight = maxHeight
        textView.minHeight = minHeight
        textView.attributedPlaceholder = NSAttributedString(string: placeHolder, attributes: textStyle2Attribute(textStyle: placeHolderStyle, defaultAttr: defaultAttributes, placeHolderBreakWord: placeHolderBreakWord))
        textView.maxLength = maxLength
        pHStyle = placeHolderStyle;
        pHBreakWord = placeHolderBreakWord;
        if done { textView.returnKeyType = .done }
    }

    func handlerMethodCall(_ call: FlutterMethodCall, _ result: FlutterResult) {
        switch call.method {
        case "insertBlock":
            if let args = call.arguments as? [String: Any] {
                let name = (args["name"] as? String) ?? ""
                let data = (args["data"] as? String) ?? ""
                let prefix = (args["prefix"] as? String) ?? ""
                let textStyle = (args["textStyle"] as? [String: Any]?) ?? [:]
                let backSpaceLength = (args["backSpaceLength"] as? Int) ?? 0
                insertBlock(name: name, data: data, textStyle: textStyle, prefix: prefix, backSpaceLength: backSpaceLength)
            }
            break
        case "insertText":
            if let args = call.arguments as? [String: Any] {
                let text = (args["text"] as? String) ?? ""
                let backSpaceLength = (args["backSpaceLength"] as? Int) ?? 0
                insertText(text: text, backSpaceLength: backSpaceLength)
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
        case "replace":
            if let args = call.arguments as? [String: Any] {
                let text = (args["text"] as? String) ?? ""
                let selectionStart = (args["selection_start"] as? Int) ?? 0
                let selectionEnd = (args["selection_end"] as? Int) ?? selectionStart
                replace(text: text, range: NSRange(location: selectionStart, length: selectionEnd - selectionStart))
            }
            break
        case "setText":
            if let text = call.arguments as? String {
                setText(text: text)
            }
            break
        case "setPlaceholder":
            if let text = call.arguments as? String {
                textView.attributedPlaceholder = NSAttributedString(string: text, attributes: textStyle2Attribute(textStyle: pHStyle, defaultAttr: defaultAttributes, placeHolderBreakWord: pHBreakWord ?? false))
            }
            break
        case "setAlpha":

            if let alpha = call.arguments as? CGFloat {
                textView.alpha = alpha
            }
            break
        case "updateWidth":
            if let width = call.arguments as? Double {
                updateWidth(width: width)
            }
            break
        default:
            break
        }
    }

    func view() -> UIView {
        return textView
    }
}

// MARK: - 处理编辑中各种富文本的逻辑

extension RichTextField: GrowingTextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        updateFocus(focus: true)
        /// 不加延时的话，textView.selectedRange始终是指向最后的位置
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(200)) {
            let ret = textView.caretRect(for: textView.position(from: textView.beginningOfDocument, offset: textView.selectedRange.location)!)
            self.updateCursor(poisition: ret.origin.y)
        }
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        updateValue()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let ret = textView.caretRect(for: textView.position(from: textView.beginningOfDocument, offset: textView.selectedRange.location)!)
        updateCursor(poisition: ret.origin.y)
        
        if text == "\n" && textView.returnKeyType == .done {
            submitText()
            return false
        }

        bakReplacementText = text
        // 重置输入样式
        textView.typingAttributes = defaultAttributes
        // 输入文字
        if range.location >= textView.attributedText.length {
            return true
        }
        
        /// 是否是删除单个字符
        let deleteChatSingle = (textView.text as NSString).substring(with: range).count == 1
        
        if !deleteChatSingle && range.length > 0 {
            // 需要把包含在range这个区间头部和尾部的富文本样式去掉
            let beginRange = getCurrentRange(position: range.location)
            let lastSpace = (textView.text as NSString).substring(with: beginRange).last == " "
            let count = beginRange.length - (lastSpace ? 1 : 0)
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
            let count = _range.length //(textView.text as NSString).substring(with: _range).trimmingCharacters(in: .whitespaces).count
            let lastSpace = (textView.text as NSString).substring(with: _range).last == " "
            // 尾部删除
            if (deleteChatSingle && text.count == 0)
                && (range.location + range.length == _range.location + count || (lastSpace && range.location + range.length == _range.location + count - 1)) {
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
        channel.invokeMethod("updateHeight", arguments: height)
    }
    
    
    func textViewScrollToEnd(_ textView: GrowingTextView) {
        hideKeyboard()
    }
    
    
}
