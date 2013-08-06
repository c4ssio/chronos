require 'capistrano/ext/multistage'
#Uncomment to set a gateway
set :application, "chronos"
set :repository,  "git@github.com:airbnb/chronos.git"
set :ssh_options, {:keys=> [ENV['EC2_PRIVATE_KEY']]}
#user and application named the same thing for deploy
set :scm, :git
set :stages, ['debian','fedora']
set :mesos_version, "0.12.0"
set :maven_version, "3.0.5"
set :chronos_branch, "master"
set :chronos_port, "4400"

namespace :install do
  desc "install all requirements"
  task :all do
    install_pkgs
    add_java_home
    install_maven
    install_mesos
    install_chronos
    start_chronos
    redirect_port
  end

  desc "install maven and add to shared path"
  task :install_maven do
    maven_wget_path = "http://mirrors.gigenet.com/apache/maven/maven-3/#{maven_version}" +
                      "/binaries/apache-maven-#{maven_version}-bin.tar.gz"
    run "wget #{maven_wget_path}"
    sudo %{su -c "tar -zxvf apache-maven-#{maven_version}-bin.tar.gz -C /opt/"}
    maven_sh = <<-end_of_maven_sh
                  export M2_HOME=/opt/apache-maven-#{maven_version}
                  export M2=$M2_HOME/bin
                  PATH=$M2:$PATH
                  end_of_maven_sh
    put_path = "/home/#{user}/maven.sh"
    maven_sh_path = "/etc/profile.d/maven.sh"
    put maven_sh, put_path
    sudo "mv #{put_path} #{maven_sh_path}"
  end

  desc "install mesos"
  task :install_mesos do
    run "rm -rf mesos && git clone https://github.com/apache/mesos.git && " +
        "cd mesos && git checkout #{mesos_version} && " +
        "./bootstrap && ./configure --with-webui --with-included-zookeeper --disable-perftools && " +
        "make && sudo make install"
  end

  desc "install chronos"
  task :install_chronos do
    chronos_sh = "export MESOS_NATIVE_LIBRARY=/usr/local/lib/libmesos.so"
    put_path = "/home/#{user}/chronos.sh"
    chronos_sh_path = "/etc/profile.d/chronos.sh"
    put chronos_sh, put_path
    sudo "mv #{put_path} #{chronos_sh_path}"
    run "rm -rf chronos && rm -rf .m2 && git clone https://github.com/airbnb/chronos.git && " +
        "cd chronos && git checkout #{chronos_branch} && " +
        "mvn -X clean package",:shell => "/bin/bash --login"
  end

  desc "start chronos"
  task :start_chronos do
  #kill any running airbnb processes
  run "ps aux | grep airbnb | awk '{print $2}' | head -n -1 > chronos_pids", :shell => "/bin/bash --login"
  run "(cat chronos_pids | xargs kill -9) || true", :shell => "/bin/bash --login"
  #make sure there's a log folder
  run "cd chronos && mkdir -p log"
  #make a file to run nohup on
  put "cd chronos && " +
      "java -cp target/chronos*.jar com.airbnb.scheduler.Main server config/local_scheduler_nozk.yml",
      "start_chronos.sh"
  #run nohup
  run "nohup sh start_chronos.sh" +
      "> chronos/log/chronos.log 2> chronos/log/chronos.err &",:shell => "/bin/bash --login"

  end

  desc "redirect ip_tables port 4400 to 80"
  task :redirect_port do
    sudo "iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port #{chronos_port}"
  end
end
