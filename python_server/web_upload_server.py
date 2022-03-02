'''
    This is a small backend server in Python using Flask paired with a Flutter app.
    The small project is about sending and receiving files encoded in base64 while implementing a good CORS policy in this backend server.
    CORS (Cross-origin resource sharing) policy is a mechanism that uses HTTP headers to check
    if a server allows to share files outside of a given domain (cross-origin). This allows a very controlled environment
    when sharing resources with other domains to prevent potential information leakage or attacks.

    CORS process:
        1. Before the domain asks for a resource, the browser that is being used sends a CORS preflight request before the actual request.
        This CORS preflight request gives small information of the actual request (like method, etc.)
        to the server before its executed in its totality.
        This gives the server an opportunity to check what operations will be done and if it either allow it or tell the browser show an error to the client.
        2. Send actual request if the CORS preflight allows the request to be sent.

    More information about CORS preflight: https://livebook.manning.com/book/cors-in-action/chapter-4/13
'''

# Flask is a framework for creating easy and fast backend servers.
from flask import Flask, request, make_response, jsonify

# Utility libraries
import os  # For manipulating directories
import base64  # For encoding and decoding

# App Creation
app = Flask(__name__)

# Create directories in a known location to save files to and to store files to be sent
# (everyone in the same root as this file)
uploads_dir = os.path.join(os.getcwd(), 'saved_files')  # Path to 'saved_files' directory (files received)
saved_dir = os.path.join(os.getcwd(), 'send_files')  # Path to 'send_files' directory (files that can be sent)
os.makedirs(uploads_dir, exist_ok=True)


# Creating the route to receive files and save them and defining the only accepted methods for that route
@app.route('/ufile', methods=['POST', 'OPTIONS'])
def save_file():
    if request.method == "OPTIONS":  # Dispatching CORS preflight
        # Creating a very basic CORS preflight request. Allows every domain to upload a file while using ONLY
        # the POST method without caring what other headers the request may have.
        response = make_response()
        response.access_control_allow_origin = "*"
        response.access_control_allow_methods = "POST"
        response.access_control_allow_headers = "*"
        return response
    elif request.method == "POST":  # The actual request following the preflight
        try:
            # Obtaining the file encoded in the POST request (YES! You don't need to encode sent files in the POST request)
            # Using the self-made field (created in the original request) 'filebytes'.
            file_to_save = request.files['filebytes']

            # Saving the file itself using its own name
            file_to_save.save(os.path.join(uploads_dir, file_to_save.filename))

            # Do more shenanigans

            # Creating a basic response message
            response_dict = {"message": "Ok"}

            # Return Response
            response = make_response(jsonify(response_dict))
            response.status_code = 200  # Success server code
            response.headers.add("Access-Control-Allow-Origin", "*")
            return response
        except ValueError:
            # Creating a basic error response message
            response_dict = {"message": "File in field 'filebytes' does not exist."}

            # Return Response
            response = make_response(jsonify(response_dict))
            response.status_code = 400  # Bad request server error code
            response.headers.add("Access-Control-Allow-Origin", "*")
            return response
    else:
        # Dispatching a no valid method
        response = make_response()
        response.status_code = 405  # Method not allowed server error code
        response.headers.add("Access-Control-Allow-Origin", "*")
        return response


@app.route('/gfile', methods=['POST', 'OPTIONS'])
def send_file():
    if request.method == "OPTIONS":  # CORS preflight
        response = make_response()
        response.access_control_allow_origin = "*"
        response.access_control_allow_methods = "POST"
        response.access_control_allow_headers = "*"
        return response
    elif request.method == "POST":  # The actual request following the preflight
        # Creating Response file
        response_dict = {}

        try:
            # Getting the filename from the field 'filename'
            filename = request.form.get('filename')

            # Try to locate and read the file. Then, encode it to a base 64 string
            with open(os.path.join(saved_dir, filename), 'rb') as file:
                encoded_file = base64.b64encode(file.read())
                response_dict["file64"] = encoded_file.decode('utf-8')

            response_dict['message'] = "Ok"
            response_dict['extension'] = filename.split(".")[1]

            # Return Response
            response = make_response(jsonify(response_dict))
            response.status_code = 200  # Success server code
            response.headers.add("Access-Control-Allow-Origin", "*")
            return response
        except ValueError:
            # Return Response
            response_dict['message'] = "Filename in field 'filename' does not exist."
            response = make_response(jsonify(response_dict))
            response.status_code = 400  # Bad request server error code
            response.headers.add("Access-Control-Allow-Origin", "*")
            return response
        except OSError:
            # Return Response
            response_dict['message'] = "File not found"
            response = make_response(jsonify(response_dict))
            response.status_code = 500  # Internal server error code
            response.headers.add("Access-Control-Allow-Origin", "*")
            return response
    else:
        # Dispatching a no valid method
        response = make_response()
        response.status_code = 405  # Method not allowed server error code
        response.headers.add("Access-Control-Allow-Origin", "*")
        return response


if __name__ == '__main__':
    app.run(host="localhost", port=15000, debug=True)
