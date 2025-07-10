
require 'rubygems'          # Подключение RubyGems для управления зависимостями
require 'sinatra'           # Подключение фреймворка Sinatra
require 'sinatra/reloader'  # Подключение модуля перезагрузки для разработки
require 'sinatra/activerecord'  # Подключение ActiveRecord для работы с БД

require_relative 'models/bed_day'  # Подключение модели BedDay

set :database, {adapter: "sqlite3", database: "db/hospital.db"}  # Настройка подключения к SQLite БД

get '/' do    # Обработчик GET-запроса для главной страницы
  @target_date = params[:date] ? Date.parse(params[:date]) : Date.today  # Получение даты из параметров или текущей даты
  @beds = load_or_initialize_beds(@target_date)  # Загрузка или инициализация данных о койках
  erb :index    # Рендеринг шаблона index.erb
end

post '/occupy' do    # Обработчик POST-запроса для изменения статуса койки
  date = Date.parse(params[:date])    # Парсинг даты из параметров
  bed = BedDay.find_or_initialize_by(date: date, bed_index: params[:bed_index].to_i)  # Поиск или создание записи о койке
  
  if params[:patient_name].empty?    # Проверка на пустое имя пациента (освобождение койки)
    bed.destroy if bed.persisted?    # Удаление записи, если она существует в БД
  else
    # Разбиваем диагноз на код и название (если введено через пробел)
    diagnosis_parts = params[:diagnosis].to_s.split(' ', 2)    # Разделение диагноза на код и название
    
    bed.update!(    # Обновление данных о койке
      patient_name: params[:patient_name],    # Имя пациента
      diagnosis_code: diagnosis_parts[0],     # Код диагноза
      diagnosis_name: diagnosis_parts[1] || '',  # Название диагноза (или пустая строка)
      occupied: true    # Флаг занятости
    )
  end
  
  redirect "/?date=#{date}"    # Перенаправление на главную с текущей датой
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

helpers do    # Блок вспомогательных методов
  def load_or_initialize_beds(date)    # Метод загрузки или инициализации коек
    beds = BedDay.where(date: date).index_by(&:bed_index)  # Получение всех коек за дату и индексация
    
    (1..18).map do |idx|    # Цикл по 18 койкам (изменили на 18)
      beds[idx] || BedDay.new(date: date, bed_index: idx, occupied: false)  # Существующая койка или новая
    end
  end
end