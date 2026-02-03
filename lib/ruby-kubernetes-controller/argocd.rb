require 'net/http'
require 'uri'
require 'openssl'
require 'json'

require_relative 'generic'

module Argocd
  include Generic

  # Get all applications in a namespace
  def get_namespaced_applications(namespace)
      extension = "/apis/argoproj.io/v1alpha1/namespaces/#{namespace}/applications"

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

  # Get single namespaced application
  def get_single_namespaced_application(namespace, app_name)
      extension = "/apis/argoproj.io/v1alpha1/namespaces/#{namespace}/applications/#{app_name}"

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
end
