import Vapor

protocol BucketURLConvertible {
    func bucketURLString() -> String
}

extension String: BucketURLConvertible {

    func bucketURLString() -> String {
        guard let bucketURL = Environment.get("OSS_BUCKET_URL") else {
            return self
        }

        guard URL(string: self)?.scheme == nil else {
            return self
        }
        return "\(bucketURL)\(self)"
    }
}
