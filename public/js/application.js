document.addEventListener('DOMContentLoaded', function() {
  // Инициализация обработчиков для кнопок коек
  if (document.querySelector('.toggle-btn')) {
    initBedButtons();
  }

  // Инициализация date picker в зависимости от страницы
  if (document.getElementById('date-picker')) {
    if (window.location.pathname === '/occupied_list') {
      initOccupiedListDatePicker();
    } else {
      initDatePicker().then(() => {
        // После инициализации flatpickr обновляем видимость коек
        updateSpecialBedsVisibility();
      });
    }
  }
});

function initBedButtons() {
  document.querySelectorAll('.toggle-btn').forEach(btn => {
    btn.addEventListener('click', handleBedToggle);
  });
}

function updateSpecialBedsVisibility() {
  const datePicker = document.getElementById('date-picker');
  if (!datePicker) return;
  
  let date;
  if (datePicker._flatpickr) {
    date = datePicker._flatpickr.selectedDates[0];
  } else {
    const dateParts = datePicker.value.split('.');
    date = new Date(dateParts[2], dateParts[1] - 1, dateParts[0]);
  }
  
  if (!date || isNaN(date.getTime())) return;
  
  const weekday = date.getDay();
  const specialBeds = document.querySelectorAll('.bed-card.special-bed');
  
  specialBeds.forEach(bed => {
    bed.classList.toggle('visible', [1, 3, 5].includes(weekday));
  });
}

// async function handleBedToggle(e) {
//   e.preventDefault();
//   const btn = e.currentTarget;
//   const originalHtml = btn.innerHTML;
  
//   try {
//     btn.innerHTML = '<span class="spinner-border spinner-border-sm"></span>';
//     btn.disabled = true;
    
//     const bedCard = btn.closest('.bed-card');
//     const date = bedCard.dataset.date;
//     const bedIndex = parseInt(bedCard.querySelector('.card-title').textContent.match(/\d+/)[0]);
//     const weekday = new Date(date).getDay(); // 0-6, где 0 - воскресенье
    
//     // Проверка доступности специальных коек
//     if (bedIndex > 18 && ![1, 3, 5].includes(weekday)) {
//       showAlert('Ошибка', 'Эти койки доступны только по понедельникам, средам и пятницам');
//       btn.innerHTML = originalHtml;
//       btn.disabled = false;
//       return;
//     }
    
//     const formData = new FormData();
//     formData.append('date', date);
//     formData.append('bed_index', bedIndex);
    
//     // Определяем, занята ли койка (проверяем наличие класса occupied-card)
//     const isOccupied = bedCard.classList.contains('occupied-card');
    
//     if (isOccupied) {
//       const confirmed = await showCustomConfirm(
//         'Подтвердите действие',
//         'Вы действительно хотите освободить койку?'
//       );
      
//       if (!confirmed) {
//         btn.innerHTML = originalHtml;
//         btn.disabled = false;
//         return;
//       }
      
//       formData.append('patient_name', '');
//       formData.append('diagnosis', '');
//     } else {
//       const patientName = bedCard.querySelector('.patient-input').value.trim();
//       const diagnosis = bedCard.querySelector('.diagnosis-input').value.trim();
      
//       if (!patientName) {
//         showAlert('Ошибка', 'Пожалуйста, введите имя пациента');
//         btn.innerHTML = originalHtml;
//         btn.disabled = false;
//         return;
//       }
      
//       formData.append('patient_name', patientName);
//       formData.append('diagnosis', diagnosis);
//     }
    
//     const response = await fetch('/occupy', {
//       method: 'POST',
//       body: formData
//     });
    
//     if (response.ok) {
//       window.location.reload();
//     } else if (response.status === 409) {
//       const errorText = await response.text();
//       const bedNumber = errorText.split(':')[1];
//       btn.innerHTML = originalHtml;
//       btn.disabled = false;
      
