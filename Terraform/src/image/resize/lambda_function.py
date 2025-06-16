from PIL import Image
import io
import base64

def lambda_handler(event, context):
    image_bytes = base64.b64decode(event["image_bytes"])
    file_extension = event["file_extension"]     

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
    encoded_bytes = base64.base64encode(resized_image_bytes).decode("utf-8")

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