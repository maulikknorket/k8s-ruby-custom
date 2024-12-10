# Ruby Kubernetes Controller

[![CircleCI](https://circleci.com/gh/IBM/ruby-kubernetes-controller.svg?style=svg)](https://circleci.com/gh/IBM/ruby-kubernetes-controller) [![Gem Version](https://badge.fury.io/rb/ruby-kubernetes-controller.svg)](https://badge.fury.io/rb/ruby-kubernetes-controller) [![RubyGems](https://img.shields.io/gem/dt/ruby-kubernetes-controller.svg?color=FF502A&label=gem%20downloads&style=popout)](https://rubygems.org/gems/ruby-kubernetes-controller) [![License](https://img.shields.io/github/license/ibm/ruby-kubernetes-controller.svg)](https://github.com/IBM/ruby-kubernetes-controller/blob/master/LICENSE.txt) 

`Ruby Kubernetes Controller` is a Client-Side library which allows users to 
interact with core Kubernetes APIs natively from within their 
Ruby applications. This library is compatible with all leading Kubernetes 
Instances, including OpenShift Kubernetes, Azure Kubernetes Service, 
Amazon EKS, Google Kubernetes Service, IBM Kubernetes Service, and Rancher 
Orchestrated Kubernetes. This library also supports yaml ingestion 
for creating, patching, updating, or deleting existing Kubernetes 
types, including Pods, Services, Deployments, Endpoints, and Ingresses. 
Our documentation also contains complete examples for all operation types.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby-kubernetes-controller'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ruby-kubernetes-controller

## Usage

#### For usage instructions please see our [Documentation][DOCUMENTATION]

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/IBM/ruby-kubernetes-controller][HOMEPAGE]. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Ruby Kubernetes Controller project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/rubykubernetescontroller/blob/master/CODE_OF_CONDUCT.md).

[HOMEPAGE]: https://github.com/IBM/ruby-kubernetes-controller
[DOCUMENTATION]: https://github.com/IBM/ruby-kubernetes-controller/blob/master/Documentation/DOCUMENTATION.md

## Example

```rb
# loading custom library for `ruby-kubernetes-controller`
# assumes the repo k8s-ruby exists at same level as this script
# 
# |__ k8s-ruby/
# |         |__ ...
# |__ steampipe.rb
$LOAD_PATH.unshift(File.expand_path('k8s-ruby/lib', __dir__))

require 'aws-sdk-ssm'
require 'base64'
require 'ruby-kubernetes-controller'

# #############################################################################
# Front End
# 1. first time: can't deploy steampipe, steampipe = false in batch job paramteers
# 2. after cluster created, have option to deploy steampipe in cluster, steampipe = true in batch job
# 3. after deploying steampipe, create catalog in front end and in trino
# 4. after deploying steampipe, give option to add connections to steampipe (this code)
# 5. to verify if connection exists, must run sql query to check if schema with name (from configmap) exists in steampipe
# 
# 
# Flow 
# 1. get clusterId
# 2. get k8 token from aws ssm
# 3. get k8 endpoint from aws ssm
# 4. create k8 client
# 5. delete configmap if it exists
# 6. delete pod if it exists
# 7. create configmap
# 8. create pod
# #############################################################################


# #############################################################################
# GET KUBERNETES ENDPOINT AND TOKEN FROM AWS SSM PARAMETER
# #############################################################################

clusterId = "441"

ssm_client = Aws::SSM::Client.new(region: 'ap-south-1')

# Method to get parameter from SSM
def get_parameter(ssm_client, parameter_name)
  response = ssm_client.get_parameter(
    name: parameter_name,
    with_decryption: true  # Set to true if the parameter is a SecureString
  )
  response.parameter.value
end

# Fetch the TOKEN
token_parameter_name = "/k8s/#{clusterId}/token"
TOKEN = get_parameter(ssm_client, token_parameter_name)

# Fetch and process the ENDPOINT
endpoint_parameter_name = "/k8s/#{clusterId}/endpoint"
ENDPOINT = get_parameter(ssm_client, endpoint_parameter_name).sub("https://", "")
puts ENDPOINT

# Fetch and decode the CA_CERT
cert_parameter_name = "/k8s/#{clusterId}/cert"
CA_CERT = Base64.decode64(get_parameter(ssm_client, cert_parameter_name))
puts CA_CERT


# #############################################################################
# CREATE K8 CLIENT
# #############################################################################
SSL = true
json_client  = ::RubyKubernetesController::Client.new(ENDPOINT, TOKEN, SSL, yaml = false, ca_cert = CA_CERT)

namespace = "fdw"

# #############################################################################
# DELETE CONFIGMAP IF IT EXISTS
# #############################################################################
puts json_client.delete_configmap(namespace, 'sql-executor-config', '{}') # Returns JSON


# #############################################################################
# DELETE POD IF IT EXISTS
# #############################################################################
puts json_client.delete_pod(namespace, 'psql-query-pod', '{}') # Returns JSON

# #############################################################################
# CREATE CONFIGMAP
# #############################################################################

# #####################
# connection type:
# connection name:
# operation:
# config options...
#######################


json_config = 
'{
  "apiVersion": "v1",
  "kind": "ConfigMap",
  "metadata": {
    "name": "sql-executor-config"
  },
  "data": {
    "CONNECTOR": "aws",
    "NAME": "aws123",
    "CONFIG": "secret_key=\"Jq2IIjbnY1jtJeheM1/QAqOeKeau2cpMkrO+SCVT\"\nregions=[\"*\"]\naccess_key=\"AKIAXISLP5YSI5IFIL2A\"",
    "OPERATION": "CREATE"
  }
}'

puts json_client.create_new_configmap(namespace, json_config) # Returns JSON
# #############################################################################
# CREATE POD
# #############################################################################

json_config = 
'{
  "apiVersion": "v1",
  "kind": "Pod",
  "metadata": {
    "name": "psql-query-pod",
    "namespace": "fdw"
  },
  "spec": {
    "serviceAccountName": "exec-job-sa",
    "containers": [
      {
        "name": "psql-query-container",
        "image": "nce26ltz.c1.bhs5.container-registry.ovh.net/cnpg_basic/manualfdwjob:15",
        "command": [
          "/bin/sh",
          "-c"
        ],
        "args": [
          "echo \"Starting connection to PostgreSQL database...\"\nsql_executor\n"
        ],
        "env": [
          {
            "name": "PGPASSWORD",
            "valueFrom": {
              "secretKeyRef": {
                "name": "postgres-admin",
                "key": "password"
              }
            }
          }
        ],
        "envFrom": [
          {
            "configMapRef": {
              "name": "sql-executor-config"
            }
          }
        ]
      }
    ],
    "imagePullSecrets": [
      {
        "name": "registry-credentials"
      }
    ],
    "restartPolicy": "Never"
  }
}
'   

puts json_client.create_new_pod(namespace, json_config) # Returns JSON
```