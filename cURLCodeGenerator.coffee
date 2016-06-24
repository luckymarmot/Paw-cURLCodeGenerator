# in API v0.2.0 and below (Paw 2.2.2 and below), require had no return value
((root) -> root.Mustache = require("mustache.js") or root.Mustache)(this)

addslashes = (str) ->
    ("#{str}").replace(/[\\"]/g, '\\$&')

addslashes_single_quotes = (str) ->
    ("#{str}").replace(/[\\']/g, '\\$&')

cURLCodeGenerator = ->

    @headers = (request) ->
        headers = request.headers
        return {
            "has_headers": Object.keys(headers).length > 0
            "header_list": ({
                "header_name": addslashes header_name
                "header_value": addslashes header_value
            } for header_name, header_value of headers)
        }

    @body = (request) ->
        url_encoded_body = request.urlEncodedBody
        if url_encoded_body
            return {
                "has_url_encoded_body":true
                "url_encoded_body": ({
                    "name": addslashes name
                    "value": addslashes value
                } for name, value of url_encoded_body)
            }

        multipart_body = request.multipartBody
        if multipart_body
            return {
                "has_multipart_body":true
                "multipart_body": ({
                    "name": addslashes name
                    "value": addslashes value
                } for name, value of multipart_body)
            }

        raw_body = request.body
        if raw_body
            if raw_body.length < 5000
                has_tabs_or_new_lines = (null != /\r|\n|\t/.exec(raw_body))
                return {
                    "has_raw_body_with_tabs_or_new_lines":has_tabs_or_new_lines
                    "has_raw_body_without_tabs_or_new_lines":!has_tabs_or_new_lines
                    "raw_body": if has_tabs_or_new_lines then addslashes_single_quotes raw_body else addslashes raw_body
                }
            else
                return {
                    "has_long_body":true
                }

    @strip_last_backslash = (string) ->
    # Remove the last backslash on the last non-empty line
    # We do that programatically as it's difficult to know the "last line"
    # in Mustache templates

        lines = string.split("\n")
        for i in [(lines.length - 1)..0]
            lines[i] = lines[i].replace(/\s*\\\s*$/, "")
            if not lines[i].match(/^\s*$/)
                break
        lines.join("\n")

    @generate = (context) ->
        request = context.getCurrentRequest()

        view =
            "request": context.getCurrentRequest()
            "headers": @headers request
            "body": @body request

        # Make multi-line description.
        view.request.cURLDescription = view.request.description.split('\n').map((line, index) ->
          return if index > 0 then "##{line}" else line
        ).join('\n')

        template = readFile "curl.mustache"
        rendered_code = Mustache.render template, view
        @strip_last_backslash rendered_code

    return


cURLCodeGenerator.identifier =
    "com.luckymarmot.PawExtensions.cURLCodeGenerator"
cURLCodeGenerator.title =
    "cURL"
cURLCodeGenerator.fileExtension = "sh"
cURLCodeGenerator.languageHighlighter = "bash"

registerCodeGenerator cURLCodeGenerator
