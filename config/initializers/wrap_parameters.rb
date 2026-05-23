# Отключаем оборачивание параметров в ключ имени контроллера.
# В нашем API клиент шлёт плоский JSON ({"first_name": ...}),
# а не вложенный ({"student": {"first_name": ...}}), поэтому
# обёртка только шумит в логе как Unpermitted parameter: :student.
ActiveSupport.on_load(:action_controller) do
  wrap_parameters format: []
end
