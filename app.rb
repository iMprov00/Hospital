require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/activerecord'

require_relative 'models/bed_day'

set :database, {adapter: "sqlite3", database: "db/hospital.db"}


get '/' do
  @target_date = params[:date] ? Date.parse(params[:date]) : Date.today
  @beds = load_or_initialize_beds(@target_date)
  erb :index
end

post '/occupy' do
  date = Date.parse(params[:date])
  bed = BedDay.find_or_initialize_by(date: date, bed_index: params[:bed_index].to_i)
  
  if params[:patient_name].empty?
    bed.destroy if bed.persisted?
  else
    # Разбиваем диагноз на код и название (если введено через пробел)
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

helpers do
  def load_or_initialize_beds(date)
    beds = BedDay.where(date: date).index_by(&:bed_index)
    
    (1..18).map do |idx| # Изменили на 18
      beds[idx] || BedDay.new(date: date, bed_index: idx, occupied: false)
    end
  end
end
