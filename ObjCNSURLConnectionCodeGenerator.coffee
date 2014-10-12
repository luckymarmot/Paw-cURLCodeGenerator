require "mustache.js"

ObjCNSURLConnectionCodeGenerator = ->

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
                "json_body":json_body
                "json_body_object":@json_body_object json_body
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
            "headers": @headers request
            "body": @body request

        template = readFile "objc.mustache"
        Mustache.render template, view

    return


ObjCNSURLConnectionCodeGenerator.identifier = "com.luckymarmot.PawExtensions.ObjCNSURLConnectionCodeGenerator";
ObjCNSURLConnectionCodeGenerator.title = "Objective-C (NSURLConnection)";

registerCodeGenerator ObjCNSURLConnectionCodeGenerator
