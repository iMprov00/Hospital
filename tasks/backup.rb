require 'fileutils'
require 'date'

# Конфигурация
DB_PATH = 'db/hospital.db'
BACKUP_DIR = 'db/backups'
CLOUD_DIR = 'path/to/cloud/storage' # Укажите реальный путь
KEEP_DAILY = 7
KEEP_MONTHLY = 3

# Создаем папки если нужно
FileUtils.mkdir_p(BACKUP_DIR)
FileUtils.mkdir_p(CLOUD_DIR) if CLOUD_DIR

# Генерируем имя файла с датой
timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
backup_file = "#{BACKUP_DIR}/hospital_backup_#{timestamp}.db"

# Копируем базу данных
FileUtils.cp(DB_PATH, backup_file)

# Копируем в облако
if CLOUD_DIR
  cloud_file = "#{CLOUD_DIR}/hospital_backup_#{timestamp}.db"
  FileUtils.cp(backup_file, cloud_file)
end

# Очистка старых бэкапов
puts "Cleaning up old backups..."

# Удаляем дневные бэкапы старше KEEP_DAILY дней
daily_backups = Dir.glob("#{BACKUP_DIR}/hospital_backup_*.db").sort
if daily_backups.size > KEEP_DAILY
  (0...daily_backups.size - KEEP_DAILY).each do |i|
    File.delete(daily_backups[i])
    puts "Deleted old daily backup: #{daily_backups[i]}"
  end
end

# Сохраняем месячные бэкапы (первый день месяца)
if Date.today.day == 1
  monthly_backup = "#{BACKUP_DIR}/hospital_monthly_#{Date.today.strftime('%Y%m')}.db"
  FileUtils.cp(DB_PATH, monthly_backup)
  
  # Удаляем старые месячные бэкапы
  monthly_backups = Dir.glob("#{BACKUP_DIR}/hospital_monthly_*.db").sort
  if monthly_backups.size > KEEP_MONTHLY
    (0...monthly_backups.size - KEEP_MONTHLY).each do |i|
      File.delete(monthly_backups[i])
      puts "Deleted old monthly backup: #{monthly_backups[i]}"
    end
  end
end

puts "Backup completed successfully: #{backup_file}"