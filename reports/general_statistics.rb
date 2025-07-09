module Reports
  class GeneralStatistics
    def self.generate(date_from, date_to)
      total_beds = 18 # Общее количество коек
      total_days = (date_to - date_from).to_i + 1
      
      # Получаем данные по занятым койкам
      occupied_days = BedDay.where(date: date_from..date_to)
                          .group(:date)
                          .count
      
      # Создаем записи для ВСЕХ дней периода
      stats = (date_from..date_to).map do |date|
        occupied = occupied_days[date] || 0 # 0 если нет записей за этот день
        {
          date: date,
          occupied: occupied,
          free: total_beds - occupied,
          occupancy_rate: (occupied.to_f / total_beds * 100).round(2)
        }
      end
      
      # Рассчитываем общую статистику
      total_occupied = stats.sum { |s| s[:occupied] }
      total_free = total_beds * total_days - total_occupied # Общее количество свободных коек за весь период
      average_occupied = (total_occupied.to_f / total_days).round(2)

      {
        title: "Общая статистика по госпитализациям",
        period: "#{date_from.to_s} - #{date_to.to_s}",
        total_days: total_days,
        total_occupied: total_occupied,
        total_free: total_free,
        average_occupied: average_occupied,
        stats: stats.sort_by { |day| day[:date] } # Сортируем по дате
      }
    end
  end
end