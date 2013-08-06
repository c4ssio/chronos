set :user, ENV['EC2_FEDORA_ROOT']
role :app, ENV['EC2_FEDORA_DNS']
default_run_options[:pty] = true
namespace :install do
  desc "install pkgs"
  task :install_pkgs do
    #install yums
    sudo 'yum -y update'
    sudo 'yum install -y autoconf make gcc gcc-c++ patch python-devel git libtool java-1.7.0-openjdk-devel zlib-devel libcurl-devel openssl-devel'
  end
  desc "create file that sets java home for all users"
  task :add_java_home do
    java_sh = "export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.25.x86_64/"
    put_path = "/home/#{user}/java.sh"
    java_sh_path = "/etc/profile.d/java.sh"
    put java_sh, put_path
    sudo "mv #{put_path} #{java_sh_path}"
  end
end
