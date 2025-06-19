from PIL import Image, UnidentifiedImageError
import io
import base64
import binascii

def lambda_handler(event, context):
    try:
        image_bytes = base64.b64decode(event['validation_result']["image_bytes"])
        file_extension = event['validation_result']["file_extension"]     

        base_width = 300

        img = Image.open(io.BytesIO(image_bytes))
        original_width, original_height = img.size

        wpercent = (base_width / float(img.size[0]))
        hsize = int((float(img.size[1]) * float(wpercent)))
        img = img.resize((base_width, hsize), Image.Resampling.LANCZOS)

        new_width, new_height = img.size

        output_buffer = io.BytesIO()
        if file_extension in ["jpg", "jpeg"]:
            img.save(output_buffer, format="JPEG", quality=75, optimize=True)
        elif file_extension == "png":
            img.save(output_buffer, format="PNG", optimize=True)
        else:
            img.save(output_buffer, format=file_extension.upper())

        output_buffer.seek(0)
        resized_image_bytes = output_buffer.read()
        encoded_bytes = base64.b64encode(resized_image_bytes).decode("utf-8")

        return {
            "original": {
                "width": original_width,
                "height": original_height
            },
            "new": {
                "width": new_width,
                "height": new_height
            },
            "resized_image_base64": encoded_bytes
        }
    except (binascii.Error, ValueError) as b64_error:
        raise Exception(f"Invalid base64 input: {b64_error}")
    except UnidentifiedImageError:
        raise Exception(f"Could not identify image file")
    except OSError as img_error:
        raise Exception(f"Image processing failed: {img_error}")
    except Exception as e:
        raise Exception(f"Unexpected error: {e}")