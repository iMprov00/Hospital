// Главная функция инициализации
document.addEventListener('DOMContentLoaded', function() {
  // Инициализация обработчиков для кнопок коек
  initBedButtons();
  
  // Инициализация Flatpickr с подсветкой занятых дат
  initDatePicker();
});

function initBedButtons() {
  document.querySelectorAll('.toggle-btn').forEach(btn => {
    btn.addEventListener('click', handleBedToggle);
  });
}

async function handleBedToggle(e) {
  e.preventDefault();
  
  const bedCard = e.target.closest('.bed-card');
  const date = bedCard.dataset.date;
  const bedIndex = bedCard.querySelector('.card-title').textContent.match(/\d+/)[0];
  const isOccupied = bedCard.classList.contains('occupied-card');
  
  // Добавляем подтверждение для освобождения койки
  if (isOccupied) {
    const confirmRelease = confirm("Освободить койку?");
    if (!confirmRelease) {
      return; // Отмена действия
    }
  }
  
  // Показываем индикатор загрузки
  const btn = e.target;
  const originalText = btn.innerHTML;
  btn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>';
  btn.disabled = true;
  
  const formData = new FormData();
  formData.append('date', date);
  formData.append('bed_index', bedIndex);
  
  if (isOccupied) {
    formData.append('patient_name', '');
    formData.append('diagnosis', '');
  } else {
    const patientName = bedCard.querySelector('.patient-input').value || '';
    const diagnosis = bedCard.querySelector('.diagnosis-input').value || '';
    
    if (!patientName.trim()) {
      alert('Пожалуйста, введите имя пациента');
      btn.innerHTML = originalText;
      btn.disabled = false;
      return;
    }
    
    formData.append('patient_name', patientName);
    formData.append('diagnosis', diagnosis);
  }
  
  try {
    const response = await fetch('/occupy', {
      method: 'POST',
      body: formData
    });
    
    if (response.ok) {
      window.location.reload();
    }
  } catch (error) {
    console.error('Ошибка:', error);
    alert('Произошла ошибка при сохранении данных');
  } finally {
    btn.innerHTML = originalText;
    btn.disabled = false;
  }
}
async function initDatePicker() {
  const datePicker = document.getElementById('date-picker');
  if (!datePicker) return;

  let occupiedDates = [];
  try {
    const response = await fetch('/occupied_dates');
    occupiedDates = await response.json();
  } catch (error) {
    console.error('Ошибка при загрузке занятых дат:', error);
  }

  const flatpickrInstance = flatpickr(datePicker, {
    locale: "ru",
    dateFormat: "d.m.Y", // Новый формат дд.мм.гггг
    allowInput: true,
    defaultDate: datePicker.value,
    onChange: function(selectedDates, dateStr, instance) {
      document.getElementById('date-form').submit();
    },
    onDayCreate: function(dObj, dStr, fp, dayElem) {
      const date = flatpickr.formatDate(dayElem.dateObj, "Y-m-d");
      if (occupiedDates.includes(date)) {
        dayElem.style.backgroundColor = "#ffdddd";
        dayElem.style.color = "#cc0000";
        dayElem.style.fontWeight = "bold";
      }
    }
  });
}