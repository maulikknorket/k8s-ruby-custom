require 'net/http'
require 'uri'
require 'openssl'
require 'json'

require_relative 'generic'

module Restores
    include Generic

    # Create new Restore
    def create_new_restore(namespace, config)
        extension = "/apis/velero.io/v1/namespaces/#{namespace}/restores"

        uri = prepareURI(@endpoint, extension)

        request = prepareGenericRequest(uri, @bearer_token,  "POST")
        request.content_type = "application/json"

        if @yaml
            request.body = yaml_file_to_json(config)
        else
            request.body = config
        end

        req_options = prepareGenericRequestOptions(@ssl, uri)

        begin
            response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
                http.request(request)
            end
            return response

        rescue Errno::ECONNREFUSED
            raise "Connection for host #{uri.hostname} refused"
        end
    end

    # Get single namespaced restore
    def get_single_namespaced_restore(namespace, restore_name)
        extension = "/apis/velero.io/v1/namespaces/#{namespace}/restores/#{restore_name}"

        uri = prepareURI(@endpoint, extension)

        request = prepareGenericRequest(uri, @bearer_token, "GET")

        req_options = prepareGenericRequestOptions(@ssl, uri)

        begin
            response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
                http.request(request)
            end
            return response
        rescue Errno::ECONNREFUSED
            raise "Connection for host #{uri.hostname} refused"
        end
    end

    # Delete single namespaced restore
    def delete_namespaced_restore(namespace, restore_name)
        extension = "/apis/velero.io/v1/namespaces/#{namespace}/restores/#{restore_name}"

        uri = prepareURI(@endpoint, extension)

        request = prepareGenericRequest(uri, @bearer_token, "DELETE")

        req_options = prepareGenericRequestOptions(@ssl, uri)

        begin
            response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
                http.request(request)
            end
            return response
        rescue Errno::ECONNREFUSED
            raise "Connection for host #{uri.hostname} refused"
        end
    end
end
