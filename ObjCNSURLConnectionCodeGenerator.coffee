require "mustache.js"
require "URI.js"

ObjCNSURLConnectionCodeGenerator = ->

    @url = (request) ->
        url_params_object = (() ->
            _uri = URI request.url
            _uri.search true
        )()
        url_params = ({
            "name":name
            "value":value
        } for name, value of url_params_object)
        
        return {
            "base": (() ->
                _uri = URI request.url
                _uri.search("")
                _uri
            )()
            "params":url_params
            "has_params":url_params.length > 0
        }

    @headers = (request) ->
        headers = request.headers
        return {
            "has_headers": Object.keys(headers).length > 0
            "header_list": ({
                "header_name": header_name,
                "header_value": header_value
            } for header_name, header_value of headers)
        }

    @body = (request) ->
        json_body = request.jsonBody
        if json_body
            return {
                "has_json_body":true
                "json_body_object":@json_body_object json_body
            }
            
        url_encoded_body = request.urlEncodedBody
        if url_encoded_body
            return {
                "has_url_encoded_body":true
                "url_encoded_body": ({
                    "name": name
                    "value": value
                } for name, value of url_encoded_body)
            }
        
        raw_body = request.body
        if raw_body
            if raw_body.length < 10000
                return {
                    "has_raw_body":true
                    "raw_body": raw_body
                }
            else
                return {
                    "has_long_body":true
                }

    @json_body_object = (object, indent = 0) ->
        if object == null
            s = "[NSNull null]"
        else if typeof(object) == 'string'
            s = "@\"#{object}\""
        else if typeof(object) == 'number'
            s = "@#{object}"
        else if typeof(object) == 'boolean'
            s = "@#{if object then "YES" else "NO"}"
        else if typeof(object) == 'object'
            indent_str = Array(indent + 1).join('\t')
            indent_str_children = Array(indent + 2).join('\t')
            if object.length?
                s = "@[\n" +
                    ("#{indent_str_children}#{@json_body_object(value, indent+1)}" for value in object).join(',\n') +
                    "\n#{indent_str}]"
            else
                s = "@{\n" +
                    ("#{indent_str_children}@\"#{key}\": #{@json_body_object(value, indent+1)}" for key, value of object).join(',\n') +
                    "\n#{indent_str}}"

        if indent is 0
            if typeof(object) == 'object'
                # NSArray
                if object.length?
                    s = "NSArray* bodyObject = #{s};"
                # NSDictionary
                else
                    s = "NSDictionary* bodyObject = #{s};"
            else
                s = "id bodyObject = #{s};"

        return s

    @generate = (context) ->
        request = context.getCurrentRequest()

        view =
            "request": context.getCurrentRequest()
            "url": @url request
            "headers": @headers request
            "body": @body request

        if view.url.has_params or (view.body and view.body.has_url_encoded_body)
            view["has_utils_query_string"] = true

        template = readFile "objc.mustache"
        Mustache.render template, view

    return


ObjCNSURLConnectionCodeGenerator.identifier =
    "com.luckymarmot.PawExtensions.ObjCNSURLConnectionCodeGenerator";
ObjCNSURLConnectionCodeGenerator.title =
    "Objective-C (NSURLConnection)";

registerCodeGenerator ObjCNSURLConnectionCodeGenerator
