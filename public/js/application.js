// Главная функция инициализации
document.addEventListener('DOMContentLoaded', function() {
  // Инициализация обработчиков для кнопок коек
  initBedButtons();

  //   // Инициализация всех модальных окон Bootstrap
  // document.querySelectorAll('.modal').forEach(modalEl => {
  //   new bootstrap.Modal(modalEl);
    
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
  const btn = e.currentTarget;
  const originalHtml = btn.innerHTML;
  
  try {
    // Показываем загрузку сразу
    btn.innerHTML = '<span class="spinner-border spinner-border-sm"></span>';
    btn.disabled = true;
    
    const bedCard = btn.closest('.bed-card');
    const date = bedCard.dataset.date;
    const bedIndex = bedCard.querySelector('.card-title').textContent.match(/\d+/)[0];
    const isOccupied = bedCard.classList.contains('occupied-card');
    
    const formData = new FormData();
    formData.append('date', date);
    formData.append('bed_index', bedIndex);
    
    if (isOccupied) {
      // Запрашиваем подтверждение через кастомное модальное окно
      const confirmed = await showCustomConfirm(
        'Подтвердите действие',
        'Вы действительно хотите освободить койку?'
      );
      
      if (!confirmed) {
        btn.innerHTML = originalHtml;
        btn.disabled = false;
        return;
      }
      
      formData.append('patient_name', '');
      formData.append('diagnosis', '');
    } else {
      const patientName = bedCard.querySelector('.patient-input').value.trim();
      const diagnosis = bedCard.querySelector('.diagnosis-input').value.trim();
      
      if (!patientName) {
        showAlert('Ошибка', 'Пожалуйста, введите имя пациента');
        btn.innerHTML = originalHtml;
        btn.disabled = false;
        return;
      }
      
      formData.append('patient_name', patientName);
      formData.append('diagnosis', diagnosis);
    }
    
    // Отправка данных
    const response = await fetch('/occupy', {
      method: 'POST',
      body: formData
    });
    
    if (response.ok) {
      window.location.reload();
    } else {
      throw new Error('Ошибка сервера');
    }
  } catch (error) {
    console.error('Error:', error);
    showAlert('Ошибка', 'Не удалось выполнить действие');
    btn.innerHTML = originalHtml;
    btn.disabled = false;
  }
}

function showCustomConfirm(title, message) {
  return new Promise((resolve) => {
    const modal = new bootstrap.Modal('#confirmModal');
    const modalEl = document.getElementById('confirmModal');
    
    // Анимация появления
    modalEl.querySelector('.modal-content').style.transform = 'translateY(20px)';
    modalEl.querySelector('.modal-content').style.opacity = '0';
    
    // Настройка контента
    modalEl.querySelector('.modal-title').innerHTML = `<i class="bi bi-question-circle me-2"></i>${title}`;
    modalEl.querySelector('#confirmMessage').textContent = message;
    
    // Очистка предыдущих обработчиков
    const confirmBtn = modalEl.querySelector('#confirmBtn');
    const cancelBtn = modalEl.querySelector('#cancelBtn');
    
    const cleanUp = () => {
      confirmBtn.onclick = null;
      cancelBtn.onclick = null;
    };
    
    // Новые обработчики
    confirmBtn.onclick = () => {
      modal.hide();
      cleanUp();
      resolve(true);
    };
    
    cancelBtn.onclick = () => {
      modal.hide();
      cleanUp();
      resolve(false);
    };
    
    // Показываем модальное окно с анимацией
    modal.show();
    
    // Анимация появления
    setTimeout(() => {
      modalEl.querySelector('.modal-content').style.transform = 'translateY(0)';
      modalEl.querySelector('.modal-content').style.opacity = '1';
      modalEl.querySelector('.modal-content').style.transition = 'all 0.3s ease-out';
    }, 10);
  });
}

// Функция показа уведомления
function showAlert(title, message) {
  const modal = new bootstrap.Modal('#confirmModal');
  const modalEl = document.getElementById('confirmModal');
  
  // Настраиваем для alert
  modalEl.querySelector('.modal-header').className = 'modal-header bg-warning text-dark';
  modalEl.querySelector('.modal-title').textContent = title;
  modalEl.querySelector('#confirmMessage').textContent = message;
  modalEl.querySelector('#confirmBtn').textContent = 'OK';
  modalEl.querySelector('#cancelBtn').style.display = 'none';
  
  const confirmBtn = modalEl.querySelector('#confirmBtn');
  confirmBtn.onclick = () => {
    modal.hide();
    // Возвращаем исходные настройки
    modalEl.querySelector('.modal-header').className = 'modal-header bg-danger text-white';
    modalEl.querySelector('#confirmBtn').textContent = 'Освободить';
    modalEl.querySelector('#cancelBtn').style.display = 'block';
  };
  
  modal.show();
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