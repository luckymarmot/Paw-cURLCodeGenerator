# in API v0.2.0 and below (Paw 2.2.2 and below), require had no return value
((root) -> root.Mustache = require("mustache.js") or root.Mustache)(this)
((root) -> root.Base64 = require("Base64.js") or root.Base64)(this)

addslashes = (str) ->
    ("#{str}").replace(/[\\"]/g, '\\$&')

addslashes_single_quotes = (str) ->
    ("#{str}").replace(/[\\']/g, '\\$&')

cURLCodeGenerator = ->
    self = this

    @headers = (request) ->
        headers = request.headers

        auth = null
        if headers['Authorization']
            auth = @auth request, headers['Authorization']
            if auth
                delete headers['Authorization']

        return {
            "has_headers": Object.keys(headers).length > 0
            "header_list": ({
                "header_name": addslashes header_name
                "header_value": addslashes header_value
            } for header_name, header_value of headers)
            "auth": auth
        }

    @auth = (request, authHeader) ->
        if self.options.useHeader
            return null
        match = authHeader.match(/([^\s]+)\s(.*)/) || []
        scheme = match[1] || null
        params = match[2] || null


        if scheme == 'Basic'
            decoded = Base64.atob(params)
            userpass = decoded.match(/([^:]*):?(.*)/)

            return {
                "username": userpass[1] || '',
                "password": userpass[2] || ''
            }

        digestDS = request.getHeaderByName('Authorization', true)
        if digestDS and digestDS.length == 1 and digestDS.getComponentAtIndex(0).type == 'com.luckymarmot.PawExtensions.DigestAuthDynamicValue'
            digestDV = digestDS.getComponentAtIndex(0)
            DVuser = digestDV.username
            username = ''
            if typeof DVuser == 'object'
                username = DVuser.getEvaluatedString()
            else
                username = DVuser
            DVpass = digestDV.password
            password = ''
            if typeof DVpass == 'object'
                password = DVpass.getEvaluatedString()
            else
                password = DVpass

            return {
                "isDigest": true,
                "username": username,
                "password": password
            }

        return null


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

    @generateRequest = (request) ->
        view =
            "request": request
            "headers": @headers request
            "body": @body request

        # Make multi-line description.
        if view.request.description
            view.request.cURLDescription = view.request.description.split('\n').map((line, index) ->
              return "# #{line}"
            ).join('\n')
        else
            view.request.cURLDescription = ''

        template = readFile "curl.mustache"
        rendered_code = Mustache.render template, view
        return @strip_last_backslash rendered_code

    @generate = (context, requests, options) ->
        self.options = (options || {}).inputs || {}

        curls = requests.map((request) ->
            return self.generateRequest(request)
        )

        return curls.join('\n')

    return


cURLCodeGenerator.identifier =
    "com.luckymarmot.PawExtensions.cURLCodeGenerator"
cURLCodeGenerator.title =
    "cURL"
cURLCodeGenerator.fileExtension = "sh"
cURLCodeGenerator.languageHighlighter = "bash"
cURLCodeGenerator.inputs = [
    new InputField("useHeader", "do not use -u option", "Checkbox", {defaultValue: false})
]

registerCodeGenerator cURLCodeGenerator
