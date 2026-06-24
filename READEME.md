## INTRO
This is an HTTP server written in ZIG from scratch, that allows you to do CRUD operation on a contact server, serving both frontend and backend
Ideally, this should be able to handle request from both browser and curl.

# DESIGN
We typically get a HTTP request like so:
```
METHOD /path?query HTTP/1.1\r\n
Header-Name: Header-Value\r\n
Another-Header: value\r\n
\r\n
[optional body]
```

The main information is stored before the optional body. A parser needs to reliably parse this information, and respond to it appropriately.

A response would look something like this:
```
HTTP/1.1 200 OK\r\n
Content-Type: text/html\r\n
Content-Length: 42\r\n
\r\n
[body]
```

## What's supported in this project

This is just a learning project, so it'll only support a subset of features provided by HTTP:

### Methods
1. GET
2. POST
3. DELETE
3. PUT

### Status Code
1. **1xx — Informational**: `100 Continue`
2. **2xx - Success**: `200 OK`, `201 Created`
3. **4xx - Client error**: `400 Bad Request`, `401 Unauthorized`, `404 Not Found`, `405 Method Not Allowed`
4. **5xx - Server Error**: `500 Internal Server Error`, `501 Not Implemented`

