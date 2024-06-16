import io
import logging as log
import numpy as np
import os
import tempfile

from flask import Flask, request, jsonify, make_response
from sys import stderr
from utils import infer_image


# Initialize the Flask application
app = Flask(__name__)

LOG_FORMAT = '%(asctime)s [%(levelname)s]: %(message)s'
log.basicConfig(stream=stderr, format=LOG_FORMAT, level=log.INFO)

@app.route('/')
def main():
    '''Default route does nothing'''
    pass


@app.route('/healthz')
def healthz():
    '''Kubernetes health check'''
    return 'Ok', 200


@app.route('/inference', methods=['POST'])
def inference():
    '''Runs an inference from a given iamge'''
    #  check whether is a file part
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400

    file = request.files['file']
    #  TODO: properly verify that the file is an image
    if file.filename.rsplit('.')[-1].lower() not in ['tif', 'tiff']:
        return jsonify({'error': 'File type not permitted'}), 400

    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    log.info("Saving file to a temporary location")

    # Save the uploaded file to a temp directory
    with tempfile.NamedTemporaryFile(delete=False) as temp_file:
        file.save(temp_file.name)
        temp_file_path = temp_file.name

    try:
        log.info("Running inference for %s" % file.filename)
        # Run the inference
        result = infer_image(temp_file_path)
        # create a bytes stream to save the numpy array
        stream = io.BytesIO()
        np.save(stream, result)
        response = make_response(stream.getvalue())
        # set the right headers for binary data
        response.headers['content-type'] = 'application/octet-stream'
        return response
    except Exception as e:
        log.error(str(e))
        return jsonify({'error': str(e)}), 500
    finally:
        # Remove temporary file
        os.remove(temp_file_path)


if __name__ == '__main__':
    #  TODO: make log level configurable via env variables
    app.run()
