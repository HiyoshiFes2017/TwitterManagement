set :output, 'log/cron.log'

every :hour do
  command "ls"
end

# 1時間毎に実行
every 1.hour do
  command "ls"
end

# 3分毎に実行(crontabと記述方法を合わせる)
every '*/3 * * * *' do
  command "ls"
end
