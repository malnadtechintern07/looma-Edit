import Foundation
import AppKit

let srcPath = "/Users/apple/.gemini/antigravity-ide/brain/3020f8b9-aa57-4b47-90c9-c85f9bd166f8/.user_uploaded/media_1788160236668.jpg"
let dstPath = "/Users/apple/Desktop/looma/scratch/looma_emblem_clean.png"

guard let image = NSImage(contentsOfFile: srcPath) else {
    print("Failed to open source image")
    exit(1)
}
var imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
guard let cgImage = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil) else {
    print("Failed to get CGImage")
    exit(1)
}

let cropRect = CGRect(x: 172, y: 80, width: 680, height: 680)
guard let croppedCg = cgImage.cropping(to: cropRect) else {
    print("Failed to crop CGImage")
    exit(1)
}

let bitmapRep = NSBitmapImageRep(cgImage: croppedCg)
guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
    print("Failed to generate PNG data")
    exit(1)
}

try pngData.write(to: URL(fileURLWithPath: dstPath))
print("Successfully generated clean emblem PNG at \(dstPath)!")
