import uuid
import base64
import mimetypes
from datetime import datetime

def lambda_handler(event, context):
    
            request_json = event['body']

            try:
                image_bytes = base64.b64decode(request_json['image_data'], validate=True)
            except (base64.binascii.Error, ValueError):
                raise ValueError("Invalid base64-encoded image data")
                
            max_size = 5 * 1024 * 1024
            if len(image_bytes) > max_size:
                raise ValueError("Image is too large")
                
            if not image_bytes.startswith((b'\xff\xd8', b'\x89PNG')): # JPEG or PNG
                raise ValueError("Unsupported image format (must be JPG or PNG)")            
            
            timestamp = datetime.now().isoformat()
            image_id = str(uuid.uuid4())
            content_type = request_json.get('content_type', 'image/jpeg')
            file_extension = mimetypes.guess_extension(content_type) or '.jpg'
            image_base64 = base64.b64encode(image_bytes).decode("utf-8")
            
            return {
                  "validation": "passed",
                  "image_id": image_id,
                  "file_extension": file_extension,
                  "image_bytes": image_base64,                  
                  "upload_time": timestamp,
                  "status": "pending"
            }