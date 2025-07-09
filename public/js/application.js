// public/js/application.js
document.addEventListener('DOMContentLoaded', function() {
  // Обработчик для кнопок койки
  document.querySelectorAll('.toggle-btn').forEach(btn => {
    btn.addEventListener('click', handleBedToggle);
  });

  // Обработчик изменения даты
  const datePicker = document.getElementById('date-picker');
  if (datePicker) {
    datePicker.addEventListener('change', function() {
      document.getElementById('date-form').submit();
    });
  }
});

async function handleBedToggle(e) {
  e.preventDefault();
  
  const bedCard = e.target.closest('.bed-card');
  const date = bedCard.dataset.date; // Получаем дату из data-атрибута
  const bedIndex = bedCard.querySelector('.card-title').textContent.match(/\d+/)[0];
  const isOccupied = bedCard.classList.contains('occupied-card');
  
  const formData = new FormData();
  formData.append('date', date);
  formData.append('bed_index', bedIndex);
  
  if (isOccupied) {
    formData.append('patient_name', '');
    formData.append('diagnosis', '');
  } else {
    const patientName = bedCard.querySelector('.patient-input').value || '';
    const diagnosis = bedCard.querySelector('.diagnosis-input').value || '';
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
  }
}