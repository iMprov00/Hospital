
require 'rubygems'          # Подключение RubyGems для управления зависимостями
require 'sinatra'           # Подключение фреймворка Sinatra
require 'sinatra/reloader'  # Подключение модуля перезагрузки для разработки
require 'sinatra/activerecord'  # Подключение ActiveRecord для работы с БД
# require 'axlsx'

require_relative 'models/bed_day'  # Подключение модели BedDay

set :database, {adapter: "sqlite3", database: "db/hospital.db"}  # Настройка подключения к SQLite БД

get '/' do    # Обработчик GET-запроса для главной страницы
  @target_date = params[:date] ? Date.parse(params[:date]) : Date.today  # Получение даты из параметров или текущей даты
  @beds = load_or_initialize_beds(@target_date)  # Загрузка или инициализация данных о койках
  erb :index    # Рендеринг шаблона index.erb
end

post '/occupy' do
  date = Date.parse(params[:date])
  bed_index = params[:bed_index].to_i
  
  # Проверяем, не занята ли уже койка другим пользователем
  existing_bed = BedDay.find_by(date: date, bed_index: bed_index)
  
  if existing_bed && existing_bed.occupied? && !params[:patient_name].empty?
    # Возвращаем специальный статус и сообщение
    status 409
    return "КОЙКА_ЗАНЯТА:#{bed_index}" # Добавляем номер койки в сообщение
  end

  # Остальной код обработчика остается без изменений
  bed = BedDay.find_or_initialize_by(date: date, bed_index: bed_index)
  
  if params[:patient_name].empty?
    bed.destroy if bed.persisted?
  else
    diagnosis_parts = params[:diagnosis].to_s.split(' ', 2)
    
    bed.update!(
      patient_name: params[:patient_name],
      diagnosis_code: diagnosis_parts[0],
      diagnosis_name: diagnosis_parts[1] || '',
      occupied: true
    )
  end
  
  redirect "/?date=#{date}"
end

# Эндпоинт для получения занятых дат
get '/occupied_dates' do
  content_type :json
  
  # Получаем даты, где все 18 коек заняты
  occupied_dates = BedDay.select(:date)
                         .group(:date)
                         .having('COUNT(*) = ?', 18)
                         .pluck(:date)
                         .map { |d| d.to_s }
  
  occupied_dates.to_json
end

get '/reports' do
  erb :reports  # Это будет рендерить views/reports.erb
end

get '/reports/general_stats' do
  content_type :json
  
  start_date = Date.parse(params[:start_date]) if params[:start_date]
  end_date = Date.parse(params[:end_date]) if params[:end_date]
  
  # Если даты не указаны, берем последние 30 дней
  end_date ||= Date.today
  start_date ||= end_date - 30.days
  
  # Получаем все даты в диапазоне (включая пустые)
  all_dates = (start_date..end_date).to_a
  
  # Получаем данные из БД
  beds_data = BedDay.where(date: start_date..end_date)
                   .group(:date)
                   .count
  
  # Формируем данные для таблицы
  table_data = all_dates.map do |date|
    occupied = beds_data[date] || 0
    percentage = (occupied.to_f / 18 * 100).round(1)
    
    {
      date: date.strftime('%d.%m.%Y'),
      occupied: occupied,
      percentage: percentage
    }
  end
  
  # Общая статистика
  total_days = all_dates.size
  total_occupied = beds_data.values.sum
  total_possible = total_days * 18
  avg_occupancy = (total_occupied.to_f / total_possible * 100).round(1)
  
  {
    stats: {
      total_occupied: total_occupied,
      total_free: total_possible - total_occupied,
      avg_occupancy: avg_occupancy
    },
    table_data: table_data
  }.to_json
end

