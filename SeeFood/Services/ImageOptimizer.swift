import UIKit
import OSLog

enum ImageOptimizerError: Error {
    case compressionFailed
    case saveFailed
    case invalidImage
}

class ImageOptimizer {
    private let logger = Logger(subsystem: "com.seefood.app", category: "ImageOptimizer")
    private let fileManager = FileManager.default
    
    // Maximum image dimension (width or height)
    private let maxDimension: CGFloat = 1200
    // JPEG compression quality (0.0 to 1.0)
    private let compressionQuality: CGFloat = 0.7
    
    func optimizeImage(_ image: UIImage) throws -> (UIImage, Data) {
        // Resize image if needed
        let resizedImage = resizeImageIfNeeded(image)
        
        // Compress image
        guard let imageData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            logger.error("Failed to compress image")
            throw ImageOptimizerError.compressionFailed
        }
        
        return (resizedImage, imageData)
    }
    
    func saveImage(_ image: UIImage, forMealId mealId: UUID) throws -> URL {
        let documentsDirectory = try fileManager.url(for: .documentDirectory,
                                                   in: .userDomainMask,
                                                   appropriateFor: nil,
                                                   create: true)
        
        let imageDirectory = documentsDirectory.appendingPathComponent("MealImages", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: imageDirectory.path) {
            try fileManager.createDirectory(at: imageDirectory,
                                         withIntermediateDirectories: true)
        }
        
        let imageUrl = imageDirectory.appendingPathComponent("\(mealId.uuidString).jpg")
        
        // Optimize and save image
        let (_, imageData) = try optimizeImage(image)
        
        do {
            try imageData.write(to: imageUrl)
            logger.info("Successfully saved image for meal \(mealId)")
            return imageUrl
        } catch {
            logger.error("Failed to save image: \(error.localizedDescription)")
            throw ImageOptimizerError.saveFailed
        }
    }
    
    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let size = image.size
        
        // Check if resizing is needed
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        var newSize: CGSize
        if size.width > size.height {
            let ratio = maxDimension / size.width
            newSize = CGSize(width: maxDimension, height: size.height * ratio)
        } else {
            let ratio = maxDimension / size.height
            newSize = CGSize(width: size.width * ratio, height: maxDimension)
        }
        
        // Resize image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
} 