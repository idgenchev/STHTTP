#!/usr/bin/env python

import web

urls = (
    '/test', 'Test'
)

app = web.application(urls, globals())

class Test:
    def GET(self):
        return "GET successful"

    def POST(self):
        return "POST successful"

if __name__ == "__main__":
    app.run()
