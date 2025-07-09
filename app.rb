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
    bed.update!(
      patient_name: params[:patient_name],
      occupied: !params[:patient_name].empty?
    )
  end
  
  redirect "/?date=#{date}"
end

helpers do
  def load_or_initialize_beds(date)
    beds = BedDay.where(date: date).index_by(&:bed_index)
    
    (1..20).map do |idx|
      beds[idx] || BedDay.new(date: date, bed_index: idx, occupied: false)
    end
  end
end