//       // Модифицированная версия showAlert с колбэком
//       showAlertWithCallback('Койка занята', `Койка №${bedNumber} уже занята другим пациентом. Нажмите OK для обновления данных.`, () => {
//         window.location.reload();
//       });
//     } else {
//       throw new Error('Ошибка сервера');
//     }
//   } catch (error) {
//     console.error('Error:', error);
//     showAlert('Ошибка', 'Не удалось выполнить действие');
//     btn.innerHTML = originalHtml;
//     btn.disabled = false;
//   }
// }
function initOccupiedListDatePicker() {
  const datePicker = document.getElementById('date-picker');
  if (!datePicker) return;

  flatpickr(datePicker, {
    locale: "ru",
    dateFormat: "d.m.Y",
    allowInput: true,
    defaultDate: datePicker.value,
    onChange: function(selectedDates, dateStr) {
      window.location.href = `/occupied_list?date=${dateStr}`;
    }
  });
}
function showAlertWithCallback(title, message, callback) {
  const modal = new bootstrap.Modal('#confirmModal');
  const modalEl = document.getElementById('confirmModal');
  
  // Настраиваем для alert
  modalEl.querySelector('.modal-header').className = 'modal-header bg-warning text-dark';
  modalEl.querySelector('.modal-title').textContent = title;
  modalEl.querySelector('#confirmMessage').textContent = message;
  modalEl.querySelector('#confirmBtn').textContent = 'OK';
  modalEl.querySelector('#cancelBtn').style.display = 'none';
  
  const confirmBtn = modalEl.querySelector('#confirmBtn');
  
  // Очищаем предыдущие обработчики
  confirmBtn.onclick = null;
  
  // Устанавливаем новый обработчик
  confirmBtn.onclick = () => {
    modal.hide();
    // Возвращаем исходные настройки
    modalEl.querySelector('.modal-header').className = 'modal-header bg-danger text-white';
    modalEl.querySelector('#confirmBtn').textContent = 'Освободить';
    modalEl.querySelector('#cancelBtn').style.display = 'block';
    
    // Вызываем колбэк после закрытия модального окна
    if (typeof callback === 'function') {
      callback();
    }
  };
  
  modal.show();
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
    if (!response.ok) throw new Error('Network response was not ok');
    occupiedDates = await response.json();
  } catch (error) {
    console.error('Ошибка при загрузке занятых дат:', error);
    // Можно показать пользователю уведомление об ошибке
    showAlert('Ошибка', 'Не удалось загрузить данные о занятых датах');
  }

  const flatpickrInstance = flatpickr(datePicker, {
    locale: "ru",
    dateFormat: "d.m.Y",
    allowInput: true,
    defaultDate: datePicker.value,
    onChange: function(selectedDates, dateStr, instance) {
      document.getElementById('date-form').submit();
    },
    onDayCreate: function(dObj, dStr, fp, dayElem) {
      const date = dayElem.dateObj;
      const formattedDate = `${date.getFullYear()}-${String(date.getMonth()+1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
      
      if (occupiedDates.includes(formattedDate)) {
        dayElem.style.backgroundColor = "#ffdddd";
        dayElem.style.color = "#cc0000";
        dayElem.style.fontWeight = "bold";
      }
    }
  });

  return flatpickrInstance;
}

function printTable() {
  const printWindow = window.open('', '_blank');
  printWindow.document.write(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Список занятых коек на <%= @target_date.strftime('%d.%m.%Y') %></title>
      <style>
        body { font-family: Arial; margin: 20px; }
        h4 { text-align: center; margin-bottom: 20px; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { border: 1px solid #000; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        @page { size: auto; margin: 5mm; }
      </style>
    </head>
    <body>
      ${document.getElementById('printable-table').innerHTML}
      <script>
        window.onload = function() {
          setTimeout(function() {
            window.print();
            window.close();
          }, 200);
        }
      </script>
    </body>
    </html>
  `);
  printWindow.document.close();
}