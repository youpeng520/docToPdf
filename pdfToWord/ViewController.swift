//
//  ViewController.swift
//  pdfToWord
//
//  Created by 左有朋 on 2025/4/29.
//

import UIKit
import PDFKit
import OfficeFileReader
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // Initialize the converter
//        let docxURL = URL(fileURLWithPath: Bundle.main.path(forResource: "doc", ofType: "doc")!)
//        let data = try! Data(contentsOf:docxURL)
//        let file = try! DocFile(data: data)
//        print(file.wordDocumentStream)
        
        
        let docURL = URL(fileURLWithPath: Bundle.main.path(forResource: "doc", ofType: "doc")!)
        
        // 输出 PDF 文件的路径
        let pdfURL = FileManager.default.temporaryDirectory.appendingPathComponent("output.pdf")
        
        try? FileManager.default.removeItem(at: pdfURL)
        
        do {
            let data = try Data(contentsOf: docURL)
            let docFile = try DocFile(data: data)
            try saveDocToPDF(docFile: docFile, outputPath: pdfURL.path)
            print("转换成功！PDF 文件路径：\(pdfURL.path)")
        } catch {
            print("转换失败: \(error)")
        }
        
    }
    
   
    // 保存 Doc 文件到 PDF 的函数
    func saveDocToPDF(docFile: DocFile, outputPath: String) throws {
        guard let characters = docFile.characters else {
            throw NSError(domain: "DocFileError", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法提取文档内容"])
        }

        let text = characters.text
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let margin: CGFloat = 40

        let font = UIFont(name: "Helvetica", size: 12) ?? UIFont.systemFont(ofSize: 12)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]

        let attributedText = NSAttributedString(string: text, attributes: attributes)

        // 设置绘图区域
        let textRect = CGRect(x: margin, y: margin, width: pageRect.width - 2 * margin, height: pageRect.height - 2 * margin)

        // 创建文本框架
        let framesetter = CTFramesetterCreateWithAttributedString(attributedText)

        UIGraphicsBeginPDFContextToFile(outputPath, pageRect, nil)

        var currentRange = CFRange(location: 0, length: 0)

        while currentRange.location < attributedText.length {
            UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
            let context = UIGraphicsGetCurrentContext()!
            context.textMatrix = .identity
            context.translateBy(x: 0, y: pageRect.height)
            context.scaleBy(x: 1.0, y: -1.0)

            let path = CGMutablePath()
            path.addRect(textRect)

            // 计算当前页能容纳多少文字
            let frame = CTFramesetterCreateFrame(framesetter, currentRange, path, nil)
            CTFrameDraw(frame, context)

            // 更新范围
            let visibleRange = CTFrameGetVisibleStringRange(frame)
            currentRange = CFRange(location: currentRange.location + visibleRange.length, length: 0)
        }

        UIGraphicsEndPDFContext()
        print("PDF 文件保存成功：\(outputPath)")
    }


    func test(){
        let converter = DOCXConverter()
        
        // 输入 DOCX 文件的路径 (确保文件存在)
        let docxURL = URL(fileURLWithPath: Bundle.main.path(forResource: "example", ofType: "docx")!)
        
        // 输出 PDF 文件的路径
        let pdfURL = FileManager.default.temporaryDirectory.appendingPathComponent("output.pdf")
        
        do {
            // 调用转换方法
            try converter.convertToPDF(inputURL: docxURL, outputURL: pdfURL)
            print("转换成功！PDF 文件路径：\(pdfURL.path)")
            
            // 可选：查看生成的 PDF
            openPDF(at: pdfURL)
        } catch {
            print("转换失败: \(error)")
        }
    }
    
    
    // 打开 PDF 文件
       func openPDF(at url: URL) {
           let pdfViewController = UIViewController()
           let pdfView = PDFKit.PDFView(frame: pdfViewController.view.bounds)
           pdfView.autoScales = true
           pdfView.document = PDFKit.PDFDocument(url: url)
           pdfViewController.view.addSubview(pdfView)
           self.present(pdfViewController, animated: true, completion: nil)
       }


}

