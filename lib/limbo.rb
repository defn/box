shome=File.expand_path("..", __FILE__)

docker_script = "#{shome}/script/docker-bootstrap"
docker_args = [ ENV['BASEBOX_DOCKER_NETWORK_PREFIX'] ]

block_script = %x{which block-cibuild 2>/dev/null}.chomp
block_args = [ ENV['BASEBOX_HOME_URL'] ]
%w(http_proxy ssh_gateway ssh_gateway_user).each {|ele|
  unless ENV[ele].nil? || ENV[ele].empty?
    block_args << ENV[ele]
  else
    break
  end
}

facts_script = "#{shome}/script/facts-finish"
facts_args = [ ]

if ENV['ssh_gateway_user'].nil? || ENV['ssh_gateway_user'].empty?
  block_args << ENV['USER']
end

if ENV['VAGRANT_DEFAULT_PROVIDER'] == "aws"
  threads = []
  threads << Thread.new do aws_region = ENV['AWS_DEFAULT_REGION'] || %x{aws configure get region}.chomp; end
  threads << Thread.new do aws_access_key_id = ENV['AWS_ACCESS_KEY_ID'] || %x{aws configure get aws_access_key_id}.chomp; end
  threads << Thread.new do aws_secret_access_key= ENV['AWS_SECRET_ACCESS_KEY'] || %x{aws configure get aws_secret_access_key}.chomp; end

  threads.map(&:join)
end