get '/reports/export_excel' do
  content_type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  headers['Content-Disposition'] = 'attachment; filename=hospital_report.xlsx'
  
  start_date = Date.parse(params[:start_date]) if params[:start_date]
  end_date = Date.parse(params[:end_date]) if params[:end_date]
  
  end_date ||= Date.today
  start_date ||= end_date - 30.days
  
  all_dates = (start_date..end_date).to_a
  beds_data = BedDay.where(date: start_date..end_date)
                   .group(:date)
                   .count
  
  # Создаем Excel файл
  p = Axlsx::Package.new
  wb = p.workbook
  
  # Добавляем стили
  styles = wb.styles
  header_style = styles.add_style(b: true, bg_color: '54C654', fg_color: 'FFFFFF', alignment: { horizontal: :center })
  percent_style = styles.add_style(format_code: '0.0%')
  
  # Лист с общей статистикой
  wb.add_worksheet(name: 'Общая статистика') do |sheet|
    sheet.add_row ['Отчет по занятости коек', '', ''], style: header_style
    sheet.add_row ["Период: с #{start_date.strftime('%d.%m.%Y')} по #{end_date.strftime('%d.%m.%Y')}", '', '']
    sheet.add_row []
    
    total_days = all_dates.size
    total_occupied = beds_data.values.sum
    total_possible = total_days * 18
    avg_occupancy = (total_occupied.to_f / total_possible)
    
    sheet.add_row ['Метрика', 'Значение', ''], style: header_style
    sheet.add_row ['Всего занято коек', total_occupied]
    sheet.add_row ['Всего свободно коек', total_possible - total_occupied]
    sheet.add_row ['Средняя занятость', avg_occupancy, percent_style]
  end
  
  # Лист с ежедневной статистикой
  wb.add_worksheet(name: 'Ежедневная статистика') do |sheet|
    sheet.add_row ['Дата', 'Занято коек', 'Процент занятости'], style: header_style
    
    all_dates.each do |date|
      occupied = beds_data[date] || 0
      percentage = occupied.to_f / 18
      
      sheet.add_row [
        date.strftime('%d.%m.%Y'),
        occupied,
        percentage
      ], types: [:string, :integer, :float], style: [nil, nil, percent_style]
    end
  end
  
  p.to_stream.read
end

# Маршрут для управления бэкапами
get '/admin/backups' do

  
  @daily_backups = Dir.glob('db/backups/hospital_backup_*.db').sort.reverse
  @monthly_backups = Dir.glob('db/backups/hospital_monthly_*.db').sort.reverse
  
  erb :backups
end

# Маршрут для скачивания бэкапа
get '/admin/download_backup' do

  
  file = params[:file]
  path = File.join('db/backups', file)
  
  if File.exist?(path)
    send_file path, filename: file, type: 'Application/octet-stream'
  else
    status 404
    "Backup not found"
  end
end

# Маршрут для ручного создания бэкапа
post '/admin/create_backup' do

  
  # Запускаем скрипт бэкапа
  result = `ruby tasks/backup.rb 2>&1`
  
  content_type :text
  "Backup created successfully!\n#{result}"
end

get '/check_bed' do
  content_type :json
  
  date = Date.parse(params[:date])
  bed_index = params[:bed_index].to_i
  
  bed = BedDay.find_by(date: date, bed_index: bed_index)
  
  {
    occupied: bed&.occupied? || false,
    patient_name: bed&.patient_name || '',
    diagnosis: [bed&.diagnosis_code, bed&.diagnosis_name].compact.join(' ')
  }.to_json
end

get '/occupied_list' do
  @target_date = params[:date] ? Date.parse(params[:date]) : Date.today
  @occupied_beds = BedDay.where(date: @target_date, occupied: true).order(:bed_index)
  erb :occupied_list
end

before '/admin/*' do
  protected!
end

helpers do    # Блок вспомогательных методов
  def load_or_initialize_beds(date)    # Метод загрузки или инициализации коек
    beds = BedDay.where(date: date).index_by(&:bed_index)  # Получение всех коек за дату и индексация
    
    (1..18).map do |idx|    # Цикл по 18 койкам (изменили на 18)
      beds[idx] || BedDay.new(date: date, bed_index: idx, occupied: false)  # Существующая койка или новая
    end
  end

  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['admin', '123']
  end

end