set :user, ENV['EC2_DEBIAN_ROOT']
role :app, ENV['EC2_DEBIAN_DNS']
namespace :install do
  desc "install pkgs"
  task :install_pkgs do
    #install yums
    sudo 'apt-get update'
    sudo 'apt-get install -y autoconf make build-essential gcc cpp patch python-dev git libtool openjdk-7-jdk gzip libghc-zlib-dev libcurl4-openssl-dev'
  end
  desc "create file that sets java home for all users"
  task :add_java_home do
    java_sh = "export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-amd64/"
    put_path = "/home/#{user}/java.sh"
    java_sh_path = "/etc/profile.d/java.sh"
    put java_sh, put_path
    sudo "mv #{put_path} #{java_sh_path}"
  end
end
