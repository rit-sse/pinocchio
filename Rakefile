namespace :server do

  task :start do
    if File.exists?('tmp/pids/unicorn.pid')
      pid = File.read('tmp/pids/unicorn.pid').to_i
      Process.kill("HUP", pid)
      puts 'Restarted the server'
    else
      puts 'Not running, starting the server...'
      sh 'unicorn -c config/unicorn.rb -E production -D'
    end
  end

  task :stop do
    if File.exists?('tmp/pids/unicorn.pid')
      pid = File.read('tmp/pids/unicorn.pid').to_i
      Process.kill("QUIT", pid)
      puts 'Stopped the server'
    else
      puts 'Server already down'
    end
  end

end