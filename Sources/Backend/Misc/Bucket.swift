import Vapor

protocol BucketURLConvertible {
    func bucketURLString() -> String
}

extension String: BucketURLConvertible {

    func bucketURLString() -> String {
        guard let bucketURL = Environment.get("IMG_BUCKET_URL") else {
            return self
        }

        guard !hasPrefix("http://") && !hasPrefix("https://") && !hasPrefix("//") else {
            return self
        }
        return "\(bucketURL)\(self)"
    }
}
